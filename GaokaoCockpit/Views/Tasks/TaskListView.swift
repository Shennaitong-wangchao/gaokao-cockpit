import SwiftData
import SwiftUI

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var todayKey = DateKey.todayKey()
    @State private var todayDate = Date()
    @State private var dayPlan: DayPlan?
    @State private var tasks: [StudyTask] = []
    @State private var selectedFilter: TaskFilter = .all
    @State private var totalTaskCount = 0
    @State private var completedTaskCount = 0
    @State private var skippedTaskCount = 0
    @State private var isLoading = true
    @State private var statusMessage: String?
    @State private var activeEditor: TaskEditorMode?

    private var unfinishedTaskCount: Int {
        max(totalTaskCount - completedTaskCount - skippedTaskCount, 0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                TaskListHeaderView(date: todayDate, dayKey: todayKey)

                TaskSummaryCard(
                    totalTaskCount: totalTaskCount,
                    completedTaskCount: completedTaskCount,
                    unfinishedTaskCount: unfinishedTaskCount
                )

                TaskFilterBar(selectedFilter: $selectedFilter)

                if isLoading {
                    ProgressView("正在加载今日任务")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 28)
                } else if tasks.isEmpty {
                    ContentUnavailableView {
                        Label(selectedFilter.emptyTitle, systemImage: selectedFilter.emptySystemImage)
                    } description: {
                        Text(selectedFilter.emptyMessage)
                    } actions: {
                        Button {
                            activeEditor = .add
                        } label: {
                            Label("新增任务", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 12)
                } else {
                    VStack(spacing: 10) {
                        ForEach(tasks, id: \.id) { task in
                            TaskRowView(
                                task: task,
                                onTap: {
                                    activeEditor = .edit(task)
                                },
                                onFocusFinished: {
                                    refreshTaskData()
                                    statusMessage = "已保存专注记录。"
                                },
                                onChangeStatus: { status in
                                    updateTaskStatus(task, to: status)
                                }
                            )
                        }
                    }
                }

                Button {
                    activeEditor = .add
                } label: {
                    Label("新增任务", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if let statusMessage {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("任务")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadTodayTasks()
        }
        .onAppear {
            if !isLoading {
                refreshTaskData()
            }
        }
        .onChange(of: selectedFilter) {
            refreshTaskData()
        }
        .refreshable {
            refreshTaskData()
        }
        .sheet(item: $activeEditor) { editor in
            TaskEditorSheet(
                mode: editor,
                dayKey: todayKey,
                dayPlanID: dayPlan?.id
            ) { message in
                refreshTaskData()
                statusMessage = message
            }
        }
    }

    private func loadTodayTasks() {
        isLoading = true
        statusMessage = nil

        do {
            let plan = try DayPlanStore.fetchOrCreateToday(in: modelContext)
            dayPlan = plan
            todayKey = plan.dayKey
            todayDate = plan.date
            try refreshTaskDataThrowing()
            isLoading = false
        } catch {
            isLoading = false
            statusMessage = "加载任务失败，请重试。"
        }
    }

    private func refreshTaskData() {
        do {
            try refreshTaskDataThrowing()
        } catch {
            statusMessage = "刷新任务失败，请重试。"
        }
    }

    private func refreshTaskDataThrowing() throws {
        let fetchedTasks = try StudyTaskStore.fetchTasks(
            for: todayKey,
            status: selectedFilter.status?.storageValue,
            in: modelContext
        )

        tasks = selectedFilter == .unfinished
            ? fetchedTasks.filter(\.isTaskListUnfinished)
            : fetchedTasks
        totalTaskCount = try StudyTaskStore.countTasks(for: todayKey, in: modelContext)
        completedTaskCount = try StudyTaskStore.countCompletedTasks(for: todayKey, in: modelContext)
        skippedTaskCount = try StudyTaskStore.countSkippedTasks(for: todayKey, in: modelContext)
    }

    private func updateTaskStatus(_ task: StudyTask, to status: StudyTaskStatus) {
        guard StudyTaskStatus.from(task.status) != status else {
            return
        }

        do {
            task.status = status.storageValue
            StudyTaskStore.updateTaskTimestamp(task)
            try modelContext.save()
            try refreshTaskDataThrowing()
            statusMessage = "已更新状态：\(status.displayName)。"
        } catch {
            statusMessage = "更新状态失败，请重试。"
        }
    }
}

#Preview {
    let container = try! AppModelContainerFactory.make(inMemory: true)
    let context = container.mainContext
    let dayPlan = DayPlan(
        dayKey: DateKey.todayKey(),
        date: DateKey.startOfDay(for: Date()),
        mainSubject: LearningSubject.math.storageValue
    )

    context.insert(dayPlan)
    context.insert(
        StudyTask(
            dayPlanId: dayPlan.id,
            dayKey: dayPlan.dayKey,
            title: "函数导数压轴题 6 道",
            subject: LearningSubject.math.storageValue,
            category: StudyTaskCategory.exercise.storageValue,
            estimatedMinutes: 45,
            actualMinutes: 50,
            status: StudyTaskStatus.inProgress.storageValue,
            outputNote: "已完成前 4 道，第 5 道参数分类需要复盘。"
        )
    )
    context.insert(
        StudyTask(
            dayPlanId: dayPlan.id,
            dayKey: dayPlan.dayKey,
            title: "英语阅读 C 篇精读",
            subject: LearningSubject.english.storageValue,
            category: StudyTaskCategory.review.storageValue,
            estimatedMinutes: 25,
            status: StudyTaskStatus.done.storageValue,
            outputNote: "整理了 6 个长难句触发信号。"
        )
    )

    return NavigationStack {
        TaskListView()
    }
    .modelContainer(container)
}
