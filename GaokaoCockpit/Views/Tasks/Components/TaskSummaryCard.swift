import Foundation
import SwiftUI

struct TaskListHeaderView: View {
    let date: Date
    let dayKey: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("学习任务")
                .font(.largeTitle.bold())

            Text(Self.dateFormatter.string(from: date))
                .font(.title3.weight(.semibold))

            Text(dayKey)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = AppDateTime.timeZone
        formatter.dateFormat = "M月d日 EEEE"
        return formatter
    }()
}

struct TaskSummaryCard: View {
    let totalTaskCount: Int
    let completedTaskCount: Int
    let unfinishedTaskCount: Int

    var body: some View {
        TaskListCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("今日任务概览", systemImage: "chart.bar.doc.horizontal")
                    .font(.headline)

                HStack(spacing: 10) {
                    SummaryValue(title: "今日任务", value: totalTaskCount)
                    SummaryValue(title: "已完成", value: completedTaskCount, tint: .green)
                    SummaryValue(title: "未完成", value: unfinishedTaskCount, tint: .orange)
                }
            }
        }
    }
}

struct SummaryValue: View {
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

struct TaskListCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
