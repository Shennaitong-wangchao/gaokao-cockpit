import SwiftData
import SwiftUI

struct FocusSessionFinishSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let task: StudyTask
    let session: FocusSession
    let elapsedSeconds: Int
    let distractionCount: Int
    let onCancel: () -> Void
    let onSaved: () -> Void

    @State private var actualMinutes: Int
    @State private var draftDistractionCount: Int
    @State private var completionScore: Int
    @State private var sessionNote = ""
    @State private var nextAction = ""
    @State private var markTaskDone = false
    @State private var syncOutputToTask = true
    @State private var errorMessage: String?

    init(
        task: StudyTask,
        session: FocusSession,
        elapsedSeconds: Int,
        distractionCount: Int,
        onCancel: @escaping () -> Void,
        onSaved: @escaping () -> Void
    ) {
        self.task = task
        self.session = session
        self.elapsedSeconds = elapsedSeconds
        self.distractionCount = distractionCount
        self.onCancel = onCancel
        self.onSaved = onSaved

        _actualMinutes = State(initialValue: Self.defaultActualMinutes(from: elapsedSeconds))
        _draftDistractionCount = State(initialValue: distractionCount)
        _completionScore = State(initialValue: session.completionScore ?? 4)
        _sessionNote = State(initialValue: session.sessionNote)
        _nextAction = State(initialValue: session.nextAction)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("快速结束") {
                    Label("可以先保存本轮时间和分心次数，备注与下一步之后再补。", systemImage: "bolt.fill")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button {
                        save(useQuickDefaults: true)
                    } label: {
                        Label("快速保存并返回", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Section("本轮结果") {
                    Stepper(value: $actualMinutes, in: 1...600) {
                        Text("实际 \(actualMinutes) 分钟")
                    }
                    .accessibilityLabel("实际分钟")

                    Stepper(value: $draftDistractionCount, in: 0...99) {
                        Text("分心 \(draftDistractionCount) 次")
                    }
                    .accessibilityLabel("分心次数")

                    Picker("完成评分", selection: $completionScore) {
                        Text("不评分").tag(0)
                        ForEach(1...5, id: \.self) { score in
                            Text("\(score) 分").tag(score)
                        }
                    }
                }

                Section("本轮产出") {
                    TextEditor(text: $sessionNote)
                        .frame(minHeight: 110)
                        .accessibilityLabel("本轮产出")
                }

                Section("下一步") {
                    TextEditor(text: $nextAction)
                        .frame(minHeight: 80)
                        .accessibilityLabel("下一步")
                }

                Section("同步到任务") {
                    Toggle("标记任务完成", isOn: $markTaskDone)
                    Toggle("同步产出到任务备注", isOn: $syncOutputToTask)
                }

                Section {
                    Button {
                        save(useQuickDefaults: false)
                    } label: {
                        Label("保存详细记录", systemImage: "tray.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("本轮结束")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("继续专注") {
                        dismiss()
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存详细记录") {
                        save(useQuickDefaults: false)
                    }
                }
            }
        }
    }

    private func save(useQuickDefaults: Bool) {
        let cleanSessionNote = sessionNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNextAction = nextAction.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalActualMinutes = max(actualMinutes, 1)
        let finalCompletionScore = useQuickDefaults && completionScore == 0 ? 4 : completionScore

        do {
            try FocusSessionStore.finishSession(
                session,
                actualMinutes: finalActualMinutes,
                distractionCount: draftDistractionCount,
                completionScore: finalCompletionScore == 0 ? nil : finalCompletionScore,
                sessionNote: cleanSessionNote,
                nextAction: cleanNextAction,
                in: modelContext
            )

            task.actualMinutes = (task.actualMinutes ?? 0) + finalActualMinutes
            if markTaskDone {
                task.status = ModelDefaults.StudyTaskStatus.done
            } else {
                task.status = ModelDefaults.StudyTaskStatus.inProgress
            }

            if syncOutputToTask && !cleanSessionNote.isEmpty {
                task.outputNote = appendedFocusNote(to: task.outputNote, note: cleanSessionNote)
            }

            task.updatedAt = Date()
            try modelContext.save()

            dismiss()
            onSaved()
        } catch {
            errorMessage = "保存专注记录失败：\(error.localizedDescription)"
        }
    }

    private func appendedFocusNote(to currentNote: String, note: String) -> String {
        let cleanCurrentNote = currentNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let focusLine = "Focus: \(note)"

        guard !cleanCurrentNote.isEmpty else {
            return focusLine
        }

        return "\(cleanCurrentNote)\n\(focusLine)"
    }

    private static func defaultActualMinutes(from elapsedSeconds: Int) -> Int {
        max(1, Int((Double(elapsedSeconds) / 60.0).rounded(.up)))
    }
}

#Preview {
    let container = try! AppModelContainerFactory.make(inMemory: true)
    let context = container.mainContext
    let task = StudyTask(
        dayKey: DateKey.todayKey(),
        title: "英语阅读精读 1 篇",
        subject: "英语",
        category: "复盘",
        estimatedMinutes: 25
    )
    let session = FocusSession(
        taskId: task.id,
        dayKey: task.dayKey,
        subject: task.subject,
        plannedMinutes: 25
    )

    context.insert(task)
    context.insert(session)

    return FocusSessionFinishSheet(
        task: task,
        session: session,
        elapsedSeconds: 1280,
        distractionCount: 1,
        onCancel: {},
        onSaved: {}
    )
    .modelContainer(container)
}
