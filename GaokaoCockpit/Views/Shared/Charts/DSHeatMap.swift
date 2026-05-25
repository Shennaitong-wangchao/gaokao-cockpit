import SwiftUI

/// 热力图组件 - 用于展示学习连续性（类似 GitHub Contributions）
struct DSHeatMap: View {
    let data: [DayData]
    var columns: Int = 7 // 一周 7 天
    var cellSize: CGFloat = 12
    var cellSpacing: CGFloat = 3
    var colorScale: [Color] = [
        Color.gray.opacity(0.1),
        Color.green.opacity(0.3),
        Color.green.opacity(0.5),
        Color.green.opacity(0.7),
        Color.green
    ]
    var showMonthLabels: Bool = true
    var showWeekdayLabels: Bool = true
    var isAnimated: Bool = true

    struct DayData: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
        var label: String?
    }

    @State private var animatedProgress: Double = 0

    private var maxValue: Double {
        data.map { $0.value }.max() ?? 1
    }

    private var rows: Int {
        Int(ceil(Double(data.count) / Double(columns)))
    }

    private var weekdayLabels: [String] {
        ["一", "二", "三", "四", "五", "六", "日"]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // 月份标签
            if showMonthLabels {
                monthLabelsView
            }

            HStack(alignment: .top, spacing: cellSpacing) {
                // 星期标签
                if showWeekdayLabels {
                    VStack(spacing: cellSpacing) {
                        ForEach(0..<columns, id: \.self) { index in
                            Text(weekdayLabels[index])
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }

                // 热力图网格
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: Array(repeating: GridItem(.fixed(cellSize), spacing: cellSpacing), count: columns), spacing: cellSpacing) {
                        ForEach(Array(data.enumerated()), id: \.element.id) { index, day in
                            HeatMapCell(
                                value: day.value,
                                maxValue: maxValue,
                                colorScale: colorScale,
                                size: cellSize,
                                date: day.date,
                                label: day.label
                            )
                            .opacity(animatedProgress)
                            .scaleEffect(animatedProgress)
                        }
                    }
                }
            }

            // 图例
            legendView
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

    private var monthLabelsView: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            if showWeekdayLabels {
                Spacer()
                    .frame(width: cellSize)
            }

            // 简化版：显示起始和结束月份
            if let firstDate = data.first?.date, let lastDate = data.last?.date {
                HStack {
                    Text(monthLabel(for: firstDate))
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(monthLabel(for: lastDate))
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var legendView: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Text("少")
                .font(DesignSystem.Typography.caption2)
                .foregroundStyle(.secondary)

            ForEach(0..<colorScale.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(colorScale[index])
                    .frame(width: cellSize, height: cellSize)
            }

            Text("多")
                .font(DesignSystem.Typography.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func monthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = AppDateTime.timeZone
        formatter.dateFormat = "M月"
        return formatter.string(from: date)
    }
}

/// 热力图单元格
struct HeatMapCell: View {
    let value: Double
    let maxValue: Double
    let colorScale: [Color]
    let size: CGFloat
    let date: Date
    let label: String?

    @State private var showTooltip = false

    private var color: Color {
        guard maxValue > 0 else { return colorScale[0] }

        let ratio = value / maxValue
        let index = min(Int(ratio * Double(colorScale.count)), colorScale.count - 1)
        return colorScale[index]
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(color)
            .frame(width: size, height: size)
            .overlay {
                if showTooltip {
                    tooltipView
                }
            }
            .onTapGesture {
                showTooltip.toggle()
            }
    }

    private var tooltipView: some View {
        VStack(spacing: 4) {
            Text(dateLabel)
                .font(DesignSystem.Typography.caption2)
            Text(label ?? "\(Int(value))")
                .font(DesignSystem.Typography.caption2.weight(.semibold))
        }
        .padding(6)
        .background(Color(.systemBackground))
        .cornerRadius(4)
        .shadow(radius: 4)
        .offset(y: -40)
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = AppDateTime.timeZone
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

/// 简化版热力图 - 用于小空间展示
struct DSCompactHeatMap: View {
    let data: [DSHeatMap.DayData]
    var cellSize: CGFloat = 8
    var cellSpacing: CGFloat = 2
    var maxColumns: Int = 30
    var colorScale: [Color] = [
        Color.gray.opacity(0.1),
        Color.green.opacity(0.3),
        Color.green.opacity(0.5),
        Color.green.opacity(0.7),
        Color.green
    ]
    var isAnimated: Bool = true

    @State private var animatedProgress: Double = 0

    private var maxValue: Double {
        data.map { $0.value }.max() ?? 1
    }

    private var recentData: [DSHeatMap.DayData] {
        Array(data.suffix(maxColumns))
    }

    var body: some View {
        HStack(spacing: cellSpacing) {
            ForEach(Array(recentData.enumerated()), id: \.element.id) { index, day in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(color(for: day.value))
                    .frame(width: cellSize, height: cellSize)
                    .opacity(animatedProgress)
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

    private func color(for value: Double) -> Color {
        guard maxValue > 0 else { return colorScale[0] }

        let ratio = value / maxValue
        let index = min(Int(ratio * Double(colorScale.count)), colorScale.count - 1)
        return colorScale[index]
    }
}

#Preview("热力图") {
    let calendar = AppDateTime.calendar
    let today = Date()

    let data = (0..<90).map { dayOffset in
        let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
        let value = Double.random(in: 0...10)
        return DSHeatMap.DayData(date: date, value: value, label: "\(Int(value)) 小时")
    }.reversed()

    return ScrollView {
        VStack(spacing: 20) {
            DSHeatMap(data: Array(data))

            DSCompactHeatMap(data: Array(data))
        }
        .padding()
    }
}
