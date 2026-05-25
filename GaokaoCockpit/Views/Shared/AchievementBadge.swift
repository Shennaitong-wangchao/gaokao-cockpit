import SwiftUI

/// 视觉奖励系统 - 显示勋章、火焰、奖杯等成就图标
struct AchievementBadge: View {
    let type: BadgeType
    var size: CGFloat = 60
    var showLabel: Bool = true
    var isAnimated: Bool = true

    enum BadgeType {
        case dailyGoal          // 完成每日目标
        case weekStreak         // 连续学习 7 天
        case twoWeekStreak      // 连续学习 14 天
        case monthStreak        // 连续学习 30 天
        case twoMonthStreak     // 连续学习 60 天
        case threeMonthStreak   // 连续学习 90 天
        case hundredHours       // 累计学习 100 小时
        case fiveHundredHours   // 累计学习 500 小时
        case thousandHours      // 累计学习 1000 小时
        case weeklyChampion     // 本周完成 20+ 任务

        var icon: String {
            switch self {
            case .dailyGoal: return "checkmark.seal.fill"
            case .weekStreak: return "flame.fill"
            case .twoWeekStreak: return "star.fill"
            case .monthStreak: return "trophy.fill"
            case .twoMonthStreak: return "medal.fill"
            case .threeMonthStreak: return "crown.fill"
            case .hundredHours: return "clock.badge.checkmark.fill"
            case .fiveHundredHours: return "clock.badge.checkmark.fill"
            case .thousandHours: return "clock.badge.checkmark.fill"
            case .weeklyChampion: return "star.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .dailyGoal: return .green
            case .weekStreak: return .orange
            case .twoWeekStreak: return .yellow
            case .monthStreak: return .green
            case .twoMonthStreak: return .blue
            case .threeMonthStreak: return .purple
            case .hundredHours: return .blue
            case .fiveHundredHours: return .purple
            case .thousandHours: return .yellow
            case .weeklyChampion: return .orange
            }
        }

        var label: String {
            switch self {
            case .dailyGoal: return "今日目标达成"
            case .weekStreak: return "连续学习 7 天"
            case .twoWeekStreak: return "连续学习 14 天"
            case .monthStreak: return "连续学习 30 天"
            case .twoMonthStreak: return "连续学习 60 天"
            case .threeMonthStreak: return "连续学习 90 天"
            case .hundredHours: return "累计学习 100 小时"
            case .fiveHundredHours: return "累计学习 500 小时"
            case .thousandHours: return "累计学习 1000 小时"
            case .weeklyChampion: return "本周冠军"
            }
        }

        var description: String {
            switch self {
            case .dailyGoal: return "完美！今日所有任务都已完成"
            case .weekStreak: return "太棒了！连续学习一周，习惯正在养成"
            case .twoWeekStreak: return "两周连续学习！你很自律"
            case .monthStreak: return "一个月连续学习！你是冠军"
            case .twoMonthStreak: return "两个月连续学习！太不可思议了"
            case .threeMonthStreak: return "三个月连续学习！你是传奇"
            case .hundredHours: return "累计学习时长超过 100 小时！"
            case .fiveHundredHours: return "累计学习时长超过 500 小时！你很专注"
            case .thousandHours: return "累计学习时长超过 1000 小时！你是学习达人"
            case .weeklyChampion: return "本周完成 20+ 任务！效率惊人"
            }
        }
    }

    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // 徽章图标
            ZStack {
                // 背景光晕
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                type.color.opacity(0.3),
                                type.color.opacity(0.1),
                                type.color.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.8
                        )
                    )
                    .frame(width: size * 1.6, height: size * 1.6)
                    .opacity(opacity)

                // 徽章背景
                Circle()
                    .fill(type.color.opacity(0.2))
                    .frame(width: size, height: size)

                // 徽章图标
                Image(systemName: type.icon)
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(type.color)
                    .rotationEffect(.degrees(rotation))
            }
            .scaleEffect(scale)
            .opacity(opacity)

            // 标签
            if showLabel {
                Text(type.label)
                    .font(DesignSystem.Typography.caption.weight(.semibold))
                    .foregroundStyle(type.color)
                    .opacity(opacity)
            }
        }
        .onAppear {
            if isAnimated {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }

                withAnimation(.easeInOut(duration: 0.8)) {
                    rotation = 360
                }
            } else {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

/// 成就解锁弹窗
struct AchievementUnlockedView: View {
    let badge: AchievementBadge.BadgeType
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // 成就卡片
            VStack(spacing: DesignSystem.Spacing.xl) {
                // 标题
                Text("成就解锁")
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(.primary)

                // 徽章
                AchievementBadge(type: badge, size: 100, showLabel: false, isAnimated: true)

                // 描述
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text(badge.label)
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(badge.color)

                    Text(badge.description)
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // 关闭按钮
                Button {
                    dismiss()
                } label: {
                    Text("太棒了！")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(badge.color)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous))
                }
            }
            .padding(DesignSystem.Spacing.xl)
            .background(DesignSystem.NeutralColors.background)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge, style: .continuous))
            .shadow(radius: 20)
            .padding(DesignSystem.Spacing.xl)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }

            // 触觉反馈
            HapticFeedback.success()
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 0.8
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

/// 成就墙 - 显示所有已解锁的成就
struct AchievementWallView: View {
    let unlockedBadges: [AchievementBadge.BadgeType]
    let allBadges: [AchievementBadge.BadgeType] = [
        .dailyGoal,
        .weekStreak,
        .twoWeekStreak,
        .monthStreak,
        .twoMonthStreak,
        .threeMonthStreak,
        .hundredHours,
        .fiveHundredHours,
        .thousandHours,
        .weeklyChampion
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // 标题
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("成就墙")
                        .font(DesignSystem.Typography.largeTitle)

                    Text("已解锁 \(unlockedBadges.count) / \(allBadges.count)")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }

                // 成就网格
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: DesignSystem.Spacing.lg) {
                    ForEach(allBadges, id: \.label) { badge in
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            if unlockedBadges.contains(where: { $0.label == badge.label }) {
                                AchievementBadge(type: badge, size: 60, showLabel: false, isAnimated: false)
                            } else {
                                // 未解锁的徽章（灰色）
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 60, height: 60)

                                    Image(systemName: badge.icon)
                                        .font(.system(size: 30))
                                        .foregroundStyle(.gray.opacity(0.3))
                                }
                            }

                            Text(badge.label)
                                .font(DesignSystem.Typography.caption2)
                                .foregroundStyle(unlockedBadges.contains(where: { $0.label == badge.label }) ? .primary : .secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("成就")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("徽章") {
    VStack(spacing: 30) {
        HStack(spacing: 20) {
            AchievementBadge(type: .dailyGoal)
            AchievementBadge(type: .weekStreak)
            AchievementBadge(type: .monthStreak)
        }

        HStack(spacing: 20) {
            AchievementBadge(type: .hundredHours)
            AchievementBadge(type: .weeklyChampion)
        }
    }
    .padding()
}

#Preview("解锁弹窗") {
    AchievementUnlockedView(badge: .monthStreak) {
        print("Dismissed")
    }
}

#Preview("成就墙") {
    NavigationStack {
        AchievementWallView(unlockedBadges: [
            .dailyGoal,
            .weekStreak,
            .hundredHours
        ])
    }
}
