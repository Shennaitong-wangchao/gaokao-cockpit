import SwiftUI

struct MistakeSurgeryPlaceholderView: View {
    var body: some View {
        ScrollView {
            StagePlaceholderView(
                pageName: "Mistakes 错题",
                futureProblem: "未来用于把错题从收藏变成拆解、复练和模型修正的流程。"
            )
            .padding()
        }
        .navigationTitle("错题")
    }
}

#Preview {
    NavigationStack {
        MistakeSurgeryPlaceholderView()
    }
}
