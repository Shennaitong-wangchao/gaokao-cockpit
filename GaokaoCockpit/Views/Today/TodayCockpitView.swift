import SwiftData
import SwiftUI

struct TodayCockpitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager

    private let onViewTasks: (() -> Void)?
    @State private var model = TodayCockpitModel()

    init(onViewTasks: (() -> Void)? = nil) {
        self.onViewTasks = onViewTasks
    }

    var body: some View {
        Group {
            switch model.loadState {
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
                        model.loadToday(context: modelContext)
                    }
                    .buttonStyle(.borderedProminent)
                }

            case .loaded:
                if model.dayPlan == nil {
                    ContentUnavailableView {
                        Label("今日计划为空", systemImage: "calendar.badge.exclamationmark")
                    } description: {
                        Text("没有找到今日 DayPlan。")
                    } actions: {
                        Button("创建今日计划") {
                            model.loadToday(context: modelContext)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            TodayHeaderView(date: model.todayDate, dayKey: model.todayKey)
                                .cardAppear(delay: 0)

                            TodayStartupCard(
                                stateScore: $model.stateScore,
                                mainSubject: $model.mainSubject
                            )
                            .cardAppear(delay: 0.1)

                            if model.isLowEnergyMode {
                                LowEnergyModeCard()
                                    .cardAppear(delay: 0.2)
                            }

                            TodayTaskSummaryCard(
                                totalTaskCount: model.totalTaskCount,
                                completedTaskCount: model.completedTaskCount,
                                pendingTaskCount: model.pendingTaskCount,
                                builtInPromptTemplateCount: model.builtInPromptTemplateCount
                            )
                            .cardAppear(delay: model.isLowEnergyMode ? 0.3 : 0.2)

                            TodayTaskListCard(
                                tasks: model.tasks,
                                taskMessage: model.taskMessage,
                                planTaskGenerationResult: model.planTaskGenerationResult,
                                onToggleStatus: { task in
                                    model.toggleTaskStatus(in: modelContext, task: task)
                                },
                                onQuickAdd: {
                                    model.isShowingQuickAddTask = true
                                },
                                onViewTasks: viewGeneratedTasks
                            )

                            TodayPlanTextCard(
                                topTasksText: $model.topTasksText,
                                baselineTasksText: $model.baselineTasksText,
                                bonusTasksText: $model.bonusTasksText,
                                isLowEnergyMode: model.isLowEnergyMode
                            )

                            PlanToTaskActionCard(
                                message: model.planTaskMessage,
                                onGenerate: {
                                    model.preparePlanTaskGeneration(in: modelContext)
                                }
                            )

                            TomorrowFirstActionCard(text: $model.tomorrowFirstAction)

                            SavePlanCard(
                                saveMessage: model.saveMessage,
                                onSave: {
                                    model.saveTodayPlan(in: modelContext)
                                }
                            )
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .refreshable {
                        model.refreshTaskData(for: model.todayKey, in: modelContext)
                    }
                }
            }
        }
        .navigationTitle("今日")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            model.loadToday(context: modelContext)
        }
        .onAppear {
            if model.loadState == .loaded {
                model.refreshTaskData(for: model.todayKey, in: modelContext)
            }
            // 更新动态主题
            updateTheme()
        }
        .onReceive(NotificationCenter.default.publisher(for: StudyTaskStore.didChangeNotification)) { notification in
            if model.handleTaskStoreDidChange(notification) {
                model.refreshTaskData(for: model.todayKey, in: modelContext)
            }
        }
        .sheet(isPresented: $model.isShowingQuickAddTask) {
            TodayQuickAddTaskSheet(
                dayKey: model.todayKey,
                dayPlanID: model.dayPlan?.id,
                defaultSubject: model.mainSubject.trimmingCharacters(in: .whitespacesAndNewlines)
            ) {
                model.refreshTaskData(for: model.todayKey, in: modelContext)
                model.planTaskGenerationResult = nil
                model.taskMessage = "已新增今日任务。"
                HapticFeedback.success()
                ToastManager.shared.show(message: "已新增今日任务", style: .success)
            }
        }
        .sheet(item: $model.activePlanTaskGeneration) { generation in
            PlanTaskGenerationSheet(generation: generation) {
                model.createTasksFromPlan(in: modelContext, parsedTasks: generation.parsedTasks)
            }
        }
    }

    private func viewGeneratedTasks() {
        guard let onViewTasks else {
            model.taskMessage = "请进入 Tasks 页查看已生成任务。"
            return
        }
        onViewTasks()
    }

    private func updateTheme() {
        let isGoalAchieved = model.totalTaskCount > 0 && model.completedTaskCount == model.totalTaskCount
        themeManager.updateTheme(
            basedOn: Date(),
            stateScore: model.stateScore,
            isGoalAchieved: isGoalAchieved,
            isLowEnergyMode: model.isLowEnergyMode
        )
    }
}

enum LoadState: Equatable {
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
