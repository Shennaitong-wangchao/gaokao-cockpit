import Foundation
import SwiftData

@Model
final class FocusSession {
    var id: UUID
    var taskId: UUID?
    var dayKey: String
    var subject: String
    var startTime: Date
    var endTime: Date?
    var plannedMinutes: Int
    var actualMinutes: Int?
    var distractionCount: Int
    var completionScore: Int?
    var sessionNote: String
    var nextAction: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        taskId: UUID? = nil,
        dayKey: String? = nil,
        subject: String = "",
        startTime: Date = .now,
        endTime: Date? = nil,
        plannedMinutes: Int = 25,
        actualMinutes: Int? = nil,
        distractionCount: Int = 0,
        completionScore: Int? = nil,
        sessionNote: String = "",
        nextAction: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.taskId = taskId
        self.dayKey = dayKey ?? DateKey.string(from: startTime)
        self.subject = subject
        self.startTime = startTime
        self.endTime = endTime
        self.plannedMinutes = plannedMinutes
        self.actualMinutes = actualMinutes
        self.distractionCount = distractionCount
        self.completionScore = completionScore
        self.sessionNote = sessionNote
        self.nextAction = nextAction
        self.createdAt = createdAt
    }
}
