import SwiftUI

struct LowEnergyModeCard: View {
    var body: some View {
        DSCard(
            cornerRadius: DesignSystem.CornerRadius.large,
            shadow: DesignSystem.Shadow.small,
            accentColor: DesignSystem.ThemeColors.lowEnergy,
            backgroundColor: DesignSystem.ThemeColors.lowEnergy.opacity(0.1)
        ) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // 图标
                ZStack {
                    Circle()
                        .fill(DesignSystem.ThemeColors.lowEnergy.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: "bolt.heart.fill")
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(DesignSystem.ThemeColors.lowEnergy)
                }

                // 文案
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("今天只保住链条")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.ThemeColors.lowEnergy)

                    Text("今天状态不佳？没关系，休息也是进步的一部分。先做保底任务，不追求完美。")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
