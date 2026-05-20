import SwiftData
import SwiftUI

struct TodayCockpitView: View {
    @Environment(\.modelContext) private var modelContext

    private let onViewTasks: (() -> Void)?

    @State private var loadState: LoadState = .loading
    @State private var dayPlan: DayPlan?
    @State private var todayKey = DateKey.todayKey()
    @State private var todayDate = Date()

    @State private var stateScore = 7
    @State private var mainSubject = ""
    @State private var topTasksText = ""
    @State private var baselineTasksText = ""
    @State private var bonusTasksText = ""
    @State private var tomorrowFirstAction = ""

    @State private var tasks: [StudyTask] = []
    @State private var totalTaskCount = 0
    @State private var completedTaskCount = 0
    @State private var builtInPromptTemplateCount = 0

    @State private var saveMessage: String?
    @State private var taskMessage: String?
    @State private var planTaskGenerationResult: PlanTaskGenerationResult?
    @State private var isShowingQuickAddTask = false
    @State private var activePlanTaskGeneration: PlanTaskGenerationState?

    init(onViewTasks: (() -> Void)? = nil) {
        self.onViewTasks = onViewTasks
    }

    private var pendingTaskCount: Int {
        max(totalTaskCount - completedTaskCount, 0)
    }

    private var isLowEnergyMode: Bool {
        stateScore <= 4
    }

    var body: some View {
        Group {
            switch loadState {
            case .loading:
                ProgressView("正在加载今日驾驶舱")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .failed(let message):
                ContentUnavailableView {
                    Label("今日驾驶舱加载失败", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("重新加载") {
                        loadToday()
                    }
                    .buttonStyle(.borderedProminent)
                }

            case .loaded:
                if dayPlan == nil {
                    ContentUnavailableView {
                        Label("今日计划为空", systemImage: "calendar.badge.exclamationmark")
                    } description: {
                        Text("没有找到今日 DayPlan。")
                    } actions: {
                        Button("创建今日计划") {
                            loadToday()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            TodayHeaderView(date: todayDate, dayKey: todayKey)

                            TodayStartupCard(
                                stateScore: $stateScore,
                                mainSubject: $mainSubject
                            )

                            if isLowEnergyMode {
                                LowEnergyModeCard()
                            }

                            TodayPlanTextCard(
                                topTasksText: $topTasksText,
                                baselineTasksText: $baselineTasksText,
                                bonusTasksText: $bonusTasksText,
                                isLowEnergyMode: isLowEnergyMode
                            )

                            PlanToTaskActionCard(
                                onGenerate: preparePlanTaskGeneration
                            )

                            TodayTaskSummaryCard(
                                totalTaskCount: totalTaskCount,
                                completedTaskCount: completedTaskCount,
                                pendingTaskCount: pendingTaskCount,
                                builtInPromptTemplateCount: builtInPromptTemplateCount
                            )

                            TodayTaskListCard(
                                tasks: tasks,
                                taskMessage: taskMessage,
                                planTaskGenerationResult: planTaskGenerationResult,
                                onToggleStatus: toggleTaskStatus,
                                onQuickAdd: {
                                    isShowingQuickAddTask = true
                                },
                                onViewTasks: viewGeneratedTasks
                            )

                            TomorrowFirstActionCard(text: $tomorrowFirstAction)

                            SavePlanCard(
                                saveMessage: saveMessage,
                                onSave: saveTodayPlan
                            )

                            #if DEBUG
                            DeveloperDiagnosticsDisclosureCard()
                            #endif
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .refreshable {
                        refreshTaskData()
                    }
                }
            }
        }
        .navigationTitle("今日")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadToday()
        }
        .onAppear {
            if loadState == .loaded {
                refreshTaskData()
            }
        }
        .sheet(isPresented: $isShowingQuickAddTask) {
            TodayQuickAddTaskSheet(
                dayKey: todayKey,
                dayPlanID: dayPlan?.id,
                defaultSubject: mainSubject.trimmingCharacters(in: .whitespacesAndNewlines)
            ) {
                refreshTaskData()
                planTaskGenerationResult = nil
                taskMessage = "已新增今日任务。"
            }
        }
        .sheet(item: $activePlanTaskGeneration) { generation in
            PlanTaskGenerationSheet(generation: generation) {
                createTasksFromPlan(generation.parsedTasks)
            }
        }
    }

    private func loadToday() {
        loadState = .loading
        saveMessage = nil
        taskMessage = nil
        planTaskGenerationResult = nil

        do {
            let plan = try DayPlanStore.fetchOrCreateToday(in: modelContext)
            dayPlan = plan
            todayKey = plan.dayKey
            todayDate = plan.date
            stateScore = plan.stateScore ?? 7
            mainSubject = plan.mainSubject
            topTasksText = plan.topTasksText
            baselineTasksText = plan.baselineTasksText
            bonusTasksText = plan.bonusTasksText

            let reviewTomorrowFirstAction = try DailyReviewStore
                .fetchDailyReview(for: plan.dayKey, in: modelContext)?
                .tomorrowFirstAction
                .trimmingCharacters(in: .whitespacesAndNewlines)
            tomorrowFirstAction = reviewTomorrowFirstAction?.isEmpty == false
                ? reviewTomorrowFirstAction ?? ""
                : plan.tomorrowFirstAction

            try refreshTaskDataThrowing(for: plan.dayKey)
            loadState = .loaded
        } catch {
            loadState = .failed("无法读取或创建今日 DayPlan：\(error.localizedDescription)")
        }
    }

    private func refreshTaskData() {
        do {
            try refreshTaskDataThrowing(for: todayKey)
        } catch {
            taskMessage = "刷新任务失败：\(error.localizedDescription)"
        }
    }

    private func refreshTaskDataThrowing(for dayKey: String) throws {
        tasks = try StudyTaskStore.fetchTasks(for: dayKey, in: modelContext)
        totalTaskCount = try StudyTaskStore.countTasks(for: dayKey, in: modelContext)
        completedTaskCount = try StudyTaskStore.countCompletedTasks(for: dayKey, in: modelContext)
        builtInPromptTemplateCount = try PromptTemplateStore.countBuiltInTemplates(in: modelContext)
    }

    private func saveTodayPlan() {
        guard let plan = dayPlan else {
            saveMessage = "保存失败：今日计划尚未加载。"
            return
        }

        do {
            applyDraftPlanFields(to: plan)
            try modelContext.save()
            saveMessage = "今日计划已保存。"
        } catch {
            saveMessage = "保存失败：\(error.localizedDescription)"
        }
    }

    private func preparePlanTaskGeneration() {
        taskMessage = nil
        planTaskGenerationResult = nil

        let parsedTasks = PlanTaskParser.parsePlanSections(
            top: topTasksText,
            baseline: baselineTasksText,
            bonus: bonusTasksText
        )

        guard !parsedTasks.isEmpty else {
            taskMessage = "先在 Top / 保底 / 加分任务里写几行计划。"
            return
        }

        do {
            let existingTitleKeys = Set(
                try StudyTaskStore.fetchTasks(for: todayKey, in: modelContext).map {
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
        }
    }

    private func createTasksFromPlan(_ parsedTasks: [ParsedPlanTask]) {
        guard let plan = dayPlan else {
            taskMessage = "生成失败：今日计划尚未加载。"
            return
        }

        do {
            applyDraftPlanFields(to: plan)
            let result = try StudyTaskStore.createTasksFromPlan(
                dayPlan: plan,
                parsedTasks: parsedTasks,
                in: modelContext
            )
            try refreshTaskDataThrowing(for: todayKey)
            saveMessage = "已保存今日计划。"
            planTaskGenerationResult = PlanTaskGenerationResult(created: result.created, skipped: result.skipped)
            taskMessage = nil
        } catch {
            taskMessage = "生成今日任务失败：\(error.localizedDescription)"
        }
    }

    private func viewGeneratedTasks() {
        guard let onViewTasks else {
            taskMessage = "请进入 Tasks 页查看已生成任务。"
            return
        }

        onViewTasks()
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

    private func toggleTaskStatus(_ task: StudyTask) {
        let currentStatus = StudyTaskStatus.from(task.status)
        guard currentStatus == .pending || currentStatus == .done else {
            taskMessage = "Today 只支持快速切换待做/完成；更多状态请到任务页处理。"
            return
        }

        do {
            task.status = currentStatus == .done
                ? StudyTaskStatus.pending.storageValue
                : StudyTaskStatus.done.storageValue
            task.updatedAt = Date()
            try modelContext.save()
            try refreshTaskDataThrowing(for: todayKey)
            taskMessage = StudyTaskStatus.from(task.status) == .done ? "已标记完成。" : "已撤回待做。"
        } catch {
            taskMessage = "更新任务失败：\(error.localizedDescription)"
        }
    }
}

private enum LoadState: Equatable {
    case loading
    case loaded
    case failed(String)
}

#Preview {
    NavigationStack {
        TodayCockpitView()
    }
    .modelContainer(try! AppModelContainerFactory.make(inMemory: true))
}
