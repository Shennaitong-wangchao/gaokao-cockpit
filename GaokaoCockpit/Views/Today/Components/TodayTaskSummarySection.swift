import SwiftUI

struct TodayTaskSummaryCard: View {
    let totalTaskCount: Int
    let completedTaskCount: Int
    let pendingTaskCount: Int
    let builtInPromptTemplateCount: Int

    var body: some View {
        TodayCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle(title: "今日任务摘要", systemImage: "chart.bar.doc.horizontal")

                HStack(spacing: 10) {
                    StatPill(title: "任务", value: "\(totalTaskCount)")
                    StatPill(title: "已完成", value: "\(completedTaskCount)", isPositive: totalTaskCount > 0 && totalTaskCount == completedTaskCount)
                    StatPill(title: "未完成", value: "\(pendingTaskCount)")
                }

                Text("内置 Prompt 模板：\(builtInPromptTemplateCount) 个")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
