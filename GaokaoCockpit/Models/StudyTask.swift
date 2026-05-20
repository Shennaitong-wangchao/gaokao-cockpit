import Foundation
import SwiftData

@Model
final class StudyTask {
    var id: UUID
    var dayPlanId: UUID?
    var dayKey: String
    var title: String
    var subject: String
    var category: String
    var estimatedMinutes: Int?
    var actualMinutes: Int?
    var status: String
    var outputNote: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        dayPlanId: UUID? = nil,
        dayKey: String = DateKey.today(),
        title: String = "",
        subject: String = "",
        category: String = "",
        estimatedMinutes: Int? = nil,
        actualMinutes: Int? = nil,
        status: String = StudyTaskStatus.pending.storageValue,
        outputNote: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.dayPlanId = dayPlanId
        self.dayKey = dayKey
        self.title = title
        self.subject = subject
        self.category = category
        self.estimatedMinutes = estimatedMinutes
        self.actualMinutes = actualMinutes
        self.status = status
        self.outputNote = outputNote
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
