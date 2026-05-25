import SwiftUI

/// 环形图组件 - 用于展示完成率、状态分数等单一数值
struct DSRingChart: View {
    let value: Double // 0.0 - 1.0
    var title: String? = nil
    var subtitle: String? = nil
    var lineWidth: CGFloat = 12
    var size: CGFloat = 120
    var color: Color = .blue
    var backgroundColor: Color = Color.gray.opacity(0.2)
    var showPercentage: Bool = true
    var isAnimated: Bool = true

    @State private var animatedValue: Double = 0

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ZStack {
                // 背景圆环
                Circle()
                    .stroke(backgroundColor, lineWidth: lineWidth)
                    .frame(width: size, height: size)

                // 进度圆环
                Circle()
                    .trim(from: 0, to: animatedValue)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))

                // 中心内容
                VStack(spacing: 4) {
                    if showPercentage {
                        Text("\(Int(value * 100))%")
                            .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                            .foregroundStyle(color)
                    }

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let title {
                Text(title)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            if isAnimated {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animatedValue = value
                }
            } else {
                animatedValue = value
            }
        }
        .onChange(of: value) { oldValue, newValue in
            if isAnimated {
                withAnimation(.easeInOut(duration: 0.5)) {
                    animatedValue = newValue
                }
            } else {
                animatedValue = newValue
            }
        }
    }
}

/// 多段环形图 - 用于展示多个分类的占比
struct DSMultiRingChart: View {
    let segments: [Segment]
    var lineWidth: CGFloat = 12
    var size: CGFloat = 120
    var showLegend: Bool = true
    var isAnimated: Bool = true

    struct Segment: Identifiable {
        let id = UUID()
        let value: Double
        let color: Color
        let label: String
    }

    @State private var animatedProgress: Double = 0

    private var total: Double {
        segments.reduce(0) { $0 + $1.value }
    }

    private var normalizedSegments: [(start: Double, end: Double, color: Color)] {
        var current: Double = 0
        return segments.map { segment in
            let start = current
            let percentage = segment.value / total
            current += percentage
            return (start, current, segment.color)
        }
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                // 背景圆环
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: lineWidth)
                    .frame(width: size, height: size)

                // 多段进度圆环
                ForEach(Array(normalizedSegments.enumerated()), id: \.offset) { index, segment in
                    Circle()
                        .trim(from: segment.start * animatedProgress, to: segment.end * animatedProgress)
                        .stroke(
                            segment.color,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(-90))
                }

                // 中心总数
                VStack(spacing: 2) {
                    Text("\(Int(total))")
                        .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("总计")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // 图例
            if showLegend {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    ForEach(segments) { segment in
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Circle()
                                .fill(segment.color)
                                .frame(width: 8, height: 8)

                            Text(segment.label)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text("\(Int(segment.value))")
                                .font(DesignSystem.Typography.caption.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text("(\(Int(segment.value / total * 100))%)")
                                .font(DesignSystem.Typography.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .onAppear {
            if isAnimated {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animatedProgress = 1.0
                }
            } else {
                animatedProgress = 1.0
            }
        }
    }
}

#Preview("单一环形图") {
    VStack(spacing: 40) {
        DSRingChart(
            value: 0.75,
            title: "完成率",
            subtitle: "良好",
            color: .green
        )

        DSRingChart(
            value: 0.45,
            title: "学习进度",
            lineWidth: 8,
            size: 100,
            color: .blue
        )
    }
    .padding()
}

#Preview("多段环形图") {
    DSMultiRingChart(
        segments: [
            .init(value: 5, color: .green, label: "已完成"),
            .init(value: 3, color: .blue, label: "进行中"),
            .init(value: 2, color: .orange, label: "待办")
        ],
        size: 140
    )
    .padding()
}
