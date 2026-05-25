import SwiftUI

/// 成就卡片 - 显示学习连续天数、累计学习时长、本周完成任务数
struct TodayAchievementCard: View {
    let streakDays: Int
    let totalMinutes: Int
    let weeklyCompletedTasks: Int
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        DSCard(
            cornerRadius: DesignSystem.CornerRadius.large,
            shadow: DesignSystem.Shadow.medium,
            accentColor: achievementColor
        ) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // 标题
                HStack {
                    SectionTitle(title: "学习成就", systemImage: "star.fill")
                    Spacer()
                    Image(systemName: topAchievementIcon)
                        .font(DesignSystem.Typography.title2)
                        .foregroundStyle(achievementColor)
                }

                // 三个成就指标
                HStack(spacing: DesignSystem.Spacing.md) {
                    // 学习连续天数
                    AchievementItem(
                        icon: EncouragementSystem.getStreakIcon(for: streakDays),
                        value: "\(streakDays)",
                        label: "连续天数",
                        color: streakColor,
                        message: EncouragementSystem.getStreakMessage(for: streakDays)
                    )

                    Divider()

                    // 累计学习时长
                    AchievementItem(
                        icon: "clock.fill",
                        value: formatHours(totalMinutes),
                        label: "累计时长",
                        color: .blue,
                        message: EncouragementSystem.getTotalTimeMessage(for: totalMinutes)
                    )

                    Divider()

                    // 本周完成任务数
                    AchievementItem(
                        icon: "checkmark.circle.fill",
                        value: "\(weeklyCompletedTasks)",
                        label: "本周完成",
                        color: .green,
                        message: EncouragementSystem.getWeeklyTaskMessage(for: weeklyCompletedTasks)
                    )
                }

                // 鼓励文案
                if let topMessage = topAchievementMessage {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "sparkles")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(achievementColor)

                        Text(topMessage)
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(achievementColor)
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(achievementColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous))
                }
            }
        }
    }

    // MARK: - 计算属性

    private var streakColor: Color {
        switch streakDays {
        case 0: return .gray
        case 1...6: return .orange
        case 7...13: return .red
        case 14...29: return .yellow
        case 30...59: return .green
        case 60...89: return .blue
        default: return .purple
        }
    }

    private var achievementColor: Color {
        // 优先级：连续天数 > 本周任务数 > 累计时长
        if streakDays >= 30 {
            return .green
        } else if weeklyCompletedTasks >= 20 {
            return .blue
        } else if totalMinutes >= 6000 { // 100 小时
            return .purple
        } else if streakDays >= 7 {
            return .orange
        } else {
            return themeManager.themeColor
        }
    }

    private var topAchievementIcon: String {
        if streakDays >= 90 {
            return "crown.fill"
        } else if streakDays >= 60 {
            return "medal.fill"
        } else if streakDays >= 30 {
            return "trophy.fill"
        } else if streakDays >= 7 {
            return "flame.fill"
        } else if weeklyCompletedTasks >= 20 {
            return "star.fill"
        } else {
            return "star"
        }
    }

    private var topAchievementMessage: String? {
        if streakDays >= 90 {
            return "三个月连续学习！你是传奇"
        } else if streakDays >= 60 {
            return "两个月连续学习！太不可思议了"
        } else if streakDays >= 30 {
            return "一个月连续学习！你是冠军"
        } else if streakDays >= 7 {
            return "连续学习一周！习惯正在养成"
        } else if weeklyCompletedTasks >= 20 {
            return "本周完成 \(weeklyCompletedTasks) 个任务！效率惊人"
        } else {
            return nil
        }
    }

    private func formatHours(_ minutes: Int) -> String {
        let hours = minutes / 60
        if hours >= 1000 {
            return "\(hours)"
        } else if hours >= 100 {
            return "\(hours)"
        } else if hours >= 10 {
            return "\(hours)"
        } else if hours > 0 {
            return "\(hours).\(minutes % 60 / 6)"
        } else {
            return "0"
        }
    }
}

/// 成就项组件
struct AchievementItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let message: String

    @State private var showTooltip = false

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // 图标
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(color)
            }

            // 数值
            Text(value)
                .font(DesignSystem.Typography.numberMedium)
                .foregroundStyle(color)

            // 标签
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .onTapGesture {
            showTooltip.toggle()
        }
        .popover(isPresented: $showTooltip) {
            Text(message)
                .font(DesignSystem.Typography.subheadline)
                .padding()
                .presentationCompactAdaptation(.popover)
        }
    }
}

/// 紧凑版成就卡片 - 用于小空间展示
struct CompactAchievementView: View {
    let streakDays: Int
    let totalMinutes: Int
    let weeklyCompletedTasks: Int

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // 连续天数
            CompactAchievementItem(
                icon: EncouragementSystem.getStreakIcon(for: streakDays),
                value: "\(streakDays)",
                color: streakColor
            )

            Divider()
                .frame(height: 30)

            // 累计时长
            CompactAchievementItem(
                icon: "clock.fill",
                value: "\(totalMinutes / 60)h",
                color: .blue
            )

            Divider()
                .frame(height: 30)

            // 本周完成
            CompactAchievementItem(
                icon: "checkmark.circle.fill",
                value: "\(weeklyCompletedTasks)",
                color: .green
            )
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.NeutralColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous))
    }

    private var streakColor: Color {
        switch streakDays {
        case 0: return .gray
        case 1...6: return .orange
        case 7...13: return .red
        case 14...29: return .yellow
        case 30...59: return .green
        case 60...89: return .blue
        default: return .purple
        }
    }
}

/// 紧凑版成就项
struct CompactAchievementItem: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(color)

            Text(value)
                .font(DesignSystem.Typography.subheadline.weight(.semibold))
                .foregroundStyle(color)
        }
    }
}

#Preview("成就卡片") {
    VStack(spacing: 20) {
        TodayAchievementCard(
            streakDays: 30,
            totalMinutes: 6000,
            weeklyCompletedTasks: 15
        )

        TodayAchievementCard(
            streakDays: 7,
            totalMinutes: 1200,
            weeklyCompletedTasks: 8
        )

        CompactAchievementView(
            streakDays: 15,
            totalMinutes: 3000,
            weeklyCompletedTasks: 12
        )
    }
    .padding()
    .environment(ThemeManager.shared)
}
