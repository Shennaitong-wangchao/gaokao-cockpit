import Foundation
import SwiftData

@Model
final class DayPlan {
    var id: UUID
    var dayKey: String
    var date: Date
    var wakeTime: Date?
    var stateScore: Int?
    var mainSubject: String
    var topTasksText: String
    var baselineTasksText: String
    var bonusTasksText: String
    var tomorrowFirstAction: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        dayKey: String? = nil,
        date: Date = .now,
        wakeTime: Date? = nil,
        stateScore: Int? = nil,
        mainSubject: String = "",
        topTasksText: String = "",
        baselineTasksText: String = "",
        bonusTasksText: String = "",
        tomorrowFirstAction: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.dayKey = dayKey ?? DateKey.string(from: date)
        self.date = date
        self.wakeTime = wakeTime
        self.stateScore = stateScore
        self.mainSubject = mainSubject
        self.topTasksText = topTasksText
        self.baselineTasksText = baselineTasksText
        self.bonusTasksText = bonusTasksText
        self.tomorrowFirstAction = tomorrowFirstAction
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
