import Foundation
import SwiftData

enum StudyTaskStore {
    static let didChangeNotification = Notification.Name("StudyTaskStore.didChangeNotification")
    static let dayKeyUserInfoKey = "dayKey"

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

        let selectedStatus = StudyTaskStatus.from(status).storageValue
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
        status: String = StudyTaskStatus.pending.storageValue,
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
        postDidChange(dayKey: dayKey)

        return task
    }

    static func createTask(
        dayKey: String,
        title: String,
        subject: String,
        category: StudyTaskCategory,
        estimatedMinutes: Int?,
        actualMinutes: Int? = nil,
        status: StudyTaskStatus = .pending,
        outputNote: String = "",
        dayPlanId: UUID? = nil,
        in context: ModelContext
    ) throws -> StudyTask {
        try createTask(
            dayKey: dayKey,
            title: title,
            subject: subject,
            category: category.storageValue,
            estimatedMinutes: estimatedMinutes,
            actualMinutes: actualMinutes,
            status: status.storageValue,
            outputNote: outputNote,
            dayPlanId: dayPlanId,
            in: context
        )
    }

    static func createTasksFromPlan(
        dayPlan: DayPlan,
        parsedTasks: [ParsedPlanTask],
        in context: ModelContext
    ) throws -> (created: Int, skipped: Int) {
        var existingTitleKeys = Set(
            try fetchTasks(for: dayPlan.dayKey, in: context).map {
                PlanTaskParser.normalizedTitleKey($0.title)
            }
        )
        var createdCount = 0
        var skippedCount = 0
        let subject = dayPlan.mainSubject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? LearningSubject.other.storageValue
            : LearningSubject.from(dayPlan.mainSubject).storageValue

        for parsedTask in parsedTasks {
            let titleKey = PlanTaskParser.normalizedTitleKey(parsedTask.title)
            guard !existingTitleKeys.contains(titleKey) else {
                skippedCount += 1
                continue
            }

            let now = Date()
            let task = StudyTask(
                dayPlanId: dayPlan.id,
                dayKey: dayPlan.dayKey,
                title: parsedTask.title,
                subject: subject,
                category: StudyTaskCategory.from(parsedTask.category).storageValue,
                estimatedMinutes: 25,
                status: StudyTaskStatus.pending.storageValue,
                outputNote: "From Today \(parsedTask.source) plan",
                createdAt: now,
                updatedAt: now
            )

            context.insert(task)
            existingTitleKeys.insert(titleKey)
            createdCount += 1
        }

        try context.save()
        postDidChange(dayKey: dayPlan.dayKey)
        return (created: createdCount, skipped: skippedCount)
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
        let completedStatus = StudyTaskStatus.done.storageValue
        let descriptor = FetchDescriptor<StudyTask>(
            predicate: #Predicate<StudyTask> { task in
                task.dayKey == dayKey && task.status == completedStatus
            }
        )

        return try context.fetchCount(descriptor)
    }

    static func countSkippedTasks(for dayKey: String, in context: ModelContext) throws -> Int {
        let skippedStatus = StudyTaskStatus.skipped.storageValue
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
        let dayKey = task.dayKey
        context.delete(task)
        try context.save()
        postDidChange(dayKey: dayKey)
    }

    static func postDidChange(dayKey: String) {
        NotificationCenter.default.post(
            name: didChangeNotification,
            object: nil,
            userInfo: [dayKeyUserInfoKey: dayKey]
        )
    }
}
