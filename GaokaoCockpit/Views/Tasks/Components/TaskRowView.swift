import SwiftUI

struct TaskRowView: View {
    let task: StudyTask
    let onTap: () -> Void
    let onFocusFinished: () -> Void
    let onChangeStatus: (StudyTaskStatus) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    onTap()
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: task.taskListStatusIconName)
                            .font(.title3)
                            .foregroundStyle(task.taskListStatusIconColor)
                            .frame(width: 28, height: 28)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(task.title.isEmpty ? "未命名任务" : task.title)
                                .font(.headline)
                                .foregroundStyle(task.taskListStatus == .done ? .secondary : .primary)
                                .strikethrough(task.taskListStatus == .done)
                                .lineLimit(2)

                            HStack(spacing: 8) {
                                TaskTag(text: task.taskListSubjectText)
                                TaskTag(text: task.taskListCategoryText)
                            }

                            Text(task.taskListMinutesText)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if !task.outputNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(task.outputNote)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("编辑任务 \(task.title.isEmpty ? "未命名任务" : task.title)")
                .accessibilityHint("打开任务详情编辑")
                .accessibilityAddTraits(.isButton)

                Menu {
                    ForEach(TaskStatusOption.all) { option in
                        Button {
                            onChangeStatus(option.status)
                        } label: {
                            Label(option.title, systemImage: option.systemImage)
                        }
                    }
                } label: {
                    Label(task.taskListStatusTitle, systemImage: "chevron.down.circle")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("切换任务状态")
                .accessibilityValue(task.taskListStatusTitle)
            }

            HStack(spacing: 10) {
                NavigationLink {
                    FocusSessionView(task: task, onFinished: onFocusFinished)
                } label: {
                    Label("开始专注", systemImage: "timer")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    onTap()
                } label: {
                    Label("编辑", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct TaskTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

struct TaskStatusOption: Identifiable {
    let status: StudyTaskStatus
    let systemImage: String

    var id: String { status.rawValue }

    var title: String { status.displayName }

    static let all: [TaskStatusOption] = [
        TaskStatusOption(
            status: .pending,
            systemImage: "circle"
        ),
        TaskStatusOption(
            status: .inProgress,
            systemImage: "circle.lefthalf.filled"
        ),
        TaskStatusOption(
            status: .done,
            systemImage: "checkmark.circle.fill"
        ),
        TaskStatusOption(
            status: .skipped,
            systemImage: "minus.circle"
        )
    ]

    static func title(for status: String) -> String {
        StudyTaskStatus.from(status).displayName
    }

    static func systemImage(for status: String) -> String {
        systemImage(for: StudyTaskStatus.from(status))
    }

    static func systemImage(for status: StudyTaskStatus) -> String {
        all.first { $0.status == status }?.systemImage ?? "circle"
    }
}

extension StudyTask {
    var taskListStatus: StudyTaskStatus {
        StudyTaskStatus.from(status)
    }

    var isTaskListUnfinished: Bool {
        taskListStatus == .pending || taskListStatus == .inProgress
    }

    var taskListStatusTitle: String {
        TaskStatusOption.title(for: status)
    }

    var taskListStatusIconName: String {
        TaskStatusOption.systemImage(for: status)
    }

    var taskListStatusIconColor: Color {
        switch taskListStatus {
        case .done:
            return .green
        case .inProgress:
            return .blue
        case .skipped:
            return .secondary
        case .pending:
            return .orange
        }
    }

    var taskListSubjectText: String {
        subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "未设科目"
            : LearningSubject.from(subject).displayName
    }

    var taskListCategoryText: String {
        category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "未分类"
            : StudyTaskCategory.from(category).displayName
    }

    var taskListMinutesText: String {
        let estimatedText = estimatedMinutes.map { "预计 \($0) 分钟" } ?? "预计未填写"
        let actualText = actualMinutes.map { "实际 \($0) 分钟" } ?? "实际未填写"
        return "\(estimatedText) / \(actualText)"
    }
}
