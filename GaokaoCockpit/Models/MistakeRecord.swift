import Foundation
import SwiftData

@Model
final class MistakeRecord {
    var id: UUID
    var subject: String
    var chapter: String
    var source: String
    var questionText: String
    var questionImagePath: String
    var mySolution: String
    var correctSolution: String
    var mistakeType: String
    var rootCause: String
    var questionSignal: String
    var correctModel: String
    var variantTask: String
    var nextReminder: Date?
    var reviewStatus: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        subject: String = "",
        chapter: String = "",
        source: String = "",
        questionText: String = "",
        questionImagePath: String = "",
        mySolution: String = "",
        correctSolution: String = "",
        mistakeType: String = MistakeType.concept.storageValue,
        rootCause: String = "",
        questionSignal: String = "",
        correctModel: String = "",
        variantTask: String = "",
        nextReminder: Date? = nil,
        reviewStatus: String = ReviewStatus.new.storageValue,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.subject = subject
        self.chapter = chapter
        self.source = source
        self.questionText = questionText
        self.questionImagePath = questionImagePath
        self.mySolution = mySolution
        self.correctSolution = correctSolution
        self.mistakeType = mistakeType
        self.rootCause = rootCause
        self.questionSignal = questionSignal
        self.correctModel = correctModel
        self.variantTask = variantTask
        self.nextReminder = nextReminder
        self.reviewStatus = reviewStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
