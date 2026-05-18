import SwiftUI

struct FocusSessionPlaceholderView: View {
    var body: some View {
        ScrollView {
            StagePlaceholderView(
                pageName: "Focus 专注",
                futureProblem: "未来用于绑定学习任务，记录一次专注学习过程和完成质量。",
                note: "请从任务列表选择一个任务开始专注"
            )
            .padding()
        }
        .navigationTitle("专注")
    }
}

#Preview {
    NavigationStack {
        FocusSessionPlaceholderView()
    }
}
