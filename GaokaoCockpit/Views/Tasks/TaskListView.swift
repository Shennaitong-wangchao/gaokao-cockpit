import SwiftData
import SwiftUI

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var model = TaskListModel()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                TaskListHeaderView(date: model.todayDate, dayKey: model.todayKey)

                TaskSummaryCard(
                    totalTaskCount: model.totalTaskCount,
                    completedTaskCount: model.completedTaskCount,
                    unfinishedTaskCount: model.unfinishedTaskCount
                )

                TaskFilterBar(selectedFilter: $model.selectedFilter)

                if model.isLoading {
                    ProgressView("正在加载今日任务")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 28)
                } else if model.tasks.isEmpty {
                    ContentUnavailableView {
                        Label(model.selectedFilter.emptyTitle, systemImage: model.selectedFilter.emptySystemImage)
                    } description: {
                        Text(model.selectedFilter.emptyMessage)
                    } actions: {
                        Button {
                            model.activeEditor = .add
                        } label: {
                            Label("新增任务", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("新增任务")
                        .accessibilityHint("打开任务编辑表单")
                    }
                    .padding(.vertical, 12)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(model.tasks.enumerated()), id: \.element.id) { index, task in
                            TaskRowView(
                                task: task,
                                onTap: {
                                    model.activeEditor = .edit(task)
                                },
                                onFocusFinished: {
                                    model.refreshTaskData(in: modelContext)
                                    model.statusMessage = "已保存专注记录。"
                                    HapticFeedback.success()
                                    ToastManager.shared.show(message: "已保存专注记录", style: .success)
                                },
                                onChangeStatus: { status in
                                    model.updateTaskStatus(in: modelContext, task: task, to: status)
                                }
                            )
                            .staggeredAppear(index: index)
                        }
                    }
                }

                if !model.isLoading && !model.tasks.isEmpty {
                    Button {
                        model.activeEditor = .add
                    } label: {
                        Label("新增任务", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("新增任务")
                    .accessibilityHint("打开任务编辑表单")
                }

                if let statusMessage = model.statusMessage {
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
            model.loadTodayTasks(in: modelContext)
        }
        .onAppear {
            if !model.isLoading {
                model.refreshTaskData(in: modelContext)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: StudyTaskStore.didChangeNotification)) { notification in
            if model.handleTaskStoreDidChange(notification) {
                model.refreshTaskData(in: modelContext)
            }
        }
        .onChange(of: model.selectedFilter) {
            model.refreshTaskData(in: modelContext)
        }
        .refreshable {
            model.refreshTaskData(in: modelContext)
        }
        .sheet(item: $model.activeEditor) { editor in
            TaskEditorSheet(
                mode: editor,
                dayKey: model.todayKey,
                dayPlanID: model.dayPlan?.id
            ) { message in
                model.refreshTaskData(in: modelContext)
                model.statusMessage = message
            }
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
