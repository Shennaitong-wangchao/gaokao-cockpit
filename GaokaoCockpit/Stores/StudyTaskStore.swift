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

    static func createTask(
        dayKey: String,
        title: String,
        subject: String,
        category: String,
        estimatedMinutes: Int?,
        in context: ModelContext
    ) throws -> StudyTask {
        let now = Date()
        let task = StudyTask(
            dayKey: dayKey,
            title: title,
            subject: subject,
            category: category,
            estimatedMinutes: estimatedMinutes,
            status: ModelDefaults.StudyTaskStatus.pending,
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
}
