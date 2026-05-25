import SwiftUI

/// 动画系统 - 统一的动画效果
struct AnimationSystem {

    // MARK: - 基础动画曲线

    /// 弹性动画（用于按钮点击、卡片出现）
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// 平滑动画（用于状态切换、颜色变化）
    static let smooth = Animation.easeInOut(duration: 0.3)

    /// 快速动画（用于小元素的快速反馈）
    static let quick = Animation.easeInOut(duration: 0.2)

    /// 慢速动画（用于大范围的布局变化）
    static let slow = Animation.easeInOut(duration: 0.5)

    /// 弹跳动画（用于成就庆祝）
    static let bounce = Animation.interpolatingSpring(stiffness: 300, damping: 10)

    // MARK: - 数值动画

    /// 数字滚动动画视图
    struct AnimatedNumber: View {
        let value: Int
        var duration: Double = 0.8

        @State private var displayValue: Int = 0

        var body: some View {
            Text("\(displayValue)")
                .contentTransition(.numericText(value: Double(displayValue)))
                .animation(.easeInOut(duration: duration), value: displayValue)
                .onAppear {
                    displayValue = value
                }
                .onChange(of: value) { oldValue, newValue in
                    displayValue = newValue
                }
        }
    }

    // MARK: - 成就动画

    /// 庆祝粒子效果
    struct ConfettiView: View {
        @State private var isAnimating = false

        var body: some View {
            ZStack {
                ForEach(0..<20, id: \.self) { index in
                    ConfettiPiece(index: index, isAnimating: $isAnimating)
                }
            }
            .onAppear {
                isAnimating = true
            }
        }
    }

    /// 单个粒子
    private struct ConfettiPiece: View {
        let index: Int
        @Binding var isAnimating: Bool

        @State private var offset: CGSize = .zero
        @State private var opacity: Double = 1.0
        @State private var rotation: Double = 0

        private let colors: [Color] = [
            .red, .orange, .yellow, .green, .blue, .purple, .pink
        ]

        var body: some View {
            Circle()
                .fill(colors[index % colors.count])
                .frame(width: 8, height: 8)
                .offset(offset)
                .opacity(opacity)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.easeOut(duration: 1.5)) {
                        offset = CGSize(
                            width: CGFloat.random(in: -150...150),
                            height: CGFloat.random(in: -200...100)
                        )
                        opacity = 0
                        rotation = Double.random(in: 0...720)
                    }
                }
        }
    }

    /// 完成任务的勾选动画
    struct CheckmarkAnimation: View {
        @State private var progress: CGFloat = 0
        @State private var scale: CGFloat = 0.5
        @State private var opacity: Double = 0

        var body: some View {
            ZStack {
                Circle()
                    .fill(DesignSystem.SemanticColors.success.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .scaleEffect(scale)
                    .opacity(opacity)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(DesignSystem.SemanticColors.success)
                    .scaleEffect(scale)
                    .opacity(opacity)
            }
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }

                // 1 秒后淡出
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0
                    }
                }
            }
        }
    }

    /// 星星闪烁动画（用于掌握错题）
    struct StarAnimation: View {
        @State private var scale: CGFloat = 0.5
        @State private var rotation: Double = 0
        @State private var opacity: Double = 0

        var body: some View {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .scaleEffect(scale)
                    .opacity(opacity)

                Image(systemName: "star.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.yellow)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                    .opacity(opacity)
            }
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                    rotation = 360
                }

                // 1 秒后淡出
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0
                    }
                }
            }
        }
    }

    // MARK: - 过渡动画

    /// 卡片出现动画修饰符
    struct CardAppearModifier: ViewModifier {
        @State private var opacity: Double = 0
        @State private var offset: CGFloat = 20

        let delay: Double

        func body(content: Content) -> some View {
            content
                .opacity(opacity)
                .offset(y: offset)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                        opacity = 1.0
                        offset = 0
                    }
                }
        }
    }

    /// 错开动画修饰符（用于列表项）
    struct StaggeredAppearModifier: ViewModifier {
        let index: Int
        @State private var opacity: Double = 0
        @State private var offset: CGFloat = 20

        func body(content: Content) -> some View {
            content
                .opacity(opacity)
                .offset(y: offset)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.3).delay(Double(index) * 0.05)) {
                        opacity = 1.0
                        offset = 0
                    }
                }
        }
    }

    /// 脉冲动画修饰符（用于强调）
    struct PulseModifier: ViewModifier {
        @State private var scale: CGFloat = 1.0

        func body(content: Content) -> some View {
            content
                .scaleEffect(scale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        scale = 1.05
                    }
                }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// 应用卡片出现动画
    func cardAppear(delay: Double = 0) -> some View {
        self.modifier(AnimationSystem.CardAppearModifier(delay: delay))
    }

    /// 应用错开出现动画（用于列表）
    func staggeredAppear(index: Int) -> some View {
        self.modifier(AnimationSystem.StaggeredAppearModifier(index: index))
    }

    /// 应用脉冲动画
    func pulse() -> some View {
        self.modifier(AnimationSystem.PulseModifier())
    }
}

// MARK: - 动画触发器

/// 动画触发管理器
@Observable
class AnimationTrigger {
    var showCheckmark = false
    var showStar = false
    var showConfetti = false

    /// 触发完成任务动画
    func triggerCheckmark() {
        showCheckmark = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showCheckmark = false
        }
    }

    /// 触发星星动画
    func triggerStar() {
        showStar = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showStar = false
        }
    }

    /// 触发庆祝动画
    func triggerConfetti() {
        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showConfetti = false
        }
    }
}

// MARK: - 动画覆盖层

/// 全局动画覆盖层
struct AnimationOverlay: View {
    @Environment(AnimationTrigger.self) private var trigger

    var body: some View {
        ZStack {
            if trigger.showCheckmark {
                AnimationSystem.CheckmarkAnimation()
            }

            if trigger.showStar {
                AnimationSystem.StarAnimation()
            }

            if trigger.showConfetti {
                AnimationSystem.ConfettiView()
            }
        }
        .allowsHitTesting(false)
    }
}
