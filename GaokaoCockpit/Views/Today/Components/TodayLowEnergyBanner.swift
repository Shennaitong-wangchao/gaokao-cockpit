import SwiftUI

struct LowEnergyModeCard: View {
    var body: some View {
        TodayCard(tint: .orange) {
            VStack(alignment: .leading, spacing: 8) {
                Label("今天只保住链条", systemImage: "bolt.heart")
                    .font(.headline)

                Text("先做保底任务，不追求完美。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
