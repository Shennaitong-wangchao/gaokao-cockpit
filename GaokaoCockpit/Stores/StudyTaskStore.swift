import Foundation
import SwiftData

enum StudyTaskStore {
    static func fetchTasks(for dayKey: String, in context: ModelContext) throws -> [StudyTask] {
        let descriptor = FetchDescriptor<StudyTask>(
            predicate: #Predicate<StudyTask> { task in
                task.dayKey == dayKey
            },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        return try context.fetch(descriptor)
    }

    static func fetchTasks(for dayKey: String, status: String?, in context: ModelContext) throws -> [StudyTask] {
        guard let status else {
            return try fetchTasks(for: dayKey, in: context)
        }

        let selectedStatus = status
        let descriptor = FetchDescriptor<StudyTask>(
            predicate: #Predicate<StudyTask> { task in
                task.dayKey == dayKey && task.status == selectedStatus
            },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        return try context.fetch(descriptor)
    }

    static func createTask(
        dayKey: String,
        title: String,
        subject: String,
        category: String,
        estimatedMinutes: Int?,
        actualMinutes: Int? = nil,
        status: String = ModelDefaults.StudyTaskStatus.pending,
        outputNote: String = "",
        dayPlanId: UUID? = nil,
        in context: ModelContext
    ) throws -> StudyTask {
        let now = Date()
        let task = StudyTask(
            dayPlanId: dayPlanId,
            dayKey: dayKey,
            title: title,
            subject: subject,
            category: category,
            estimatedMinutes: estimatedMinutes,
            actualMinutes: actualMinutes,
            status: status,
            outputNote: outputNote,
            createdAt: now,
            updatedAt: now
        )

        context.insert(task)
        try context.save()

        return task
    }

    static func countTasks(for dayKey: String, in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<StudyTask>(
            predicate: #Predicate<StudyTask> { task in
                task.dayKey == dayKey
            }
        )

        return try context.fetchCount(descriptor)
    }

    static func countCompletedTasks(for dayKey: String, in context: ModelContext) throws -> Int {
        let completedStatus = ModelDefaults.StudyTaskStatus.done
        let descriptor = FetchDescriptor<StudyTask>(
            predicate: #Predicate<StudyTask> { task in
                task.dayKey == dayKey && task.status == completedStatus
            }
        )

        return try context.fetchCount(descriptor)
    }

    static func countSkippedTasks(for dayKey: String, in context: ModelContext) throws -> Int {
        let skippedStatus = ModelDefaults.StudyTaskStatus.skipped
        let descriptor = FetchDescriptor<StudyTask>(
            predicate: #Predicate<StudyTask> { task in
                task.dayKey == dayKey && task.status == skippedStatus
            }
        )

        return try context.fetchCount(descriptor)
    }

    static func updateTaskTimestamp(_ task: StudyTask) {
        task.updatedAt = Date()
    }

    static func deleteTask(_ task: StudyTask, in context: ModelContext) throws {
        context.delete(task)
        try context.save()
    }
}
