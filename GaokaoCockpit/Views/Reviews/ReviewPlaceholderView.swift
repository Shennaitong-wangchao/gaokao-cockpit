import SwiftUI

struct ReviewPlaceholderView: View {
    var body: some View {
        ScrollView {
            StagePlaceholderView(
                pageName: "Reviews 复盘",
                futureProblem: "未来用于每日复盘和周复盘，帮助明天继续推进学习闭环。"
            )
            .padding()
        }
        .navigationTitle("复盘")
    }
}

#Preview {
    NavigationStack {
        ReviewPlaceholderView()
    }
}
