import SwiftUI

struct TodayPlanTextCard: View {
    @Binding var topTasksText: String
    @Binding var baselineTasksText: String
    @Binding var bonusTasksText: String
    let isLowEnergyMode: Bool

    var body: some View {
        TodayCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(title: "今日三层任务", systemImage: "square.stack.3d.up")

                LabeledTextEditor(
                    title: "Top Tasks",
                    subtitle: "今天最重要的 1-3 件事",
                    placeholder: "今天最重要的 1-3 件事",
                    text: $topTasksText
                )

                LabeledTextEditor(
                    title: "Baseline Tasks",
                    subtitle: "状态差也要完成",
                    placeholder: "最少要完成的事",
                    text: $baselineTasksText
                )

                if isLowEnergyMode {
                    Label("加分任务已收起，今天先保住链条。", systemImage: "tray")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    LabeledTextEditor(
                        title: "Bonus Tasks",
                        subtitle: "状态好时追加",
                        placeholder: "有余力就多做一点",
                        text: $bonusTasksText
                    )
                }
            }
        }
    }
}

struct PlanToTaskActionCard: View {
    let onGenerate: () -> Void

    var body: some View {
        TodayCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(title: "计划转任务", systemImage: "arrow.triangle.branch")

                Text("按行拆分 Top / 保底 / 加分任务，自动生成今日任务。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button {
                    onGenerate()
                } label: {
                    Label("把计划加入任务页", systemImage: "text.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
