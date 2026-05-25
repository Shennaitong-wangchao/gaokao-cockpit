import SwiftUI

// MARK: - DSCard（设计系统卡片）

/// 设计系统卡片 - 支持不同圆角、阴影、彩色强调
struct DSCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = DesignSystem.CornerRadius.medium
    var shadow: DesignSystem.Shadow = .none
    var accentColor: Color? = nil
    var accentPosition: AccentPosition = .leading
    var backgroundColor: Color = DesignSystem.NeutralColors.secondaryBackground

    enum AccentPosition {
        case leading, top, trailing, bottom
    }

    init(
        cornerRadius: CGFloat = DesignSystem.CornerRadius.medium,
        shadow: DesignSystem.Shadow = .none,
        accentColor: Color? = nil,
        accentPosition: AccentPosition = .leading,
        backgroundColor: Color = DesignSystem.NeutralColors.secondaryBackground,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.accentColor = accentColor
        self.accentPosition = accentPosition
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignSystem.Spacing.lg)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                if let accentColor {
                    accentBar(color: accentColor)
                }
            }
            .dsShadow(shadow)
    }

    @ViewBuilder
    private func accentBar(color: Color) -> some View {
        switch accentPosition {
        case .leading:
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(color)
                    .frame(width: 4)
                Spacer()
            }
        case .top:
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(color)
                    .frame(height: 4)
                Spacer()
            }
        case .trailing:
            HStack(spacing: 0) {
                Spacer()
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(color)
                    .frame(width: 4)
            }
        case .bottom:
            VStack(spacing: 0) {
                Spacer()
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(color)
                    .frame(height: 4)
            }
        }
    }
}

// MARK: - DSStatCard（统计数字卡片）

/// 统计数字卡片 - 支持图标、趋势、彩色背景、数值动画
struct DSStatCard: View {
    let title: String
    let value: String
    var icon: String? = nil
    var trend: Trend? = nil
    var backgroundColor: Color = DesignSystem.NeutralColors.background
    var valueColor: Color = .primary
    var isAnimated: Bool = true

    enum Trend {
        case up(String)
        case down(String)
        case neutral(String)

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .secondary
            }
        }

        var text: String {
            switch self {
            case .up(let text), .down(let text), .neutral(let text):
                return text
            }
        }
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(valueColor)
            }

            // 使用数值动画
            if isAnimated, let numericValue = Int(value) {
                AnimationSystem.AnimatedNumber(value: numericValue)
                    .font(DesignSystem.Typography.numberMedium)
                    .foregroundStyle(valueColor)
            } else {
                Text(value)
                    .font(DesignSystem.Typography.numberMedium)
                    .foregroundStyle(valueColor)
            }

            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)

            if let trend {
                HStack(spacing: 4) {
                    Image(systemName: trend.icon)
                        .font(.caption2)
                    Text(trend.text)
                        .font(.caption2)
                }
                .foregroundStyle(trend.color)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)：\(value)")
    }
}

// MARK: - DSTag（标签）

/// 设计系统标签 - 支持不同颜色主题、大小、图标
struct DSTag: View {
    let text: String
    var icon: String? = nil
    var style: TagStyle = .neutral
    var size: TagSize = .small

    enum TagStyle {
        case success, warning, error, info, neutral, custom(Color)

        var color: Color {
            switch self {
            case .success: return DesignSystem.SemanticColors.success
            case .warning: return DesignSystem.SemanticColors.warning
            case .error: return DesignSystem.SemanticColors.error
            case .info: return DesignSystem.SemanticColors.info
            case .neutral: return .secondary
            case .custom(let color): return color
            }
        }

        var backgroundColor: Color {
            color.opacity(0.15)
        }
    }

    enum TagSize {
        case small, medium

        var font: Font {
            switch self {
            case .small: return DesignSystem.Typography.caption
            case .medium: return DesignSystem.Typography.subheadline
            }
        }

        var padding: (horizontal: CGFloat, vertical: CGFloat) {
            switch self {
            case .small: return (7, 3)
            case .medium: return (10, 5)
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: return DesignSystem.CornerRadius.small
            case .medium: return DesignSystem.CornerRadius.medium
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(size.font)
            }
            Text(text)
                .font(size.font)
        }
        .foregroundStyle(style.color)
        .lineLimit(1)
        .padding(.horizontal, size.padding.horizontal)
        .padding(.vertical, size.padding.vertical)
        .background(style.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous))
    }
}

// MARK: - DSProgressBar（进度条）

/// 进度条组件 - 支持线性和环形、渐变色、动画
struct DSProgressBar: View {
    let progress: Double // 0.0 - 1.0
    var style: ProgressStyle = .linear
    var color: Color = .blue
    var showPercentage: Bool = true
    var isAnimated: Bool = true

    enum ProgressStyle {
        case linear
        case ring(lineWidth: CGFloat = 8)
    }

    var body: some View {
        switch style {
        case .linear:
            linearProgress
        case .ring(let lineWidth):
            ringProgress(lineWidth: lineWidth)
        }
    }

    private var linearProgress: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.gray.opacity(0.2))

                    // 进度
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color)
                        .frame(width: geometry.size.width * progress)
                        .animation(isAnimated ? DesignSystem.Animation.smooth : nil, value: progress)
                }
            }
            .frame(height: 8)
        }
    }

    private func ringProgress(lineWidth: CGFloat) -> some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

            // 进度圆环
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(isAnimated ? DesignSystem.Animation.smooth : nil, value: progress)

            // 百分比文字
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(DesignSystem.Typography.numberSmall)
                    .foregroundStyle(color)
            }
        }
    }
}

// MARK: - DSButton（按钮）

/// 设计系统按钮 - 统一样式、加载状态、弹性动画
struct DSButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    var style: ButtonStyle = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false

    enum ButtonStyle {
        case primary, secondary, tertiary, destructive

        var backgroundColor: Color {
            switch self {
            case .primary: return .blue
            case .secondary: return Color.gray.opacity(0.2)
            case .tertiary: return .clear
            case .destructive: return .red
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary, .destructive: return .white
            case .secondary, .tertiary: return .primary
            }
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else {
                    if let icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .font(DesignSystem.Typography.headline)
            .foregroundStyle(style.foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(style.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous))
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1.0)
        .animation(DesignSystem.Animation.spring, value: isLoading)
    }
}

// MARK: - 保留旧组件以兼容现有代码

/// 旧的 TodayCard - 保留以兼容现有代码
struct TodayCard<Content: View>: View {
    var tint: Color?
    let content: Content

    init(tint: Color? = nil, @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        DSCard(
            accentColor: tint,
            backgroundColor: tint != nil ? tint!.opacity(0.12) : DesignSystem.NeutralColors.secondaryBackground,
            content: { content }
        )
    }
}

/// 旧的 StatPill - 保留以兼容现有代码
struct StatPill: View {
    let title: String
    let value: String
    var isPositive = false

    var body: some View {
        DSStatCard(
            title: title,
            value: value,
            valueColor: isPositive ? .green : .primary
        )
    }
}

/// 旧的 SmallTag - 保留以兼容现有代码
struct SmallTag: View {
    let text: String

    var body: some View {
        DSTag(text: text, style: .neutral, size: .small)
    }
}

/// 旧的 SectionTitle - 保留以兼容现有代码
struct SectionTitle: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(DesignSystem.Typography.headline)
            .accessibilityAddTraits(.isHeader)
    }
}

/// 旧的 LabeledTextEditor - 保留以兼容现有代码
struct LabeledTextEditor: View {
    let title: String
    let subtitle: String
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 92

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .frame(minHeight: minHeight)
                    .scrollContentBackground(.hidden)
                    .accessibilityLabel(title)
                    .accessibilityHint(subtitle)
                    .accessibilityValue(text.isEmpty ? "空" : text)

                if text.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.NeutralColors.background)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                    .stroke(DesignSystem.NeutralColors.separator.opacity(0.45), lineWidth: 1)
            }
        }
    }
}
