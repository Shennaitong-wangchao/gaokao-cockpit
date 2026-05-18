import SwiftUI

struct AppRootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TodayCockpitView()
            }
            .tabItem {
                Label("今日", systemImage: "sun.max")
            }

            NavigationStack {
                TaskListPlaceholderView()
            }
            .tabItem {
                Label("任务", systemImage: "checklist")
            }

            NavigationStack {
                MistakeSurgeryPlaceholderView()
            }
            .tabItem {
                Label("错题", systemImage: "cross.case")
            }

            NavigationStack {
                PromptLibraryPlaceholderView()
            }
            .tabItem {
                Label("Prompt", systemImage: "text.bubble")
            }

            NavigationStack {
                ReviewPlaceholderView()
            }
            .tabItem {
                Label("复盘", systemImage: "chart.line.uptrend.xyaxis")
            }
        }
    }
}

struct StagePlaceholderView: View {
    let pageName: String
    let futureProblem: String
    let note: String

    init(
        pageName: String,
        futureProblem: String,
        note: String = "Not implemented yet / 尚未实现"
    ) {
        self.pageName = pageName
        self.futureProblem = futureProblem
        self.note = note
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(pageName)
                .font(.title.bold())

            VStack(alignment: .leading, spacing: 8) {
                Label("Stage 1 Project Skeleton", systemImage: "hammer")
                Label(futureProblem, systemImage: "target")
                Label(note, systemImage: "clock")
            }
            .font(.body)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    AppRootView()
}
