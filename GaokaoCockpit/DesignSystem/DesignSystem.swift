import SwiftUI

/// 设计系统 - 统一的视觉规范
struct DesignSystem {

    // MARK: - 颜色系统

    /// 语义色
    struct SemanticColors {
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        static let pending = Color.orange
        static let inProgress = Color.blue
        static let done = Color.green
        static let skipped = Color.gray
    }

    /// 主题色（根据上下文动态变化）
    struct ThemeColors {
        static let morning = Color(red: 0.20, green: 0.78, blue: 0.35)      // #34C759 清新青绿
        static let afternoon = Color(red: 0.00, green: 0.48, blue: 1.00)    // #007AFF 专注深蓝
        static let evening = Color(red: 0.35, green: 0.34, blue: 0.84)      // #5856D6 沉稳靛蓝
        static let night = Color(red: 0.69, green: 0.32, blue: 0.87)        // #AF52DE 柔和紫色
        static let achievement = Color(red: 1.00, green: 0.58, blue: 0.00)  // #FF9500 温暖橙金
        static let lowEnergy = Color(red: 0.35, green: 0.47, blue: 0.65)    // #5A78A6 柔和灰蓝
    }

    /// 中性色
    struct NeutralColors {
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)
        static let separator = Color(.separator)
    }

    // MARK: - 字体系统

    /// 字体样式
    struct Typography {
        // 标题
        static let largeTitle = Font.largeTitle.bold()
        static let title = Font.title.weight(.bold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.semibold)

        // 正文
        static let headline = Font.headline
        static let headlineBold = Font.headline.weight(.bold)
        static let body = Font.body
        static let bodyBold = Font.body.weight(.semibold)

        // 辅助文本
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2

        // 数字（等宽）
        static let numberLarge = Font.title.weight(.bold).monospacedDigit()
        static let numberMedium = Font.title3.weight(.bold).monospacedDigit()
        static let numberSmall = Font.headline.monospacedDigit()
    }

    // MARK: - 间距系统

    /// 间距（基于 4pt 基准）
    struct Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    // MARK: - 圆角系统

    /// 圆角大小
    struct CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let xlarge: CGFloat = 16
        static let xxlarge: CGFloat = 20
    }

    // MARK: - 阴影系统

    /// 阴影样式
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat

        static let none = Shadow(color: .clear, radius: 0, x: 0, y: 0)

        static let small = Shadow(
            color: Color.black.opacity(0.08),
            radius: 4,
            x: 0,
            y: 1
        )

        static let medium = Shadow(
            color: Color.black.opacity(0.1),
            radius: 8,
            x: 0,
            y: 2
        )

        static let large = Shadow(
            color: Color.black.opacity(0.12),
            radius: 16,
            x: 0,
            y: 4
        )
    }

    // MARK: - 动画系统

    /// 动画曲线
    struct Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
    }
}

// MARK: - View Extensions

extension View {
    /// 应用设计系统阴影
    func dsShadow(_ shadow: DesignSystem.Shadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}
