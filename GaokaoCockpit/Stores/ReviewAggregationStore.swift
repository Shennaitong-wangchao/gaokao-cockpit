import Foundation
import SwiftData

enum ReviewAggregationStore {
    static func todayTaskCount(dayKey: String, in context: ModelContext) throws -> Int {
        try StudyTaskStore.countTasks(for: dayKey, in: context)
    }

    static func todayCompletedTaskCount(dayKey: String, in context: ModelContext) throws -> Int {
        try StudyTaskStore.countCompletedTasks(for: dayKey, in: context)
    }

    static func todayFocusMinutes(dayKey: String, in context: ModelContext) throws -> Int {
        try FocusSessionStore.totalActualMinutes(for: dayKey, in: context)
    }

    static func todayFocusSessionCount(dayKey: String, in context: ModelContext) throws -> Int {
        try FocusSessionStore.countSessions(for: dayKey, in: context)
    }

    static func todayMistakeCount(dayKey: String, in context: ModelContext) throws -> Int {
        let mistakes = try fetchMistakes(in: context)
        return mistakes.filter { DateKey.key(for: $0.createdAt) == dayKey }.count
    }

    static func weekFocusMinutes(start: Date, end: Date, in context: ModelContext) throws -> Int {
        let sessions = try fetchFocusSessions(start: start, end: end, in: context)
        return sessions.reduce(0) { total, session in
            total + (session.actualMinutes ?? 0)
        }
    }

    static func weekCompletedTaskCount(start: Date, end: Date, in context: ModelContext) throws -> Int {
        let doneStatus = StudyTaskStatus.done.storageValue
        let tasks = try fetchTasks(start: start, end: end, in: context)
        return tasks.filter { $0.status == doneStatus }.count
    }

    static func weekMistakeCount(start: Date, end: Date, in context: ModelContext) throws -> Int {
        try fetchMistakes(start: start, end: end, in: context).count
    }

    static func weekMistakeTypeBreakdownText(start: Date, end: Date, in context: ModelContext) throws -> String {
        let mistakes = try fetchMistakes(start: start, end: end, in: context)
        let counts = mistakes.reduce(into: [String: Int]()) { result, mistake in
            let type = normalizedMistakeTypeLabel(mistake.mistakeType)
            result[type, default: 0] += 1
        }

        return formatCountBreakdown(counts, emptyText: "暂无错题类型记录")
    }

    static func weekSubjectBreakdownText(start: Date, end: Date, in context: ModelContext) throws -> String {
        let focusSessions = try fetchFocusSessions(start: start, end: end, in: context)
        let focusMinutes = focusSessions.reduce(into: [String: Int]()) { result, session in
            let minutes = session.actualMinutes ?? 0
            guard minutes > 0 else {
                return
            }

            let subject = normalizedSubjectLabel(session.subject, fallback: "未设科目")
            result[subject, default: 0] += minutes
        }

        if focusMinutes.values.reduce(0, +) > 0 {
            return formatMinuteBreakdown(focusMinutes, emptyText: "暂无科目专注记录")
        }

        let tasks = try fetchTasks(start: start, end: end, in: context)
        let taskMinutes = tasks.reduce(into: [String: Int]()) { result, task in
            let minutes = task.actualMinutes ?? task.estimatedMinutes ?? 0
            guard minutes > 0 else {
                return
            }

            let subject = normalizedSubjectLabel(task.subject, fallback: "未设科目")
            result[subject, default: 0] += minutes
        }

        if taskMinutes.values.reduce(0, +) > 0 {
            return formatMinuteBreakdown(taskMinutes, emptyText: "暂无科目任务记录")
        }

        let taskCounts = tasks.reduce(into: [String: Int]()) { result, task in
            let subject = normalizedSubjectLabel(task.subject, fallback: "未设科目")
            result[subject, default: 0] += 1
        }

        return formatCountBreakdown(taskCounts, unit: "个任务", emptyText: "暂无科目记录")
    }

    private static func fetchFocusSessions(start: Date, end: Date, in context: ModelContext) throws -> [FocusSession] {
        let descriptor = FetchDescriptor<FocusSession>(
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )

        return try context.fetch(descriptor).filter { session in
            session.startTime >= start && session.startTime <= end
        }
    }

    private static func fetchTasks(start: Date, end: Date, in context: ModelContext) throws -> [StudyTask] {
        let startKey = DateKey.key(for: start)
        let endKey = DateKey.key(for: end)
        let descriptor = FetchDescriptor<StudyTask>(
            sortBy: [SortDescriptor(\.dayKey, order: .forward)]
        )

        return try context.fetch(descriptor).filter { task in
            task.dayKey >= startKey && task.dayKey <= endKey
        }
    }

    private static func fetchMistakes(start: Date, end: Date, in context: ModelContext) throws -> [MistakeRecord] {
        let descriptor = FetchDescriptor<MistakeRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        return try context.fetch(descriptor).filter { mistake in
            mistake.createdAt >= start && mistake.createdAt <= end
        }
    }

    private static func fetchMistakes(in context: ModelContext) throws -> [MistakeRecord] {
        let descriptor = FetchDescriptor<MistakeRecord>()
        return try context.fetch(descriptor)
    }

    private static func normalizedLabel(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    private static func normalizedSubjectLabel(_ value: String, fallback: String) -> String {
        let trimmed = normalizedLabel(value, fallback: "")
        return trimmed.isEmpty ? fallback : LearningSubject.from(trimmed).displayName
    }

    private static func normalizedMistakeTypeLabel(_ value: String) -> String {
        let trimmed = normalizedLabel(value, fallback: "")
        return trimmed.isEmpty ? "未分类" : MistakeType.from(trimmed).displayName
    }

    private static func formatMinuteBreakdown(_ values: [String: Int], emptyText: String) -> String {
        guard !values.isEmpty else {
            return emptyText
        }

        return values
            .sorted { lhs, rhs in
                lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
            }
            .map { "\($0.key)：\($0.value) 分钟" }
            .joined(separator: "\n")
    }

    private static func formatCountBreakdown(
        _ values: [String: Int],
        unit: String = "",
        emptyText: String
    ) -> String {
        guard !values.isEmpty else {
            return emptyText
        }

        return values
            .sorted { lhs, rhs in
                lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
            }
            .map { "\($0.key)：\($0.value)\(unit)" }
            .joined(separator: "\n")
    }
}
