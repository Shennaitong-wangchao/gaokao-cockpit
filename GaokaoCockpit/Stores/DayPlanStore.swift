import Foundation
import SwiftData

enum DayPlanStore {
    static func fetchDayPlan(for dayKey: String, in context: ModelContext) throws -> DayPlan? {
        var descriptor = FetchDescriptor<DayPlan>(
            predicate: #Predicate<DayPlan> { dayPlan in
                dayPlan.dayKey == dayKey
            },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        descriptor.fetchLimit = 1

        return try context.fetch(descriptor).first
    }

    static func createDayPlan(for date: Date, in context: ModelContext) throws -> DayPlan {
        let now = Date()
        let dayPlan = DayPlan(
            dayKey: DateKey.key(for: date),
            date: DateKey.startOfDay(for: date),
            createdAt: now,
            updatedAt: now
        )

        context.insert(dayPlan)
        try context.save()

        return dayPlan
    }

    static func fetchOrCreateToday(in context: ModelContext) throws -> DayPlan {
        let todayKey = DateKey.todayKey()

        if let dayPlan = try fetchDayPlan(for: todayKey, in: context) {
            return dayPlan
        }

        return try createDayPlan(for: Date(), in: context)
    }

    static func updateDayPlanTimestamp(_ dayPlan: DayPlan) {
        dayPlan.updatedAt = Date()
    }
}
