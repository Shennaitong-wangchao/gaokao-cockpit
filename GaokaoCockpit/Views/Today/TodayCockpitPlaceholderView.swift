import SwiftUI

struct TodayCockpitPlaceholderView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("高考驾驶舱")
                        .font(.largeTitle.bold())

                    Text("每天启动、专注、错题、复盘")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("当前阶段：Stage 2A Local SwiftData Persistence", systemImage: "externaldrive.connected.to.line.below")
                    Label("下一阶段：Stage 2B / Stage 3 将替换 Debug 区为正式今日驾驶舱", systemImage: "arrow.right.circle")
                }
                .font(.body)
                .foregroundStyle(.secondary)

                StagePlaceholderView(
                    pageName: "Today 今日",
                    futureProblem: "未来用于每天启动学习闭环，确认今日状态、主攻方向和下一步。"
                )

                Stage2DebugPersistenceView()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("今日")
    }
}

#Preview {
    NavigationStack {
        TodayCockpitPlaceholderView()
    }
    .modelContainer(try! AppModelContainerFactory.make(inMemory: true))
}
