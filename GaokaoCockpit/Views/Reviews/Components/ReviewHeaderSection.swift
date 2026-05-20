import SwiftUI

struct ReviewHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("复盘")
                .font(.largeTitle.bold())

            Text("今天收束，明天继续")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
