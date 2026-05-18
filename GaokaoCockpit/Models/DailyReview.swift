import Foundation
import SwiftData

@Model
final class DailyReview {
    var id: UUID
    var dayKey: String
    var date: Date
    var completedSummary: String
    var unfinishedSummary: String
    var biggestProblem: String
    var bestMistakeId: UUID?
    var stateScoreEnd: Int?
    var tomorrowFirstAction: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        dayKey: String? = nil,
        date: Date = .now,
        completedSummary: String = "",
        unfinishedSummary: String = "",
        biggestProblem: String = "",
        bestMistakeId: UUID? = nil,
        stateScoreEnd: Int? = nil,
        tomorrowFirstAction: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.dayKey = dayKey ?? DateKey.string(from: date)
        self.date = date
        self.completedSummary = completedSummary
        self.unfinishedSummary = unfinishedSummary
        self.biggestProblem = biggestProblem
        self.bestMistakeId = bestMistakeId
        self.stateScoreEnd = stateScoreEnd
        self.tomorrowFirstAction = tomorrowFirstAction
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
