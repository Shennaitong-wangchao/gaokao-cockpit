import Foundation
import SwiftData

enum DailyReviewStore {
    static func fetchDailyReview(for dayKey: String, in context: ModelContext) throws -> DailyReview? {
        var descriptor = FetchDescriptor<DailyReview>(
            predicate: #Predicate<DailyReview> { review in
                review.dayKey == dayKey
            },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        descriptor.fetchLimit = 1

        return try context.fetch(descriptor).first
    }

    static func createDailyReview(for date: Date, in context: ModelContext) throws -> DailyReview {
        let now = Date()
        let review = DailyReview(
            dayKey: DateKey.key(for: date),
            date: DateKey.startOfDay(for: date),
            createdAt: now,
            updatedAt: now
        )

        context.insert(review)
        try context.save()

        return review
    }

    static func fetchOrCreateTodayReview(in context: ModelContext) throws -> DailyReview {
        let todayKey = DateKey.todayKey()

        if let review = try fetchDailyReview(for: todayKey, in: context) {
            return review
        }

        return try createDailyReview(for: Date(), in: context)
    }

    static func updateDailyReviewTimestamp(_ review: DailyReview) {
        review.updatedAt = Date()
    }

    static func countReviews(in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<DailyReview>()
        return try context.fetchCount(descriptor)
    }
}
