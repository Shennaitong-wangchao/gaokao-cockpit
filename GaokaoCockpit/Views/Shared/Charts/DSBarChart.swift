import SwiftUI

/// 条形图组件 - 用于展示各科目任务数、错题数等对比数据
struct DSBarChart: View {
    let data: [BarData]
    var maxValue: Double? = nil
    var barColor: Color = .blue
    var showValues: Bool = true
    var isAnimated: Bool = true
    var orientation: Orientation = .vertical

    enum Orientation {
        case vertical, horizontal
    }

    struct BarData: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
        var color: Color?
    }

    @State private var animatedProgress: Double = 0

    private var computedMaxValue: Double {
        maxValue ?? (data.map { $0.value }.max() ?? 1)
    }

    var body: some View {
        Group {
            if orientation == .vertical {
                verticalChart
            } else {
                horizontalChart
            }
        }
        .onAppear {
            if isAnimated {
                withAnimation(.easeOut(duration: 0.6)) {
                    animatedProgress = 1.0
                }
            } else {
                animatedProgress = 1.0
            }
        }
    }

    private var verticalChart: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // 图表区域
            HStack(alignment: .bottom, spacing: DesignSystem.Spacing.sm) {
                ForEach(data) { item in
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        // 数值标签
                        if showValues {
                            Text("\(Int(item.value))")
                                .font(DesignSystem.Typography.caption2)
                                .foregroundStyle(.secondary)
                                .opacity(animatedProgress)
                        }

                        // 条形
                        GeometryReader { geometry in
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(item.color ?? barColor)
                                    .frame(
                                        height: geometry.size.height * (item.value / computedMaxValue) * animatedProgress
                                    )
                            }
                        }

                        // 标签
                        Text(item.label)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 150)
        }
    }

    private var horizontalChart: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            ForEach(data) { item in
                HStack(spacing: DesignSystem.Spacing.sm) {
                    // 标签
                    Text(item.label)
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 60, alignment: .leading)

                    // 条形
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(item.color ?? barColor)
                                .frame(
                                    width: geometry.size.width * (item.value / computedMaxValue) * animatedProgress
                                )

                            Spacer(minLength: 0)
                        }
                    }
                    .frame(height: 24)

                    // 数值标签
                    if showValues {
                        Text("\(Int(item.value))")
                            .font(DesignSystem.Typography.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 30, alignment: .trailing)
                            .opacity(animatedProgress)
                    }
                }
            }
        }
    }
}

/// 分组条形图 - 用于对比多个系列的数据
struct DSGroupedBarChart: View {
    let groups: [GroupData]
    var maxValue: Double? = nil
    var showValues: Bool = true
    var isAnimated: Bool = true

    struct GroupData: Identifiable {
        let id = UUID()
        let label: String
        let bars: [BarItem]
    }

    struct BarItem: Identifiable {
        let id = UUID()
        let value: Double
        let color: Color
        let legend: String
    }

    @State private var animatedProgress: Double = 0

    private var computedMaxValue: Double {
        maxValue ?? (groups.flatMap { $0.bars.map { $0.value } }.max() ?? 1)
    }

    private var legends: [BarItem] {
        guard let firstGroup = groups.first else { return [] }
        return firstGroup.bars
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // 图表区域
            HStack(alignment: .bottom, spacing: DesignSystem.Spacing.md) {
                ForEach(groups) { group in
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        // 分组条形
                        HStack(alignment: .bottom, spacing: 4) {
                            ForEach(group.bars) { bar in
                                VStack(spacing: 2) {
                                    // 数值标签
                                    if showValues {
                                        Text("\(Int(bar.value))")
                                            .font(.system(size: 8))
                                            .foregroundStyle(.secondary)
                                            .opacity(animatedProgress)
                                    }

                                    // 条形
                                    GeometryReader { geometry in
                                        VStack {
                                            Spacer()
                                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                                .fill(bar.color)
                                                .frame(
                                                    height: geometry.size.height * (bar.value / computedMaxValue) * animatedProgress
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 120)

                        // 分组标签
                        Text(group.label)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // 图例
            HStack(spacing: DesignSystem.Spacing.md) {
                ForEach(legends) { legend in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(legend.color)
                            .frame(width: 8, height: 8)

                        Text(legend.legend)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onAppear {
            if isAnimated {
                withAnimation(.easeOut(duration: 0.6)) {
                    animatedProgress = 1.0
                }
            } else {
                animatedProgress = 1.0
            }
        }
    }
}

#Preview("垂直条形图") {
    DSBarChart(
        data: [
            .init(label: "数学", value: 8),
            .init(label: "语文", value: 5),
            .init(label: "英语", value: 6),
            .init(label: "物理", value: 4),
            .init(label: "化学", value: 3)
        ],
        barColor: .blue
    )
    .padding()
}

#Preview("水平条形图") {
    DSBarChart(
        data: [
            .init(label: "数学", value: 8, color: .blue),
            .init(label: "语文", value: 5, color: .green),
            .init(label: "英语", value: 6, color: .orange),
            .init(label: "物理", value: 4, color: .purple)
        ],
        orientation: .horizontal
    )
    .padding()
}

#Preview("分组条形图") {
    DSGroupedBarChart(
        groups: [
            .init(label: "周一", bars: [
                .init(value: 5, color: .green, legend: "已完成"),
                .init(value: 3, color: .orange, legend: "待办")
            ]),
            .init(label: "周二", bars: [
                .init(value: 7, color: .green, legend: "已完成"),
                .init(value: 2, color: .orange, legend: "待办")
            ]),
            .init(label: "周三", bars: [
                .init(value: 4, color: .green, legend: "已完成"),
                .init(value: 4, color: .orange, legend: "待办")
            ])
        ]
    )
    .padding()
}
