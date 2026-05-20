import SwiftData
import SwiftUI

struct PromptTemplateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let mode: EditorMode
    let onSaved: () -> Void

    @State private var title: String
    @State private var category: PromptCategory
    @State private var templateDescription: String
    @State private var variablesText: String
    @State private var templateText: String
    @State private var errorMessage: String?
    @State private var showDeleteConfirmation = false

    init(mode: EditorMode, onSaved: @escaping () -> Void = {}) {
        self.mode = mode
        self.onSaved = onSaved

        switch mode {
        case .create:
            _title = State(initialValue: "")
            _category = State(initialValue: .other)
            _templateDescription = State(initialValue: "")
            _variablesText = State(initialValue: "")
            _templateText = State(initialValue: "")
        case .edit(let template):
            _title = State(initialValue: template.title)
            _category = State(initialValue: PromptCategory.from(template.category))
            _templateDescription = State(initialValue: template.templateDescription)
            _variablesText = State(initialValue: template.variablesText)
            _templateText = State(initialValue: template.templateText)
        case .duplicate(let template):
            _title = State(initialValue: "\(template.title) 副本")
            _category = State(initialValue: PromptCategory.from(template.category))
            _templateDescription = State(initialValue: template.templateDescription)
            _variablesText = State(initialValue: template.variablesText)
            _templateText = State(initialValue: template.templateText)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("标题", text: $title)
                        .textInputAutocapitalization(.never)

                    Picker("分类", selection: $category) {
                        ForEach(PromptCategory.allCases.filter { $0 != .all }) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("模板说明")
                            .font(.subheadline.weight(.semibold))
                        TextEditor(text: $templateDescription)
                            .frame(minHeight: 60)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("变量列表")
                            .font(.subheadline.weight(.semibold))
                        Text("用逗号或换行分隔，例如：subject, chapter, question")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $variablesText)
                            .frame(minHeight: 80)
                    }
                    .padding(.vertical, 4)

                    if !detectedVariables.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("模板中检测到的变量")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(detectedVariables.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Button {
                            fillDetectedVariables()
                        } label: {
                            Label("从模板正文提取变量", systemImage: "arrow.down.circle")
                                .font(.subheadline)
                        }
                    }
                } header: {
                    Text("变量")
                } footer: {
                    Text("变量格式使用 {{variableName}}，并在变量列表中用逗号或换行列出。")
                }

                Section("模板正文") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("模板内容")
                            .font(.subheadline.weight(.semibold))
                        Text("使用 {{variableName}} 标记变量位置")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $templateText)
                            .frame(minHeight: 200)
                    }
                    .padding(.vertical, 4)
                }

                if case .edit = mode {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("删除模板", systemImage: "trash")
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTemplate()
                    }
                }
            }
            .confirmationDialog("确认删除", isPresented: $showDeleteConfirmation) {
                Button("删除", role: .destructive) {
                    deleteTemplate()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("确定要删除这个自定义模板吗？此操作无法撤销。")
            }
        }
    }

    private var navigationTitle: String {
        switch mode {
        case .create:
            return "新建模板"
        case .edit:
            return "编辑模板"
        case .duplicate:
            return "复制模板"
        }
    }

    private var detectedVariables: [String] {
        PromptTemplateStore.extractVariablesFromTemplate(templateText)
    }

    private func fillDetectedVariables() {
        let detected = detectedVariables
        if !detected.isEmpty {
            variablesText = detected.joined(separator: "\n")
        }
    }

    private func saveTemplate() {
        errorMessage = nil

        do {
            switch mode {
            case .create, .duplicate:
                _ = try PromptTemplateStore.createCustomTemplate(
                    title: title,
                    category: category.storageValue,
                    templateDescription: templateDescription,
                    templateText: templateText,
                    variablesText: variablesText,
                    in: modelContext
                )
            case .edit(let template):
                try PromptTemplateStore.updateCustomTemplate(
                    template,
                    title: title,
                    category: category.storageValue,
                    templateDescription: templateDescription,
                    templateText: templateText,
                    variablesText: variablesText,
                    in: modelContext
                )
            }

            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteTemplate() {
        guard case .edit(let template) = mode else {
            return
        }

        do {
            try PromptTemplateStore.deleteCustomTemplate(template, in: modelContext)
            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    enum EditorMode {
        case create
        case edit(PromptTemplate)
        case duplicate(PromptTemplate)
    }
}

#Preview("Create") {
    let container = try! AppModelContainerFactory.make(inMemory: true)
    return PromptTemplateEditorView(mode: .create)
        .modelContainer(container)
}

#Preview("Edit") {
    let container = try! AppModelContainerFactory.make(inMemory: true)
    let context = container.mainContext
    try! PromptTemplateSeeder.seedIfNeeded(in: context)

    let custom = PromptTemplate(
        title: "测试自定义模板",
        category: "错题",
        templateDescription: "这是一个测试模板",
        templateText: "科目：{{subject}}\n题目：{{question}}",
        variablesText: "subject, question",
        isBuiltIn: false
    )
    context.insert(custom)

    return PromptTemplateEditorView(mode: .edit(custom))
        .modelContainer(container)
}
