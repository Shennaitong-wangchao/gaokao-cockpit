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
                    title: "重点任务",
                    subtitle: "今天最重要的 1-3 件事",
                    placeholder: "今天最重要的 1-3 件事",
                    text: $topTasksText
                )

                LabeledTextEditor(
                    title: "保底任务",
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
                        title: "加分任务",
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
    let message: String?
    let onGenerate: () -> Void

    var body: some View {
        TodayCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(title: "计划转任务", systemImage: "arrow.triangle.branch")

                Text("按行拆分重点 / 保底 / 加分任务，自动生成今日任务。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button {
                    onGenerate()
                } label: {
                    Label("把计划加入任务页", systemImage: "text.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("把计划加入任务页")
                .accessibilityHint("把上方每一行计划变成今日任务")
                .accessibilityAddTraits(.isButton)

                if let message {
                    Label(message, systemImage: "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .accessibilityLabel(message)
                }
            }
        }
    }
}
