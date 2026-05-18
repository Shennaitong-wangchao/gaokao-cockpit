import SwiftUI

struct PromptLibraryPlaceholderView: View {
    var body: some View {
        ScrollView {
            StagePlaceholderView(
                pageName: "Prompts Prompt",
                futureProblem: "未来用于按学习场景生成 Prompt，并复制到外部 AI 工具中使用。"
            )
            .padding()
        }
        .navigationTitle("Prompt")
    }
}

#Preview {
    NavigationStack {
        PromptLibraryPlaceholderView()
    }
}
