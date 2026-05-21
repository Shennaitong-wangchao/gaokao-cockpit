import SwiftUI

struct AppRootView: View {
    @State private var selectedTab: AppTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TodayCockpitView {
                    selectedTab = .tasks
                }
            }
            .tabItem {
                Label("今日", systemImage: "sun.max")
                    .accessibilityLabel("今日标签页")
                    .accessibilityIdentifier("tab.today")
            }
            .tag(AppTab.today)

            NavigationStack {
                TaskListView()
            }
            .tabItem {
                Label("任务", systemImage: "checklist")
                    .accessibilityLabel("任务标签页")
                    .accessibilityIdentifier("tab.tasks")
            }
            .tag(AppTab.tasks)

            NavigationStack {
                MistakeSurgeryView()
            }
            .tabItem {
                Label("错题", systemImage: "cross.case")
                    .accessibilityLabel("错题标签页")
                    .accessibilityIdentifier("tab.mistakes")
            }
            .tag(AppTab.mistakes)

            NavigationStack {
                PromptLibraryView()
            }
            .tabItem {
                Label("Prompt", systemImage: "text.bubble")
                    .accessibilityLabel("Prompt 标签页")
                    .accessibilityIdentifier("tab.prompts")
            }
            .tag(AppTab.prompts)

            NavigationStack {
                ReviewView()
            }
            .tabItem {
                Label("复盘", systemImage: "chart.line.uptrend.xyaxis")
                    .accessibilityLabel("复盘标签页")
                    .accessibilityIdentifier("tab.reviews")
            }
            .tag(AppTab.reviews)
        }
        .accessibilityIdentifier("main.tab.view")
    }
}

private enum AppTab: Hashable {
    case today
    case tasks
    case mistakes
    case prompts
    case reviews
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
