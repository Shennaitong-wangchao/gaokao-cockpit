import Foundation
import SwiftData

enum MistakeRecordStore {
    static func fetchMistakes(in context: ModelContext) throws -> [MistakeRecord] {
        let descriptor = FetchDescriptor<MistakeRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        return try context.fetch(descriptor)
    }

    static func fetchMistakes(
        subject: String?,
        reviewStatus: String?,
        in context: ModelContext
    ) throws -> [MistakeRecord] {
        let cleanSubject = normalizedFilter(subject)
        let cleanStatus = normalizedFilter(reviewStatus)

        switch (cleanSubject, cleanStatus) {
        case let (subject?, status?):
            let selectedSubject = subject
            let selectedStatus = status
            let descriptor = FetchDescriptor<MistakeRecord>(
                predicate: #Predicate<MistakeRecord> { mistake in
                    mistake.subject == selectedSubject && mistake.reviewStatus == selectedStatus
                },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try context.fetch(descriptor)

        case let (subject?, nil):
            let selectedSubject = subject
            let descriptor = FetchDescriptor<MistakeRecord>(
                predicate: #Predicate<MistakeRecord> { mistake in
                    mistake.subject == selectedSubject
                },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try context.fetch(descriptor)

        case let (nil, status?):
            let selectedStatus = status
            let descriptor = FetchDescriptor<MistakeRecord>(
                predicate: #Predicate<MistakeRecord> { mistake in
                    mistake.reviewStatus == selectedStatus
                },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try context.fetch(descriptor)

        case (nil, nil):
            return try fetchMistakes(in: context)
        }
    }

    static func createMistake(
        subject: String,
        chapter: String,
        source: String,
        questionText: String,
        questionImagePath: String,
        mySolution: String,
        correctSolution: String,
        mistakeType: String,
        rootCause: String,
        questionSignal: String,
        correctModel: String,
        variantTask: String,
        nextReminder: Date?,
        reviewStatus: String,
        in context: ModelContext
    ) throws -> MistakeRecord {
        let now = Date()
        let mistake = MistakeRecord(
            subject: subject,
            chapter: chapter,
            source: source,
            questionText: questionText,
            questionImagePath: questionImagePath,
            mySolution: mySolution,
            correctSolution: correctSolution,
            mistakeType: mistakeType,
            rootCause: rootCause,
            questionSignal: questionSignal,
            correctModel: correctModel,
            variantTask: variantTask,
            nextReminder: nextReminder,
            reviewStatus: reviewStatus,
            createdAt: now,
            updatedAt: now
        )

        context.insert(mistake)
        try context.save()

        return mistake
    }

    static func updateMistakeTimestamp(_ mistake: MistakeRecord) {
        mistake.updatedAt = Date()
    }

    static func deleteMistake(_ mistake: MistakeRecord, in context: ModelContext) throws {
        context.delete(mistake)
        try context.save()
    }

    static func countMistakes(in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<MistakeRecord>()
        return try context.fetchCount(descriptor)
    }

    static func countMistakes(reviewStatus: String, in context: ModelContext) throws -> Int {
        let selectedStatus = reviewStatus
        let descriptor = FetchDescriptor<MistakeRecord>(
            predicate: #Predicate<MistakeRecord> { mistake in
                mistake.reviewStatus == selectedStatus
            }
        )

        return try context.fetchCount(descriptor)
    }

    static func countMistakes(subject: String, in context: ModelContext) throws -> Int {
        let selectedSubject = subject
        let descriptor = FetchDescriptor<MistakeRecord>(
            predicate: #Predicate<MistakeRecord> { mistake in
                mistake.subject == selectedSubject
            }
        )

        return try context.fetchCount(descriptor)
    }

    private static func normalizedFilter(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
