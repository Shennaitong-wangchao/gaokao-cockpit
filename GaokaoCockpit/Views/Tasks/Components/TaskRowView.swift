import SwiftUI

struct TaskRowView: View {
    let task: StudyTask
    let onTap: () -> Void
    let onFocusFinished: () -> Void
    let onChangeStatus: (StudyTaskStatus) -> Void
    @Environment(ThemeManager.self) private var themeManager
    @Environment(AnimationTrigger.self) private var animationTrigger

    var body: some View {
        DSCard(
            cornerRadius: DesignSystem.CornerRadius.medium,
            shadow: DesignSystem.Shadow.small,
            accentColor: task.taskListStatusIconColor,
            backgroundColor: DesignSystem.NeutralColors.secondaryBackground
        ) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                    Button {
                        onTap()
                    } label: {
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                            // 状态图标
                            ZStack {
                                Circle()
                                    .fill(task.taskListStatusIconColor.opacity(0.15))
                                    .frame(width: 36, height: 36)

                                Image(systemName: task.taskListStatusIconName)
                                    .font(DesignSystem.Typography.title3)
                                    .foregroundStyle(task.taskListStatusIconColor)
                            }
                            .accessibilityHidden(true)

                            // 任务信息
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                Text(task.title.isEmpty ? "未命名任务" : task.title)
                                    .font(DesignSystem.Typography.headline)
                                    .foregroundStyle(task.taskListStatus == .done ? .secondary : .primary)
                                    .strikethrough(task.taskListStatus == .done)
                                    .lineLimit(2)

                                HStack(spacing: DesignSystem.Spacing.xs) {
                                    DSTag(
                                        text: task.taskListSubjectText,
                                        style: .info,
                                        size: .small
                                    )
                                    DSTag(
                                        text: task.taskListCategoryText,
                                        style: .neutral,
                                        size: .small
                                    )
                                }

                                HStack(spacing: DesignSystem.Spacing.xs) {
                                    Image(systemName: "clock")
                                        .font(DesignSystem.Typography.caption)
                                    Text(task.taskListMinutesText)
                                        .font(DesignSystem.Typography.caption)
                                }
                                .foregroundStyle(.secondary)

                                if !task.outputNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text(task.outputNote)
                                        .font(DesignSystem.Typography.caption)
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

                    // 状态切换菜单
                    Menu {
                        ForEach(TaskStatusOption.all) { option in
                            Button {
                                withAnimation(DesignSystem.Animation.spring) {
                                    onChangeStatus(option.status)
                                }
                                // 触发完成动画
                                if option.status == .done {
                                    HapticFeedback.success()
                                    animationTrigger.triggerCheckmark()
                                }
                            } label: {
                                Label(option.title, systemImage: option.systemImage)
                            }
                        }
                    } label: {
                        Label(task.taskListStatusTitle, systemImage: "chevron.down.circle")
                            .labelStyle(.iconOnly)
                            .font(DesignSystem.Typography.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("切换任务状态")
                    .accessibilityValue(task.taskListStatusTitle)
                }

                // 操作按钮
                HStack(spacing: DesignSystem.Spacing.md) {
                    NavigationLink {
                        FocusSessionView(task: task, onFinished: onFocusFinished)
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "timer")
                            Text("开始专注")
                        }
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(themeManager.themeColor)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous))
                    }

                    Button {
                        onTap()
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "pencil")
                            Text("编辑")
                        }
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(themeManager.themeColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(themeManager.themeColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous))
                    }
                }
            }
        }
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
