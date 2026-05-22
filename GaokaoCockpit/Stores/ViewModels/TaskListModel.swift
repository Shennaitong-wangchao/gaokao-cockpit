import SwiftData
import SwiftUI

@Observable
final class TaskListModel {
    var todayKey = DateKey.todayKey()
    var todayDate = Date()
    var dayPlan: DayPlan?
    var tasks: [StudyTask] = []
    var selectedFilter: TaskFilter = .all
    var totalTaskCount = 0
    var completedTaskCount = 0
    var skippedTaskCount = 0
    var isLoading = true
    var statusMessage: String?
    var activeEditor: TaskEditorMode?

    var unfinishedTaskCount: Int {
        max(totalTaskCount - completedTaskCount - skippedTaskCount, 0)
    }

    func loadTodayTasks(in context: ModelContext) {
        isLoading = true
        statusMessage = nil

        do {
            let plan = try DayPlanStore.fetchOrCreateToday(in: context)
            dayPlan = plan
            todayKey = plan.dayKey
            todayDate = plan.date
            try refreshTaskDataThrowing(in: context)
            isLoading = false
        } catch {
            isLoading = false
            statusMessage = "加载任务失败，请重试。"
            HapticFeedback.error()
            ToastManager.shared.show(message: "加载任务失败", style: .error)
        }
    }

    func refreshTaskData(in context: ModelContext) {
        do {
            try refreshTaskDataThrowing(in: context)
        } catch {
            statusMessage = "刷新任务失败，请重试。"
            HapticFeedback.error()
        }
    }

    func updateTaskStatus(in context: ModelContext, task: StudyTask, to status: StudyTaskStatus) {
        guard StudyTaskStatus.from(task.status) != status else {
            return
        }

        do {
            task.status = status.storageValue
            StudyTaskStore.updateTaskTimestamp(task)
            try context.save()
            StudyTaskStore.postDidChange(dayKey: task.dayKey)
            try refreshTaskDataThrowing(in: context)
            statusMessage = "已更新状态：\(status.displayName)。"
            HapticFeedback.lightImpact()
            ToastManager.shared.show(
                message: "已更新状态：\(status.displayName)",
                style: .success
            )
        } catch {
            statusMessage = "更新状态失败，请重试。"
            HapticFeedback.error()
            ToastManager.shared.show(message: "更新状态失败", style: .error)
        }
    }

    func handleTaskStoreDidChange(_ notification: Notification) -> Bool {
        let changedDayKey = notification.userInfo?[StudyTaskStore.dayKeyUserInfoKey] as? String
        return changedDayKey == nil || changedDayKey == todayKey
    }

    private func refreshTaskDataThrowing(in context: ModelContext) throws {
        let fetchedTasks = try StudyTaskStore.fetchTasks(
            for: todayKey,
            status: selectedFilter.status?.storageValue,
            in: context
        )

        tasks = selectedFilter == .unfinished
            ? fetchedTasks.filter(\.isTaskListUnfinished)
            : fetchedTasks
        totalTaskCount = try StudyTaskStore.countTasks(for: todayKey, in: context)
        completedTaskCount = try StudyTaskStore.countCompletedTasks(for: todayKey, in: context)
        skippedTaskCount = try StudyTaskStore.countSkippedTasks(for: todayKey, in: context)
    }
}
