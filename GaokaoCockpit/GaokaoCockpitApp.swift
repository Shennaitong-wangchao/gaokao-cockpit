import SwiftUI
import SwiftData

@main
struct GaokaoCockpitApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            let container = try AppModelContainerFactory.make()
            self.modelContainer = container

            let context = ModelContext(container)
            try PromptTemplateSeeder.seedIfNeeded(in: context)
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(modelContainer)
    }
}
