import Foundation
import SwiftUI

struct WeeklyReviewSummary {
    let focusMinutes: Int
    let completedTaskCount: Int
    let mistakeCount: Int
    let subjectBreakdownText: String
    let mistakeTypeBreakdownText: String

    static let empty = WeeklyReviewSummary(
        focusMinutes: 0,
        completedTaskCount: 0,
        mistakeCount: 0,
        subjectBreakdownText: "暂无科目记录",
        mistakeTypeBreakdownText: "暂无错题类型记录"
    )
}

struct WeeklyReviewSection: View {
    let weekStart: Date
    let weekEnd: Date
    let summary: WeeklyReviewSummary
    @Binding var keyProblemsText: String
    @Binding var nextWeekFocusText: String
    let onSave: () -> Void
    let onGeneratePrompt: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ReviewCard {
                VStack(alignment: .leading, spacing: 14) {
                    ReviewSectionTitle(title: "本周摘要", systemImage: "chart.bar.xaxis")

                    Text("\(Self.formatter.string(from: weekStart)) - \(Self.formatter.string(from: weekEnd))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ReviewStatsGrid(
                        stats: [
                            ReviewStat(title: "专注分钟", value: "\(summary.focusMinutes)", tint: .blue),
                            ReviewStat(title: "完成任务", value: "\(summary.completedTaskCount)", tint: .green),
                            ReviewStat(title: "错题数量", value: "\(summary.mistakeCount)", tint: .orange)
                        ]
                    )

                    ReviewBreakdownBlock(
                        title: "科目分布",
                        text: summary.subjectBreakdownText
                    )

                    ReviewBreakdownBlock(
                        title: "错题类型分布",
                        text: summary.mistakeTypeBreakdownText
                    )
                }
            }

            ReviewCard {
                VStack(alignment: .leading, spacing: 16) {
                    ReviewSectionTitle(title: "周复盘", systemImage: "list.bullet.clipboard")

                    ReviewTextEditor(
                        title: "本周关键问题",
                        placeholder: "本周真正反复出现的问题",
                        text: $keyProblemsText
                    )

                    ReviewTextEditor(
                        title: "下周重点",
                        placeholder: "下周最多抓住的重点",
                        text: $nextWeekFocusText
                    )
                }
            }

            ReviewActionButtons(
                saveTitle: "保存周复盘",
                promptTitle: "生成周复盘 Prompt",
                onSave: onSave,
                onGeneratePrompt: onGeneratePrompt
            )
        }
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = AppDateTime.timeZone
        formatter.dateFormat = "M月d日"
        return formatter
    }()
}
