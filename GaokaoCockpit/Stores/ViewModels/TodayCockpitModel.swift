import SwiftData
import SwiftUI

@Observable
final class TodayCockpitModel {
    var loadState: LoadState = .loading
    var dayPlan: DayPlan?
    var todayKey = DateKey.todayKey()
    var todayDate = Date()

    var stateScore = 7
    var mainSubject = ""
    var topTasksText = ""
    var baselineTasksText = ""
    var bonusTasksText = ""
    var tomorrowFirstAction = ""

    var tasks: [StudyTask] = []
    var totalTaskCount = 0
    var completedTaskCount = 0
    var builtInPromptTemplateCount = 0

    var saveMessage: String?
    var taskMessage: String?
    var planTaskMessage: String?
    var planTaskGenerationResult: PlanTaskGenerationResult?
    var isShowingQuickAddTask = false
    var activePlanTaskGeneration: PlanTaskGenerationState?

    var pendingTaskCount: Int {
        max(totalTaskCount - completedTaskCount, 0)
    }

    var isLowEnergyMode: Bool {
        stateScore <= 4
    }

    func loadToday(context: ModelContext) {
        loadState = .loading
        saveMessage = nil
        taskMessage = nil
        planTaskMessage = nil
        planTaskGenerationResult = nil

        do {
            let plan = try DayPlanStore.fetchOrCreateToday(in: context)
            dayPlan = plan
            todayKey = plan.dayKey
            todayDate = plan.date
            stateScore = plan.stateScore ?? 7
            mainSubject = plan.mainSubject
            topTasksText = plan.topTasksText
            baselineTasksText = plan.baselineTasksText
            bonusTasksText = plan.bonusTasksText

            let reviewTomorrowFirstAction = try DailyReviewStore
                .fetchDailyReview(for: plan.dayKey, in: context)?
                .tomorrowFirstAction
                .trimmingCharacters(in: .whitespacesAndNewlines)
            tomorrowFirstAction = reviewTomorrowFirstAction?.isEmpty == false
                ? reviewTomorrowFirstAction ?? ""
                : plan.tomorrowFirstAction

            try refreshTaskDataThrowing(for: plan.dayKey, in: context)
            loadState = .loaded
        } catch {
            loadState = .failed("无法读取或创建今日 DayPlan：\(error.localizedDescription)")
        }
    }

    func refreshTaskData(for dayKey: String, in context: ModelContext) {
        do {
            try refreshTaskDataThrowing(for: dayKey, in: context)
        } catch {
            taskMessage = "刷新任务失败：\(error.localizedDescription)"
        }
    }

    func saveTodayPlan(in context: ModelContext) {
        guard let plan = dayPlan else {
            saveMessage = "保存失败：今日计划尚未加载。"
            return
        }

        do {
            applyDraftPlanFields(to: plan)
            try context.save()
            saveMessage = "今日计划已保存。"
            HapticFeedback.success()
            ToastManager.shared.show(message: "今日计划已保存", style: .success)
        } catch {
            saveMessage = "保存失败：\(error.localizedDescription)"
            HapticFeedback.error()
            ToastManager.shared.show(message: "保存失败", style: .error)
        }
    }

    func preparePlanTaskGeneration(in context: ModelContext) {
        taskMessage = nil
        planTaskMessage = nil
        planTaskGenerationResult = nil

        let parsedTasks = PlanTaskParser.parsePlanSections(
            top: topTasksText,
            baseline: baselineTasksText,
            bonus: bonusTasksText
        )

        guard !parsedTasks.isEmpty else {
            planTaskMessage = "先在重点 / 保底 / 加分任务里写至少一行计划。"
            HapticFeedback.warning()
            return
        }

        do {
            let existingTitleKeys = Set(
                try StudyTaskStore.fetchTasks(for: todayKey, in: context).map {
                    PlanTaskParser.normalizedTitleKey($0.title)
                }
            )
            let items = parsedTasks.map { parsedTask in
                PlanTaskConfirmationItem(
                    parsedTask: parsedTask,
                    alreadyExists: existingTitleKeys.contains(PlanTaskParser.normalizedTitleKey(parsedTask.title))
                )
            }

            activePlanTaskGeneration = PlanTaskGenerationState(items: items)
        } catch {
            taskMessage = "读取今日任务失败：\(error.localizedDescription)"
            HapticFeedback.error()
        }
    }

    func createTasksFromPlan(in context: ModelContext, parsedTasks: [ParsedPlanTask]) {
        guard let plan = dayPlan else {
            taskMessage = "生成失败：今日计划尚未加载。"
            return
        }

        do {
            applyDraftPlanFields(to: plan)
            let result = try StudyTaskStore.createTasksFromPlan(
                dayPlan: plan,
                parsedTasks: parsedTasks,
                in: context
            )
            try refreshTaskDataThrowing(for: todayKey, in: context)
            saveMessage = "已保存今日计划。"
            planTaskGenerationResult = PlanTaskGenerationResult(created: result.created, skipped: result.skipped)
            planTaskMessage = nil
            taskMessage = nil
            HapticFeedback.success()
            ToastManager.shared.show(
                message: "已生成 \(result.created) 个任务",
                style: .success
            )
        } catch {
            taskMessage = "生成今日任务失败：\(error.localizedDescription)"
            HapticFeedback.error()
            ToastManager.shared.show(message: "生成任务失败", style: .error)
        }
    }

    func toggleTaskStatus(in context: ModelContext, task: StudyTask) {
        let currentStatus = StudyTaskStatus.from(task.status)
        guard currentStatus == .pending || currentStatus == .done else {
            taskMessage = "Today 只支持快速切换待做/完成；更多状态请到任务页处理。"
            HapticFeedback.warning()
            return
        }

        do {
            task.status = currentStatus == .done
                ? StudyTaskStatus.pending.storageValue
                : StudyTaskStatus.done.storageValue
            task.updatedAt = Date()
            try context.save()
            StudyTaskStore.postDidChange(dayKey: task.dayKey)
            try refreshTaskDataThrowing(for: todayKey, in: context)
            let newStatus = StudyTaskStatus.from(task.status)
            taskMessage = newStatus == .done ? "已标记完成。" : "已撤回待做。"
            HapticFeedback.lightImpact()
            ToastManager.shared.show(
                message: newStatus == .done ? "已标记完成" : "已撤回待做",
                style: .success
            )
        } catch {
            taskMessage = "更新任务失败：\(error.localizedDescription)"
            HapticFeedback.error()
            ToastManager.shared.show(message: "更新任务失败", style: .error)
        }
    }

    func handleTaskStoreDidChange(_ notification: Notification) -> Bool {
        let changedDayKey = notification.userInfo?[StudyTaskStore.dayKeyUserInfoKey] as? String
        return changedDayKey == nil || changedDayKey == todayKey
    }

    private func refreshTaskDataThrowing(for dayKey: String, in context: ModelContext) throws {
        tasks = try StudyTaskStore.fetchTasks(for: dayKey, in: context)
        totalTaskCount = try StudyTaskStore.countTasks(for: dayKey, in: context)
        completedTaskCount = try StudyTaskStore.countCompletedTasks(for: dayKey, in: context)
        builtInPromptTemplateCount = try PromptTemplateStore.countBuiltInTemplates(in: context)
    }

    private func applyDraftPlanFields(to plan: DayPlan) {
        plan.stateScore = stateScore
        plan.mainSubject = mainSubject.trimmingCharacters(in: .whitespacesAndNewlines)
        plan.topTasksText = topTasksText
        plan.baselineTasksText = baselineTasksText
        plan.bonusTasksText = bonusTasksText
        plan.tomorrowFirstAction = tomorrowFirstAction.trimmingCharacters(in: .whitespacesAndNewlines)
        DayPlanStore.updateDayPlanTimestamp(plan)
    }
}
