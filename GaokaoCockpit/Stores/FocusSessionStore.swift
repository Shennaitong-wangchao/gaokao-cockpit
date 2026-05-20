import Foundation
import SwiftData

enum FocusSessionStore {
    static func fetchSessions(for dayKey: String, in context: ModelContext) throws -> [FocusSession] {
        let selectedDayKey = dayKey
        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate<FocusSession> { session in
                session.dayKey == selectedDayKey
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        return try context.fetch(descriptor)
    }

    static func fetchSessions(taskId: UUID, in context: ModelContext) throws -> [FocusSession] {
        let selectedTaskId = taskId
        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate<FocusSession> { session in
                session.taskId == selectedTaskId
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        return try context.fetch(descriptor)
    }

    static func startSession(
        for task: StudyTask,
        plannedMinutes: Int,
        in context: ModelContext
    ) throws -> FocusSession {
        let now = Date()
        let session = FocusSession(
            taskId: task.id,
            dayKey: task.dayKey,
            subject: task.subject,
            startTime: now,
            plannedMinutes: plannedMinutes,
            distractionCount: 0,
            createdAt: now
        )

        task.status = StudyTaskStatus.inProgress.storageValue
        task.updatedAt = now

        context.insert(session)
        try context.save()

        return session
    }

    static func finishSession(
        _ session: FocusSession,
        actualMinutes: Int,
        distractionCount: Int,
        completionScore: Int?,
        sessionNote: String,
        nextAction: String,
        in context: ModelContext
    ) throws {
        session.endTime = Date()
        session.actualMinutes = actualMinutes
        session.distractionCount = distractionCount
        session.completionScore = completionScore
        session.sessionNote = sessionNote
        session.nextAction = nextAction

        try context.save()
    }

    static func totalActualMinutes(for dayKey: String, in context: ModelContext) throws -> Int {
        let sessions = try fetchSessions(for: dayKey, in: context)
        return sessions.reduce(0) { total, session in
            total + (session.actualMinutes ?? 0)
        }
    }

    static func countSessions(for dayKey: String, in context: ModelContext) throws -> Int {
        let selectedDayKey = dayKey
        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate<FocusSession> { session in
                session.dayKey == selectedDayKey
            }
        )

        return try context.fetchCount(descriptor)
    }
}
