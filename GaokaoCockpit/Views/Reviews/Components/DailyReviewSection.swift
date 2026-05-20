import Foundation
import SwiftUI

struct DailyReviewSummary {
    let taskCount: Int
    let completedTaskCount: Int
    let focusMinutes: Int
    let focusSessionCount: Int
    let mistakeCount: Int

    static let empty = DailyReviewSummary(
        taskCount: 0,
        completedTaskCount: 0,
        focusMinutes: 0,
        focusSessionCount: 0,
        mistakeCount: 0
    )
}

struct DailyReviewSection: View {
    let date: Date
    let summary: DailyReviewSummary
    let todayMistakes: [MistakeRecord]
    @Binding var completedSummary: String
    @Binding var unfinishedSummary: String
    @Binding var biggestProblem: String
    @Binding var bestMistakeId: UUID?
    @Binding var stateScoreEnd: Int
    @Binding var tomorrowFirstAction: String
    let onApplyQuickTemplate: () -> Void
    let onSave: () -> Void
    let onGeneratePrompt: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ReviewCard {
                VStack(alignment: .leading, spacing: 14) {
                    ReviewSectionTitle(title: "今日摘要", systemImage: "calendar")

                    ReviewStatsGrid(
                        stats: [
                            ReviewStat(title: "今日任务", value: "\(summary.taskCount)"),
                            ReviewStat(title: "已完成", value: "\(summary.completedTaskCount)", tint: .green),
                            ReviewStat(title: "专注分钟", value: "\(summary.focusMinutes)", tint: .blue),
                            ReviewStat(title: "专注次数", value: "\(summary.focusSessionCount)"),
                            ReviewStat(title: "今日错题", value: "\(summary.mistakeCount)", tint: .orange)
                        ]
                    )
                }
            }

            ReviewCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        ReviewSectionTitle(title: "每日复盘", systemImage: "square.and.pencil")
                        Spacer()
                        Button {
                            onApplyQuickTemplate()
                        } label: {
                            Label("快速复盘模板", systemImage: "text.badge.checkmark")
                        }
                        .buttonStyle(.bordered)
                    }

                    ReviewTextEditor(
                        title: "今日完成",
                        placeholder: "今天真正完成了什么",
                        text: $completedSummary
                    )

                    ReviewTextEditor(
                        title: "未完成与原因",
                        placeholder: "没完成什么，原因是什么",
                        text: $unfinishedSummary
                    )

                    ReviewTextEditor(
                        title: "最大问题",
                        placeholder: "今天最值得处理的问题",
                        text: $biggestProblem
                    )

                    BestMistakePicker(
                        mistakes: todayMistakes,
                        selectedMistakeId: $bestMistakeId
                    )

                    Stepper(value: $stateScoreEnd, in: 1...10) {
                        HStack {
                            Text("晚间状态评分")
                            Spacer()
                            Text("\(stateScoreEnd)/10")
                                .font(.headline.monospacedDigit())
                        }
                    }
                    .accessibilityLabel("晚间状态评分")
                    .accessibilityValue("\(stateScoreEnd) 分")

                    ReviewTextEditor(
                        title: "明日第一步",
                        placeholder: "明天打开 App 后第一件事",
                        text: $tomorrowFirstAction,
                        minHeight: 70
                    )
                }
            }

            ReviewActionButtons(
                saveTitle: "保存每日复盘",
                promptTitle: "生成每日复盘 Prompt",
                onSave: onSave,
                onGeneratePrompt: onGeneratePrompt
            )
        }
    }
}

struct BestMistakePicker: View {
    let mistakes: [MistakeRecord]
    @Binding var selectedMistakeId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("最佳错题")
                .font(.subheadline.weight(.semibold))

            if mistakes.isEmpty {
                Text("今天还没有错题可选，空着也可以。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Picker("最佳错题", selection: $selectedMistakeId) {
                    Text("暂不选择").tag(UUID?.none)
                    ForEach(mistakes, id: \.id) { mistake in
                        Text(mistake.displayTitle).tag(Optional(mistake.id))
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("最佳错题")
            }
        }
    }
}
