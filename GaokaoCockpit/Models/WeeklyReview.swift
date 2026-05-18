import Foundation
import SwiftData

@Model
final class WeeklyReview {
    var id: UUID
    var weekStartKey: String
    var weekEndKey: String
    var weekStartDate: Date
    var weekEndDate: Date
    var totalStudyMinutes: Int
    var subjectBreakdownText: String
    var completedTaskCount: Int
    var mistakeCount: Int
    var mistakeTypeBreakdownText: String
    var keyProblemsText: String
    var nextWeekFocusText: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        weekStartKey: String? = nil,
        weekEndKey: String? = nil,
        weekStartDate: Date = .now,
        weekEndDate: Date = .now,
        totalStudyMinutes: Int = 0,
        subjectBreakdownText: String = "",
        completedTaskCount: Int = 0,
        mistakeCount: Int = 0,
        mistakeTypeBreakdownText: String = "",
        keyProblemsText: String = "",
        nextWeekFocusText: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.weekStartKey = weekStartKey ?? DateKey.string(from: weekStartDate)
        self.weekEndKey = weekEndKey ?? DateKey.string(from: weekEndDate)
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.totalStudyMinutes = totalStudyMinutes
        self.subjectBreakdownText = subjectBreakdownText
        self.completedTaskCount = completedTaskCount
        self.mistakeCount = mistakeCount
        self.mistakeTypeBreakdownText = mistakeTypeBreakdownText
        self.keyProblemsText = keyProblemsText
        self.nextWeekFocusText = nextWeekFocusText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
