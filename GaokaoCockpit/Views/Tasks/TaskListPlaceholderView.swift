import SwiftUI

struct TaskListPlaceholderView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                StagePlaceholderView(
                    pageName: "Tasks 任务",
                    futureProblem: "未来用于承接今日计划，把学习目标拆成可开始、可完成、可复盘的任务。"
                )

                NavigationLink {
                    FocusSessionPlaceholderView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "timer")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Focus 专注")
                                .font(.headline)
                            Text("Stage 1 占位入口，暂不实现计时逻辑。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .navigationTitle("任务")
    }
}

#Preview {
    NavigationStack {
        TaskListPlaceholderView()
    }
}
