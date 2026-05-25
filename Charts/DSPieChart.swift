import SwiftUI

/// 饼图组件 - 用于展示错误类型分布、任务状态分布等占比数据
struct DSPieChart: View {
    let slices: [Slice]
    var size: CGFloat = 200
    var showLegend: Bool = true
    var showPercentages: Bool = true
    var isAnimated: Bool = true

    struct Slice: Identifiable {
        let id = UUID()
        let value: Double
        let color: Color
        let label: String
    }

    @State private var animatedProgress: Double = 0

    private var total: Double {
        slices.reduce(0) { $0 + $1.value }
    }

    private var sliceAngles: [(startAngle: Angle, endAngle: Angle, color: Color, percentage: Double)] {
        var currentAngle: Double = 0
        return slices.map { slice in
            let percentage = slice.value / total
            let startAngle = Angle(degrees: currentAngle)
            currentAngle += percentage * 360
            let endAngle = Angle(degrees: currentAngle)
            return (startAngle, endAngle, slice.color, percentage)
        }
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // 饼图
            ZStack {
                ForEach(Array(sliceAngles.enumerated()), id: \.offset) { index, slice in
                    PieSlice(
                        startAngle: slice.startAngle,
                        endAngle: slice.endAngle,
                        progress: animatedProgress
                    )
                    .fill(slice.color)
                }
            }
            .frame(width: size, height: size)

            // 图例
            if showLegend {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Circle()
                                .fill(slice.color)
                                .frame(width: 10, height: 10)

                            Text(slice.label)
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text("\(Int(slice.value))")
                                .font(DesignSystem.Typography.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            if showPercentages {
                                Text("(\(Int(slice.value / total * 100))%)")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(.secondary)
                            }
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

/// 饼图切片形状
struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        let adjustedEndAngle = Angle(
            degrees: startAngle.degrees + (endAngle.degrees - startAngle.degrees) * progress
        )

        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle - .degrees(90),
            endAngle: adjustedEndAngle - .degrees(90),
            clockwise: false
        )
        path.closeSubpath()

        return path
    }
}

/// 环形饼图（甜甜圈图）- 中间有空洞的饼图
struct DSDonutChart: View {
    let slices: [DSPieChart.Slice]
    var size: CGFloat = 200
    var innerRadiusRatio: CGFloat = 0.6
    var showLegend: Bool = true
    var showPercentages: Bool = true
    var centerContent: AnyView? = nil
    var isAnimated: Bool = true

    @State private var animatedProgress: Double = 0

    private var total: Double {
        slices.reduce(0) { $0 + $1.value }
    }

    private var sliceAngles: [(startAngle: Angle, endAngle: Angle, color: Color, percentage: Double)] {
        var currentAngle: Double = 0
        return slices.map { slice in
            let percentage = slice.value / total
            let startAngle = Angle(degrees: currentAngle)
            currentAngle += percentage * 360
            let endAngle = Angle(degrees: currentAngle)
            return (startAngle, endAngle, slice.color, percentage)
        }
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // 环形图
            ZStack {
                ForEach(Array(sliceAngles.enumerated()), id: \.offset) { index, slice in
                    DonutSlice(
                        startAngle: slice.startAngle,
                        endAngle: slice.endAngle,
                        innerRadiusRatio: innerRadiusRatio,
                        progress: animatedProgress
                    )
                    .fill(slice.color)
                }

                // 中心内容
                if let centerContent {
                    centerContent
                }
            }
            .frame(width: size, height: size)

            // 图例
            if showLegend {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Circle()
                                .fill(slice.color)
                                .frame(width: 10, height: 10)

                            Text(slice.label)
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text("\(Int(slice.value))")
                                .font(DesignSystem.Typography.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            if showPercentages {
                                Text("(\(Int(slice.value / total * 100))%)")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(.secondary)
                            }
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

/// 环形切片形状
struct DonutSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let innerRadiusRatio: CGFloat
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * innerRadiusRatio

        let adjustedEndAngle = Angle(
            degrees: startAngle.degrees + (endAngle.degrees - startAngle.degrees) * progress
        )

        var path = Path()

        // 外圆弧
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle - .degrees(90),
            endAngle: adjustedEndAngle - .degrees(90),
            clockwise: false
        )

        // 连接到内圆
        let innerEndPoint = CGPoint(
            x: center.x + innerRadius * cos((adjustedEndAngle.radians - .pi / 2)),
            y: center.y + innerRadius * sin((adjustedEndAngle.radians - .pi / 2))
        )
        path.addLine(to: innerEndPoint)

        // 内圆弧（反向）
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: adjustedEndAngle - .degrees(90),
            endAngle: startAngle - .degrees(90),
            clockwise: true
        )

        path.closeSubpath()

        return path
    }
}

#Preview("饼图") {
    DSPieChart(
        slices: [
            .init(value: 5, color: .red, label: "概念错误"),
            .init(value: 3, color: .orange, label: "方法错误"),
            .init(value: 2, color: .yellow, label: "计算错误"),
            .init(value: 1, color: .blue, label: "其他")
        ]
    )
    .padding()
}

#Preview("环形图") {
    DSDonutChart(
        slices: [
            .init(value: 8, color: .green, label: "已完成"),
            .init(value: 3, color: .blue, label: "进行中"),
            .init(value: 2, color: .orange, label: "待办")
        ],
        centerContent: AnyView(
            VStack(spacing: 4) {
                Text("13")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("总任务")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        )
    )
    .padding()
}
