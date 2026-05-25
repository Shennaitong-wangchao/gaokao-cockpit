import SwiftUI

/// 折线图组件 - 用于展示每日学习时长趋势等时间序列数据
struct DSLineChart: View {
    let dataPoints: [DataPoint]
    var lineColor: Color = .blue
    var fillGradient: Bool = true
    var showPoints: Bool = true
    var showGrid: Bool = true
    var showLabels: Bool = true
    var isAnimated: Bool = true
    var height: CGFloat = 200

    struct DataPoint: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
    }

    @State private var animatedProgress: Double = 0

    private var maxValue: Double {
        dataPoints.map { $0.value }.max() ?? 1
    }

    private var minValue: Double {
        dataPoints.map { $0.value }.min() ?? 0
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // 图表区域
            GeometryReader { geometry in
                ZStack(alignment: .bottomLeading) {
                    // 网格线
                    if showGrid {
                        gridLines(in: geometry.size)
                    }

                    // 渐变填充
                    if fillGradient {
                        linePath(in: geometry.size, closed: true)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        lineColor.opacity(0.3),
                                        lineColor.opacity(0.05)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .mask(
                                linePath(in: geometry.size, closed: true)
                                    .trim(from: 0, to: animatedProgress)
                            )
                    }

                    // 折线
                    linePath(in: geometry.size, closed: false)
                        .trim(from: 0, to: animatedProgress)
                        .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    // 数据点
                    if showPoints {
                        dataPointsView(in: geometry.size)
                    }
                }
            }
            .frame(height: height)

            // 标签
            if showLabels {
                HStack(spacing: 0) {
                    ForEach(Array(dataPoints.enumerated()), id: \.element.id) { index, point in
                        Text(point.label)
                            .font(DesignSystem.Typography.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .onAppear {
            if isAnimated {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animatedProgress = 1.0
                }
            } else {
                animatedProgress = 1.0
            }
        }
    }

    private func linePath(in size: CGSize, closed: Bool) -> Path {
        guard !dataPoints.isEmpty else { return Path() }

        let stepX = size.width / CGFloat(max(dataPoints.count - 1, 1))
        let range = maxValue - minValue
        let scale = range > 0 ? size.height / range : 1

        var path = Path()

        // 起点
        let firstY = size.height - (dataPoints[0].value - minValue) * scale
        path.move(to: CGPoint(x: 0, y: firstY))

        // 连接所有点
        for (index, point) in dataPoints.enumerated() {
            let x = CGFloat(index) * stepX
            let y = size.height - (point.value - minValue) * scale
            path.addLine(to: CGPoint(x: x, y: y))
        }

        // 如果需要闭合路径（用于填充）
        if closed {
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height))
            path.closeSubpath()
        }

        return path
    }

    private func dataPointsView(in size: CGSize) -> some View {
        let stepX = size.width / CGFloat(max(dataPoints.count - 1, 1))
        let range = maxValue - minValue
        let scale = range > 0 ? size.height / range : 1

        return ForEach(Array(dataPoints.enumerated()), id: \.element.id) { index, point in
            let x = CGFloat(index) * stepX
            let y = size.height - (point.value - minValue) * scale

            Circle()
                .fill(lineColor)
                .frame(width: 6, height: 6)
                .position(x: x, y: y)
                .opacity(animatedProgress)
        }
    }

    private func gridLines(in size: CGSize) -> some View {
        let gridCount = 4
        return ForEach(0..<gridCount, id: \.self) { index in
            let y = size.height * CGFloat(index) / CGFloat(gridCount - 1)
            Path { path in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        }
    }
}

/// 多线折线图 - 用于对比多个系列的趋势
struct DSMultiLineChart: View {
    let series: [Series]
    var showGrid: Bool = true
    var showLabels: Bool = true
    var showLegend: Bool = true
    var isAnimated: Bool = true
    var height: CGFloat = 200

    struct Series: Identifiable {
        let id = UUID()
        let label: String
        let color: Color
        let dataPoints: [DataPoint]
    }

    struct DataPoint: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
    }

    @State private var animatedProgress: Double = 0

    private var allValues: [Double] {
        series.flatMap { $0.dataPoints.map { $0.value } }
    }

    private var maxValue: Double {
        allValues.max() ?? 1
    }

    private var minValue: Double {
        allValues.min() ?? 0
    }

    private var labels: [String] {
        series.first?.dataPoints.map { $0.label } ?? []
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // 图例
            if showLegend {
                HStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(series) { s in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(s.color)
                                .frame(width: 8, height: 8)

                            Text(s.label)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // 图表区域
            GeometryReader { geometry in
                ZStack(alignment: .bottomLeading) {
                    // 网格线
                    if showGrid {
                        gridLines(in: geometry.size)
                    }

                    // 多条折线
                    ForEach(series) { s in
                        linePath(for: s.dataPoints, in: geometry.size)
                            .trim(from: 0, to: animatedProgress)
                            .stroke(s.color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    }
                }
            }
            .frame(height: height)

            // 标签
            if showLabels {
                HStack(spacing: 0) {
                    ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                        Text(label)
                            .font(DesignSystem.Typography.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .onAppear {
            if isAnimated {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animatedProgress = 1.0
                }
            } else {
                animatedProgress = 1.0
            }
        }
    }

    private func linePath(for dataPoints: [DataPoint], in size: CGSize) -> Path {
        guard !dataPoints.isEmpty else { return Path() }

        let stepX = size.width / CGFloat(max(dataPoints.count - 1, 1))
        let range = maxValue - minValue
        let scale = range > 0 ? size.height / range : 1

        var path = Path()

        // 起点
        let firstY = size.height - (dataPoints[0].value - minValue) * scale
        path.move(to: CGPoint(x: 0, y: firstY))

        // 连接所有点
        for (index, point) in dataPoints.enumerated() {
            let x = CGFloat(index) * stepX
            let y = size.height - (point.value - minValue) * scale
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }

    private func gridLines(in size: CGSize) -> some View {
        let gridCount = 4
        return ForEach(0..<gridCount, id: \.self) { index in
            let y = size.height * CGFloat(index) / CGFloat(gridCount - 1)
            Path { path in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        }
    }
}

#Preview("单线折线图") {
    DSLineChart(
        dataPoints: [
            .init(label: "周一", value: 120),
            .init(label: "周二", value: 150),
            .init(label: "周三", value: 90),
            .init(label: "周四", value: 180),
            .init(label: "周五", value: 160),
            .init(label: "周六", value: 200),
            .init(label: "周日", value: 140)
        ],
        lineColor: .blue
    )
    .padding()
}

#Preview("多线折线图") {
    DSMultiLineChart(
        series: [
            .init(
                label: "学习时长",
                color: .blue,
                dataPoints: [
                    .init(label: "周一", value: 120),
                    .init(label: "周二", value: 150),
                    .init(label: "周三", value: 90),
                    .init(label: "周四", value: 180),
                    .init(label: "周五", value: 160)
                ]
            ),
            .init(
                label: "目标时长",
                color: .green,
                dataPoints: [
                    .init(label: "周一", value: 150),
                    .init(label: "周二", value: 150),
                    .init(label: "周三", value: 150),
                    .init(label: "周四", value: 150),
                    .init(label: "周五", value: 150)
                ]
            )
        ]
    )
    .padding()
}
