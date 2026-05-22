import SwiftUI

struct TodayTaskListCard: View {
    let tasks: [StudyTask]
    let taskMessage: String?
    let planTaskGenerationResult: PlanTaskGenerationResult?
    let onToggleStatus: (StudyTask) -> Void
    let onQuickAdd: () -> Void
    let onViewTasks: () -> Void

    var body: some View {
        TodayCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionTitle(title: "今日任务列表", systemImage: "checklist")
                    Spacer()
                    Button {
                        onQuickAdd()
                    } label: {
                        Label("快速新增", systemImage: "plus.circle")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("快速新增任务")
                    .accessibilityHint("打开快速新增任务表单")
                    .accessibilityAddTraits(.isButton)
                }

                if tasks.isEmpty {
                    Text("先添加一个能立刻开始的任务。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                } else {
                    VStack(spacing: 10) {
                        ForEach(tasks, id: \.id) { task in
                            TodayTaskRowView(task: task) {
                                onToggleStatus(task)
                            }

                            if task.id != tasks.last?.id {
                                Divider()
                            }
                        }
                    }
                }

                if let planTaskGenerationResult {
                    PlanTaskGenerationResultView(
                        result: planTaskGenerationResult,
                        onViewTasks: onViewTasks
                    )
                }

                if let taskMessage {
                    Text(taskMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct PlanTaskGenerationResultView: View {
    let result: PlanTaskGenerationResult
    let onViewTasks: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(result.message, systemImage: "checkmark.circle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.green)

            Button {
                onViewTasks()
            } label: {
                Label("查看任务页", systemImage: "checklist")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("查看任务页")
            .accessibilityHint("打开任务列表查看已生成任务")
            .accessibilityAddTraits(.isButton)
        }
        .padding(10)
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct TodayTaskRowView: View {
    let task: StudyTask
    let onToggleStatus: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                onToggleStatus()
            } label: {
                Image(systemName: task.statusIconName)
                    .font(.title3)
                    .foregroundStyle(task.statusIconColor)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .disabled(!task.canToggleInStage3A)
            .accessibilityLabel(task.todayStatus == .done ? "撤回待做" : "标记完成")
            .accessibilityValue(task.statusDisplayText)
            .accessibilityHint(task.canToggleInStage3A ? "切换任务完成状态" : "请到任务页修改该状态")
            .accessibilityAddTraits(.isButton)

            VStack(alignment: .leading, spacing: 7) {
                Text(task.title.isEmpty ? "未命名任务" : task.title)
                    .font(.subheadline.weight(.semibold))
                    .strikethrough(task.todayStatus == .done)
                    .foregroundStyle(task.todayStatus == .done ? .secondary : .primary)

                HStack(spacing: 8) {
                    SmallTag(text: task.todaySubjectText)
                    SmallTag(text: task.todayCategoryText)
                    Text(task.statusDisplayText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let estimatedMinutes = task.estimatedMinutes {
                        Text("\(estimatedMinutes) 分钟")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(task.accessibilitySummary)
    }
}

extension StudyTask {
    var todayStatus: StudyTaskStatus {
        StudyTaskStatus.from(status)
    }

    var canToggleInStage3A: Bool {
        todayStatus == .pending || todayStatus == .done
    }

    var statusDisplayText: String {
        todayStatus.displayName
    }

    var statusIconName: String {
        switch todayStatus {
        case .done:
            return "checkmark.circle.fill"
        case .inProgress:
            return "circle.lefthalf.filled"
        case .skipped:
            return "minus.circle"
        case .pending:
            return "circle"
        }
    }

    var statusIconColor: Color {
        switch todayStatus {
        case .done:
            return .green
        case .inProgress:
            return .blue
        case .skipped:
            return .secondary
        case .pending:
            return .secondary
        }
    }

    var todaySubjectText: String {
        subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "未设科目"
            : LearningSubject.from(subject).displayName
    }

    var todayCategoryText: String {
        category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "未分类"
            : StudyTaskCategory.from(category).displayName
    }

    var accessibilitySummary: String {
        let minutesText = estimatedMinutes.map { "，预计 \($0) 分钟" } ?? ""
        let titleText = title.isEmpty ? "未命名任务" : title
        return "\(titleText)，\(todaySubjectText)，\(todayCategoryText)，\(statusDisplayText)\(minutesText)"
    }
}
