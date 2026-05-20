import SwiftUI

struct MistakeSurgeryHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("错题手术")
                .font(.largeTitle.bold())

            Text("不是收藏错题，是拆出下次能赢的机制")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct MistakeSummaryCard: View {
    let totalMistakeCount: Int
    let scheduledCount: Int
    let reviewedCount: Int
    let masteredCount: Int

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        MistakeSurgeryCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("错题手术概览", systemImage: "chart.bar.doc.horizontal")
                    .font(.headline)

                LazyVGrid(columns: columns, spacing: 10) {
                    MistakeSummaryValue(title: "总错题", value: totalMistakeCount)
                    MistakeSummaryValue(title: "待复习", value: scheduledCount, tint: .blue)
                    MistakeSummaryValue(title: "已复习", value: reviewedCount, tint: .green)
                    MistakeSummaryValue(title: "已掌握", value: masteredCount, tint: .purple)
                }
            }
        }
    }
}

struct MistakeSummaryValue: View {
    let title: String
    let value: Int
    var tint: Color = .primary

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
