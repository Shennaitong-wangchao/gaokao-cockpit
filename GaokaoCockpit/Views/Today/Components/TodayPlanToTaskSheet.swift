import SwiftData
import SwiftUI

struct PlanTaskGenerationState: Identifiable {
    let id = UUID()
    let items: [PlanTaskConfirmationItem]

    var parsedTasks: [ParsedPlanTask] {
        items.map(\.parsedTask)
    }

    var creatableItems: [PlanTaskConfirmationItem] {
        items.filter { !$0.alreadyExists }
    }

    var duplicateItems: [PlanTaskConfirmationItem] {
        items.filter(\.alreadyExists)
    }
}

struct PlanTaskConfirmationItem: Identifiable {
    let id = UUID()
    let parsedTask: ParsedPlanTask
    let alreadyExists: Bool
}

struct PlanTaskGenerationResult: Equatable {
    let created: Int
    let skipped: Int

    var message: String {
        "已添加 \(created) 个任务，跳过 \(skipped) 个重复项。"
    }
}

struct PlanTaskGenerationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let generation: PlanTaskGenerationState
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("已存在的同名任务会自动跳过。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !generation.creatableItems.isEmpty {
                    Section("将创建") {
                        ForEach(generation.creatableItems) { item in
                            PlanTaskPreviewRow(item: item)
                        }
                    }
                }

                if !generation.duplicateItems.isEmpty {
                    Section("已存在，将跳过") {
                        ForEach(generation.duplicateItems) { item in
                            PlanTaskPreviewRow(item: item)
                        }
                    }
                }
            }
            .navigationTitle("生成今日任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("确认添加") {
                        onConfirm()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PlanTaskPreviewRow: View {
    let item: PlanTaskConfirmationItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.alreadyExists ? "checkmark.circle" : "plus.circle")
                .foregroundStyle(item.alreadyExists ? Color.secondary : Color.green)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 5) {
                Text(item.parsedTask.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(item.alreadyExists ? .secondary : .primary)

                HStack(spacing: 8) {
                    SmallTag(text: item.parsedTask.sourceTitle)
                    SmallTag(text: StudyTaskCategory.from(item.parsedTask.category).displayName)
                    if item.alreadyExists {
                        Text("将跳过")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct TodayQuickAddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let dayKey: String
    let dayPlanID: UUID?
    let defaultSubject: String
    let onSaved: () -> Void

    @State private var title = ""
    @State private var subject: LearningSubject
    @State private var category = StudyTaskCategory.exercise
    @State private var estimatedMinutes = 25
    @State private var errorMessage: String?

    private var isAddDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(
        dayKey: String,
        dayPlanID: UUID?,
        defaultSubject: String,
        onSaved: @escaping () -> Void
    ) {
        self.dayKey = dayKey
        self.dayPlanID = dayPlanID
        self.defaultSubject = defaultSubject
        self.onSaved = onSaved
        _subject = State(initialValue: LearningSubject.from(defaultSubject))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("具体要做什么？", text: $title)
                        .accessibilityLabel("任务标题")

                    Picker("科目", selection: $subject) {
                        ForEach(LearningSubject.allCases) { subject in
                            Text(subject.displayName).tag(subject)
                        }
                    }

                    Picker("类型", selection: $category) {
                        ForEach(StudyTaskCategory.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }

                    Stepper(value: $estimatedMinutes, in: 5...180, step: 5) {
                        Text("预计 \(estimatedMinutes) 分钟")
                    }
                    .accessibilityLabel("预计分钟")
                    .accessibilityValue("\(estimatedMinutes) 分钟")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        saveTask()
                    } label: {
                        Label("添加任务", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isAddDisabled)
                    .accessibilityLabel("添加任务")
                    .accessibilityHint("保存到今日任务列表")
                }
            }
            .navigationTitle("快速新增任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(false)
    }

    private func saveTask() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            errorMessage = "请先填写任务标题。"
            return
        }

        do {
            _ = try StudyTaskStore.createTask(
                dayKey: dayKey,
                title: cleanTitle,
                subject: subject.storageValue,
                category: category,
                estimatedMinutes: estimatedMinutes,
                dayPlanId: dayPlanID,
                in: modelContext
            )

            title = ""
            subject = LearningSubject.from(defaultSubject)
            category = .exercise
            estimatedMinutes = 25
            errorMessage = nil
            onSaved()
            dismiss()
        } catch {
            errorMessage = "保存任务失败：\(error.localizedDescription)"
        }
    }
}
