import SwiftData
import SwiftUI

enum TaskEditorMode: Identifiable {
    case add
    case edit(StudyTask)

    var id: String {
        switch self {
        case .add:
            return "add-task"
        case .edit(let task):
            return task.id.uuidString
        }
    }

    var title: String {
        switch self {
        case .add:
            return "新增任务"
        case .edit:
            return "编辑任务"
        }
    }
}

struct TaskEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let mode: TaskEditorMode
    let dayKey: String
    let dayPlanID: UUID?
    let onChanged: (String) -> Void

    @State private var title: String
    @State private var subject: LearningSubject
    @State private var category: StudyTaskCategory
    @State private var estimatedMinutesText: String
    @State private var actualMinutesText: String
    @State private var status: StudyTaskStatus
    @State private var outputNote: String
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false

    init(
        mode: TaskEditorMode,
        dayKey: String,
        dayPlanID: UUID?,
        onChanged: @escaping (String) -> Void
    ) {
        self.mode = mode
        self.dayKey = dayKey
        self.dayPlanID = dayPlanID
        self.onChanged = onChanged

        switch mode {
        case .add:
            _title = State(initialValue: "")
            _subject = State(initialValue: .math)
            _category = State(initialValue: .exercise)
            _estimatedMinutesText = State(initialValue: "25")
            _actualMinutesText = State(initialValue: "")
            _status = State(initialValue: .pending)
            _outputNote = State(initialValue: "")
        case .edit(let task):
            _title = State(initialValue: task.title)
            _subject = State(initialValue: LearningSubject.from(task.subject))
            _category = State(initialValue: StudyTaskCategory.from(task.category))
            _estimatedMinutesText = State(initialValue: task.estimatedMinutes.map(String.init) ?? "")
            _actualMinutesText = State(initialValue: task.actualMinutes.map(String.init) ?? "")
            _status = State(initialValue: StudyTaskStatus.from(task.status))
            _outputNote = State(initialValue: task.outputNote)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基础信息") {
                    TextField("任务标题", text: $title)
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
                }

                Section("时间与状态") {
                    TextField("预计分钟", text: $estimatedMinutesText)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("预计分钟")

                    TextField("实际分钟", text: $actualMinutesText)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("实际分钟")

                    Picker("状态", selection: $status) {
                        ForEach(StudyTaskStatus.allCases) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                }

                Section("产出备注") {
                    TextEditor(text: $outputNote)
                        .frame(minHeight: 90)
                        .accessibilityLabel("产出备注")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                if case .edit = mode {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("删除任务", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTask()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .confirmationDialog(
                "确认删除这个任务？",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("删除任务", role: .destructive) {
                    deleteTask()
                }

                Button("取消", role: .cancel) {}
            } message: {
                Text("删除后，这个任务和任务页里的记录将无法恢复。")
            }
        }
    }

    private func saveTask() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            errorMessage = "请先填写任务标题。"
            return
        }

        guard let minutes = validatedMinutes() else {
            return
        }

        do {
            switch mode {
            case .add:
                _ = try StudyTaskStore.createTask(
                    dayKey: dayKey,
                    title: cleanTitle,
                    subject: subject.storageValue,
                    category: category,
                    estimatedMinutes: minutes.estimated,
                    actualMinutes: minutes.actual,
                    status: status,
                    outputNote: outputNote.trimmingCharacters(in: .whitespacesAndNewlines),
                    dayPlanId: dayPlanID,
                    in: modelContext
                )
                onChanged("已新增任务。")

            case .edit(let task):
                task.title = cleanTitle
                task.subject = subject.storageValue
                task.category = category.storageValue
                task.estimatedMinutes = minutes.estimated
                task.actualMinutes = minutes.actual
                task.status = status.storageValue
                task.outputNote = outputNote.trimmingCharacters(in: .whitespacesAndNewlines)
                if task.dayPlanId == nil {
                    task.dayPlanId = dayPlanID
                }
                StudyTaskStore.updateTaskTimestamp(task)
                try modelContext.save()
                onChanged("已保存任务。")
            }

            dismiss()
        } catch {
            errorMessage = "保存失败，请重试。"
        }
    }

    private func deleteTask() {
        guard case .edit(let task) = mode else {
            return
        }

        do {
            try StudyTaskStore.deleteTask(task, in: modelContext)
            onChanged("已删除任务。")
            dismiss()
        } catch {
            errorMessage = "删除失败，请重试。"
        }
    }

    private func validatedMinutes() -> (estimated: Int?, actual: Int?)? {
        guard let estimated = parseMinutes(estimatedMinutesText, fieldName: "预计分钟") else {
            return nil
        }

        guard let actual = parseMinutes(actualMinutesText, fieldName: "实际分钟") else {
            return nil
        }

        return (estimated, actual)
    }

    private func parseMinutes(_ rawValue: String, fieldName: String) -> Int?? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .some(nil)
        }

        guard let value = Int(trimmed), value >= 0 else {
            errorMessage = "\(fieldName)请输入 0 或正整数。"
            return nil
        }

        return .some(value)
    }

}
