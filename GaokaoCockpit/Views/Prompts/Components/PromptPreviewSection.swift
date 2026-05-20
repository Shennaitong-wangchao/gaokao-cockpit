import SwiftUI

struct PromptPreviewSection: View {
    let generatedPrompt: String

    var body: some View {
        Section("Prompt 预览") {
            Text(generatedPrompt)
                .font(.footnote.monospaced())
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
        }
    }
}
