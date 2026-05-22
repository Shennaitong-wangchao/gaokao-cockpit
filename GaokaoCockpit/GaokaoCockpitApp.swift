import SwiftUI
import SwiftData

@main
struct GaokaoCockpitApp: App {
    private let bootstrap: AppBootstrap

    init() {
        self.bootstrap = Self.makeBootstrap()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(startupWarning: bootstrap.startupWarning)
        }
        .modelContainer(bootstrap.modelContainer)
    }

    private static func makeBootstrap() -> AppBootstrap {
        do {
            let container = try AppModelContainerFactory.make()
            let seedWarning = seedBuiltInTemplates(in: container)
            return AppBootstrap(modelContainer: container, startupWarning: seedWarning)
        } catch {
            do {
                let fallbackContainer = try AppModelContainerFactory.make(inMemory: true)
                return AppBootstrap(
                    modelContainer: fallbackContainer,
                    startupWarning: "本地数据库暂时无法打开，已进入临时模式。本次新增数据不会持久保存：\(error.localizedDescription)"
                )
            } catch {
                fatalError("Failed to initialize fallback SwiftData ModelContainer: \(error)")
            }
        }
    }

    private static func seedBuiltInTemplates(in container: ModelContainer) -> String? {
        do {
            let context = ModelContext(container)
            try PromptTemplateSeeder.seedIfNeeded(in: context)
            return nil
        } catch {
            return "内置 Prompt 模板初始化失败，可继续使用其他功能：\(error.localizedDescription)"
        }
    }
}

private struct AppBootstrap {
    let modelContainer: ModelContainer
    let startupWarning: String?
}
