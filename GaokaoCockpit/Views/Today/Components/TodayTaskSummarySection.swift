import SwiftUI

struct TodayTaskSummaryCard: View {
    let totalTaskCount: Int
    let completedTaskCount: Int
    let pendingTaskCount: Int
    let builtInPromptTemplateCount: Int
    @Environment(ThemeManager.self) private var themeManager

    var completionRate: Double {
        guard totalTaskCount > 0 else { return 0 }
        return Double(completedTaskCount) / Double(totalTaskCount)
    }

    var body: some View {
        DSCard(
            cornerRadius: DesignSystem.CornerRadius.large,
            shadow: DesignSystem.Shadow.medium
        ) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // 标题和完成率
                HStack(alignment: .center) {
                    SectionTitle(title: "今日任务摘要", systemImage: "chart.bar.doc.horizontal")

                    Spacer()

                    // 完成率环形图
                    ZStack {
                        DSProgressBar(
                            progress: completionRate,
                            style: .ring(lineWidth: 6),
                            color: completionRate == 1.0 ? DesignSystem.SemanticColors.success : themeManager.themeColor,
                            showPercentage: false
                        )
                        .frame(width: 50, height: 50)

                        Text("\(Int(completionRate * 100))%")
                            .font(DesignSystem.Typography.caption.weight(.bold))
                            .foregroundStyle(completionRate == 1.0 ? DesignSystem.SemanticColors.success : themeManager.themeColor)
                    }
                }

                // 三个统计卡片
                HStack(spacing: DesignSystem.Spacing.md) {
                    // 总任务数
                    DSStatCard(
                        title: "总任务",
                        value: "\(totalTaskCount)",
                        icon: "list.bullet",
                        backgroundColor: themeManager.themeColor.opacity(0.1),
                        valueColor: themeManager.themeColor
                    )

                    // 已完成
                    DSStatCard(
                        title: "已完成",
                        value: "\(completedTaskCount)",
                        icon: "checkmark.circle.fill",
                        backgroundColor: DesignSystem.SemanticColors.success.opacity(0.1),
                        valueColor: DesignSystem.SemanticColors.success
                    )

                    // 待办
                    DSStatCard(
                        title: "待办",
                        value: "\(pendingTaskCount)",
                        icon: "circle",
                        backgroundColor: DesignSystem.SemanticColors.warning.opacity(0.1),
                        valueColor: DesignSystem.SemanticColors.warning
                    )
                }

                // 进度条
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        Text("完成进度")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(progressMessage)
                            .font(DesignSystem.Typography.caption.weight(.semibold))
                            .foregroundStyle(completionRate == 1.0 ? DesignSystem.SemanticColors.success : themeManager.themeColor)
                    }

                    DSProgressBar(
                        progress: completionRate,
                        style: .linear,
                        color: completionRate == 1.0 ? DesignSystem.SemanticColors.success : themeManager.themeColor,
                        showPercentage: false
                    )
                }

                // 提示词模板数量
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "text.bubble")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)

                    Text("内置 Prompt 模板：\(builtInPromptTemplateCount) 个")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var progressMessage: String {
        EncouragementSystem.getMessage(for: completionRate)
    }
}
