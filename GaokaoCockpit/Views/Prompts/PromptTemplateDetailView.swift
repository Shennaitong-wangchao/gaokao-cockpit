import SwiftData
import SwiftUI
import UIKit

struct PromptTemplateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let template: PromptTemplate
    let onCopied: (String) -> Void

    @State private var values: [String: String]
    @State private var generatedPrompt: String
    @State private var statusMessage: String?
    @State private var showEditor = false
    @State private var editorMode: PromptTemplateEditorView.EditorMode?

    init(
        template: PromptTemplate,
        initialValues: [String: String] = [:],
        onCopied: @escaping (String) -> Void = { _ in }
    ) {
        self.template = template
        self.onCopied = onCopied

        let cleanValues = Self.normalizedValues(initialValues)
        _values = State(initialValue: cleanValues)
        _generatedPrompt = State(initialValue: PromptRenderer.render(templateText: template.templateText, values: cleanValues))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("模板") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(template.title)
                                .font(.title3.bold())
                                .lineLimit(2)

                            Spacer(minLength: 8)

                            HStack(spacing: 6) {
                                if template.isBuiltIn {
                                    Text("内置")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(.tertiarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                } else {
                                    Text("自定义")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.blue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(.tertiarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                }

                                Text(template.category.isEmpty ? "未分类" : template.category)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Text(template.templateDescription.isEmpty ? "没有模板说明。" : template.templateDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }

                if variables.isEmpty {
                    Section("变量") {
                        ContentUnavailableView {
                            Label("这个模板没有变量", systemImage: "text.cursor")
                        } description: {
                            Text("可以直接生成并复制。")
                        }
                    }
                } else {
                    Section("变量") {
                        ForEach(variables, id: \.self) { variable in
                            PromptVariableInput(
                                variable: variable,
                                value: binding(for: variable)
                            )
                        }
                    }
                }

                Section {
                    Button {
                        generatePrompt()
                    } label: {
                        Label("生成 Prompt", systemImage: "wand.and.stars")
                    }

                    Button {
                        copyPrompt()
                    } label: {
                        Label("复制到剪贴板", systemImage: "doc.on.doc")
                    }

                    Button(role: .destructive) {
                        clearValues()
                    } label: {
                        Label("清空变量", systemImage: "xmark.circle")
                    }
                    .disabled(values.values.allSatisfy { clean($0).isEmpty })
                }

                if template.isBuiltIn {
                    Section {
                        Button {
                            duplicateTemplate()
                        } label: {
                            Label("复制为自定义模板", systemImage: "doc.on.doc.fill")
                        }
                    }
                } else {
                    Section {
                        Button {
                            editTemplate()
                        } label: {
                            Label("编辑模板", systemImage: "pencil")
                        }
                    }
                }

                PromptPreviewSection(generatedPrompt: generatedPrompt)

                if let statusMessage {
                    Section {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(statusMessage.hasPrefix("已复制") ? Color.secondary : Color.red)
                    }
                }
            }
            .navigationTitle(template.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $editorMode) { mode in
                PromptTemplateEditorView(mode: mode) {
                    onCopied("模板已保存")
                }
            }
        }
    }

    private var variables: [String] {
        Self.parseVariables(template.variablesText)
    }

    private func binding(for variable: String) -> Binding<String> {
        Binding(
            get: { values[variable, default: ""] },
            set: { values[variable] = $0 }
        )
    }

    private func generatePrompt() {
        generatedPrompt = PromptRenderer.render(templateText: template.templateText, values: values)
        statusMessage = nil
    }

    private func copyPrompt() {
        let prompt = PromptRenderer.render(templateText: template.templateText, values: values)
        generatedPrompt = prompt
        UIPasteboard.general.string = prompt

        do {
            try PromptTemplateStore.incrementUsageCount(template, in: modelContext)
            RecentPromptStore.recordUse(template: template)
            let message = "已复制，可以粘贴到 AI 工具了。"
            statusMessage = message
            onCopied(message)
        } catch {
            statusMessage = "已复制，但更新使用次数失败：\(error.localizedDescription)"
        }
    }

    private func clearValues() {
        values = variables.reduce(into: [String: String]()) { result, variable in
            result[variable] = ""
        }
        generatedPrompt = PromptRenderer.render(templateText: template.templateText, values: values)
        statusMessage = nil
    }

    private func clean(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func duplicateTemplate() {
        do {
            let duplicated = try PromptTemplateStore.duplicateBuiltInTemplate(template, in: modelContext)
            editorMode = .edit(duplicated)
        } catch {
            statusMessage = "复制失败：\(error.localizedDescription)"
        }
    }

    private func editTemplate() {
        editorMode = .edit(template)
    }

    private static func parseVariables(_ variablesText: String) -> [String] {
        var seenVariables = Set<String>()
        var parsedVariables: [String] = []

        for rawValue in variablesText.split(whereSeparator: { $0 == "," || $0.isNewline }) {
            let variable = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !variable.isEmpty, !seenVariables.contains(variable) else {
                continue
            }

            seenVariables.insert(variable)
            parsedVariables.append(variable)
        }

        return parsedVariables
    }

    private static func normalizedValues(_ values: [String: String]) -> [String: String] {
        values.reduce(into: [String: String]()) { result, pair in
            let key = pair.key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else {
                return
            }

            result[key] = pair.value
        }
    }
}

extension PromptTemplateEditorView.EditorMode: Identifiable {
    var id: String {
        switch self {
        case .create:
            return "create"
        case .edit(let template):
            return "edit-\(template.id.uuidString)"
        case .duplicate(let template):
            return "duplicate-\(template.id.uuidString)"
        }
    }
}

#Preview {
    let container = try! AppModelContainerFactory.make(inMemory: true)
    let context = container.mainContext
    try! PromptTemplateSeeder.seedIfNeeded(in: context)
    let template = try! PromptTemplateStore.fetchTemplate(title: "错题手术", in: context)!

    return PromptTemplateDetailView(template: template)
        .modelContainer(container)
}
