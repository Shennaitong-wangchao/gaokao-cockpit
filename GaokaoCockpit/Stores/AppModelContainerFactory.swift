import SwiftData

enum AppModelContainerFactory {
    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            DayPlan.self,
            StudyTask.self,
            FocusSession.self,
            MistakeRecord.self,
            PromptTemplate.self,
            ResourceItem.self,
            DailyReview.self,
            WeeklyReview.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
