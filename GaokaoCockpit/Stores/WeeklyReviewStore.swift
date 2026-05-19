import Foundation
import SwiftData

enum WeeklyReviewStore {
    static func fetchWeeklyReview(weekStartKey: String, in context: ModelContext) throws -> WeeklyReview? {
        var descriptor = FetchDescriptor<WeeklyReview>(
            predicate: #Predicate<WeeklyReview> { review in
                review.weekStartKey == weekStartKey
            },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        descriptor.fetchLimit = 1

        return try context.fetch(descriptor).first
    }

    static func createWeeklyReview(
        weekStartDate: Date,
        weekEndDate: Date,
        in context: ModelContext
    ) throws -> WeeklyReview {
        let now = Date()
        let review = WeeklyReview(
            weekStartKey: DateKey.key(for: weekStartDate),
            weekEndKey: DateKey.key(for: weekEndDate),
            weekStartDate: DateKey.startOfDay(for: weekStartDate),
            weekEndDate: weekEndDate,
            createdAt: now,
            updatedAt: now
        )

        context.insert(review)
        try context.save()

        return review
    }

    static func fetchOrCreateCurrentWeekReview(in context: ModelContext) throws -> WeeklyReview {
        let range = DateKey.weekKeyRange(for: Date())

        if let review = try fetchWeeklyReview(weekStartKey: range.lowerBound, in: context) {
            return review
        }

        return try createWeeklyReview(
            weekStartDate: DateKey.weekStart(for: Date()),
            weekEndDate: DateKey.weekEnd(for: Date()),
            in: context
        )
    }

    static func updateWeeklyReviewTimestamp(_ review: WeeklyReview) {
        review.updatedAt = Date()
    }

    static func countReviews(in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<WeeklyReview>()
        return try context.fetchCount(descriptor)
    }
}
