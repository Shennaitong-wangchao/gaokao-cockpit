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

                Picker("任务筛选", selection: $selectedFilter) {
                    ForEach(TaskFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("任务筛选")

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

private enum TaskFilter: String, CaseIterable, Identifiable {
    case all
    case unfinished
    case done
    case skipped

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .unfinished:
            return "未完成"
        case .done:
            return "已完成"
        case .skipped:
            return "跳过"
        }
    }

    var status: StudyTaskStatus? {
        switch self {
        case .all, .unfinished:
            return nil
        case .done:
            return .done
        case .skipped:
            return .skipped
        }
    }

    var emptyTitle: String {
        switch self {
        case .all:
            return "今天还没有任务"
        case .unfinished:
            return "没有未完成任务"
        case .done:
            return "还没有完成任务"
        case .skipped:
            return "没有跳过任务"
        }
    }

    var emptyMessage: String {
        switch self {
        case .all:
            return "还没有任务。可以从 Today 生成，或在这里手动添加。"
        case .unfinished:
            return "当前筛选下没有未开始或进行中任务。"
        case .done:
            return "完成任务后会出现在这里。"
        case .skipped:
            return "手动标记跳过的任务会出现在这里。"
        }
    }

    var emptySystemImage: String {
        switch self {
        case .all:
            return "checklist"
        case .unfinished:
            return "circle"
        case .done:
            return "checkmark.circle"
        case .skipped:
            return "minus.circle"
        }
    }
}

private enum TaskEditorMode: Identifiable {
    case add
    case edit(StudyTask)

    var id: String {
        switch self {
        case .add:
            return "add-task"
        case .edit(let task):
            return task.id.uuidString
        }
    }

    var title: String {
        switch self {
        case .add:
            return "新增任务"
        case .edit:
            return "编辑任务"
        }
    }
}

private struct TaskListHeaderView: View {
    let date: Date
    let dayKey: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("学习任务")
                .font(.largeTitle.bold())

            Text(Self.dateFormatter.string(from: date))
                .font(.title3.weight(.semibold))

            Text(dayKey)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter
    }()
}

private struct TaskSummaryCard: View {
    let totalTaskCount: Int
    let completedTaskCount: Int
    let unfinishedTaskCount: Int

    var body: some View {
        TaskListCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("今日任务概览", systemImage: "chart.bar.doc.horizontal")
                    .font(.headline)

                HStack(spacing: 10) {
                    SummaryValue(title: "今日任务", value: totalTaskCount)
                    SummaryValue(title: "已完成", value: completedTaskCount, tint: .green)
                    SummaryValue(title: "未完成", value: unfinishedTaskCount, tint: .orange)
                }
            }
        }
    }
}

private struct SummaryValue: View {
    let title: String
    let value: Int
    var tint: Color = .primary

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct TaskRowView: View {
    let task: StudyTask
    let onTap: () -> Void
    let onFocusFinished: () -> Void
    let onChangeStatus: (StudyTaskStatus) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    onTap()
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: task.taskListStatusIconName)
                            .font(.title3)
                            .foregroundStyle(task.taskListStatusIconColor)
                            .frame(width: 28, height: 28)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(task.title.isEmpty ? "未命名任务" : task.title)
                                .font(.headline)
                                .foregroundStyle(task.taskListStatus == .done ? .secondary : .primary)
                                .strikethrough(task.taskListStatus == .done)
                                .lineLimit(2)

                            HStack(spacing: 8) {
                                TaskTag(text: task.taskListSubjectText)
                                TaskTag(text: task.taskListCategoryText)
                            }

                            Text(task.taskListMinutesText)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if !task.outputNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(task.outputNote)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("编辑任务")

                Menu {
                    ForEach(TaskStatusOption.all) { option in
                        Button {
                            onChangeStatus(option.status)
                        } label: {
                            Label(option.title, systemImage: option.systemImage)
                        }
                    }
                } label: {
                    Label(task.taskListStatusTitle, systemImage: "chevron.down.circle")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("切换任务状态")
            }

            HStack(spacing: 10) {
                NavigationLink {
                    FocusSessionView(task: task, onFinished: onFocusFinished)
                } label: {
                    Label("开始专注", systemImage: "timer")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    onTap()
                } label: {
                    Label("编辑", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct TaskTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct TaskEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let mode: TaskEditorMode
    let dayKey: String
    let dayPlanID: UUID?
    let onChanged: (String) -> Void

    @State private var title: String
    @State private var subject: LearningSubject
    @State private var category: StudyTaskCategory
    @State private var estimatedMinutesText: String
    @State private var actualMinutesText: String
    @State private var status: StudyTaskStatus
    @State private var outputNote: String
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false

    init(
        mode: TaskEditorMode,
        dayKey: String,
        dayPlanID: UUID?,
        onChanged: @escaping (String) -> Void
    ) {
        self.mode = mode
        self.dayKey = dayKey
        self.dayPlanID = dayPlanID
        self.onChanged = onChanged

        switch mode {
        case .add:
            _title = State(initialValue: "")
            _subject = State(initialValue: .math)
            _category = State(initialValue: .exercise)
            _estimatedMinutesText = State(initialValue: "25")
            _actualMinutesText = State(initialValue: "")
            _status = State(initialValue: .pending)
            _outputNote = State(initialValue: "")
        case .edit(let task):
            _title = State(initialValue: task.title)
            _subject = State(initialValue: LearningSubject.from(task.subject))
            _category = State(initialValue: StudyTaskCategory.from(task.category))
            _estimatedMinutesText = State(initialValue: task.estimatedMinutes.map(String.init) ?? "")
            _actualMinutesText = State(initialValue: task.actualMinutes.map(String.init) ?? "")
            _status = State(initialValue: StudyTaskStatus.from(task.status))
            _outputNote = State(initialValue: task.outputNote)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基础信息") {
                    TextField("任务标题", text: $title)
                        .accessibilityLabel("任务标题")

                    Picker("科目", selection: $subject) {
                        ForEach(LearningSubject.allCases) { subject in
                            Text(subject.displayName).tag(subject)
                        }
                    }

                    Picker("类型", selection: $category) {
                        ForEach(StudyTaskCategory.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }

                Section("时间与状态") {
                    TextField("预计分钟", text: $estimatedMinutesText)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("预计分钟")

                    TextField("实际分钟", text: $actualMinutesText)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("实际分钟")

                    Picker("状态", selection: $status) {
                        ForEach(StudyTaskStatus.allCases) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                }

                Section("产出备注") {
                    TextEditor(text: $outputNote)
                        .frame(minHeight: 90)
                        .accessibilityLabel("产出备注")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                if case .edit = mode {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("删除任务", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTask()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .confirmationDialog(
                "确认删除这个任务？",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("删除任务", role: .destructive) {
                    deleteTask()
                }

                Button("取消", role: .cancel) {}
            } message: {
                Text("删除后，这个任务和任务页里的记录将无法恢复。")
            }
        }
    }

    private func saveTask() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            errorMessage = "请先填写任务标题。"
            return
        }

        guard let minutes = validatedMinutes() else {
            return
        }

        do {
            switch mode {
            case .add:
                _ = try StudyTaskStore.createTask(
                    dayKey: dayKey,
                    title: cleanTitle,
                    subject: subject.storageValue,
                    category: category,
                    estimatedMinutes: minutes.estimated,
                    actualMinutes: minutes.actual,
                    status: status,
                    outputNote: outputNote.trimmingCharacters(in: .whitespacesAndNewlines),
                    dayPlanId: dayPlanID,
                    in: modelContext
                )
                onChanged("已新增任务。")

            case .edit(let task):
                task.title = cleanTitle
                task.subject = subject.storageValue
                task.category = category.storageValue
                task.estimatedMinutes = minutes.estimated
                task.actualMinutes = minutes.actual
                task.status = status.storageValue
                task.outputNote = outputNote.trimmingCharacters(in: .whitespacesAndNewlines)
                if task.dayPlanId == nil {
                    task.dayPlanId = dayPlanID
                }
                StudyTaskStore.updateTaskTimestamp(task)
                try modelContext.save()
                onChanged("已保存任务。")
            }

            dismiss()
        } catch {
            errorMessage = "保存失败，请重试。"
        }
    }

    private func deleteTask() {
        guard case .edit(let task) = mode else {
            return
        }

        do {
            try StudyTaskStore.deleteTask(task, in: modelContext)
            onChanged("已删除任务。")
            dismiss()
        } catch {
            errorMessage = "删除失败，请重试。"
        }
    }

    private func validatedMinutes() -> (estimated: Int?, actual: Int?)? {
        guard let estimated = parseMinutes(estimatedMinutesText, fieldName: "预计分钟") else {
            return nil
        }

        guard let actual = parseMinutes(actualMinutesText, fieldName: "实际分钟") else {
            return nil
        }

        return (estimated, actual)
    }

    private func parseMinutes(_ rawValue: String, fieldName: String) -> Int?? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .some(nil)
        }

        guard let value = Int(trimmed), value >= 0 else {
            errorMessage = "\(fieldName)请输入 0 或正整数。"
            return nil
        }

        return .some(value)
    }

}

private struct TaskListCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct TaskStatusOption: Identifiable {
    let status: StudyTaskStatus
    let systemImage: String

    var id: String { status.rawValue }

    var title: String { status.displayName }

    static let all: [TaskStatusOption] = [
        TaskStatusOption(
            status: .pending,
            systemImage: "circle"
        ),
        TaskStatusOption(
            status: .inProgress,
            systemImage: "circle.lefthalf.filled"
        ),
        TaskStatusOption(
            status: .done,
            systemImage: "checkmark.circle.fill"
        ),
        TaskStatusOption(
            status: .skipped,
            systemImage: "minus.circle"
        )
    ]

    static func title(for status: String) -> String {
        StudyTaskStatus.from(status).displayName
    }

    static func systemImage(for status: String) -> String {
        systemImage(for: StudyTaskStatus.from(status))
    }

    static func systemImage(for status: StudyTaskStatus) -> String {
        all.first { $0.status == status }?.systemImage ?? "circle"
    }
}

private extension StudyTask {
    var taskListStatus: StudyTaskStatus {
        StudyTaskStatus.from(status)
    }

    var isTaskListUnfinished: Bool {
        taskListStatus == .pending || taskListStatus == .inProgress
    }

    var taskListStatusTitle: String {
        TaskStatusOption.title(for: status)
    }

    var taskListStatusIconName: String {
        TaskStatusOption.systemImage(for: status)
    }

    var taskListStatusIconColor: Color {
        switch taskListStatus {
        case .done:
            return .green
        case .inProgress:
            return .blue
        case .skipped:
            return .secondary
        case .pending:
            return .orange
        }
    }

    var taskListSubjectText: String {
        subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "未设科目"
            : LearningSubject.from(subject).displayName
    }

    var taskListCategoryText: String {
        category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "未分类"
            : StudyTaskCategory.from(category).displayName
    }

    var taskListMinutesText: String {
        let estimatedText = estimatedMinutes.map { "预计 \($0) 分钟" } ?? "预计未填写"
        let actualText = actualMinutes.map { "实际 \($0) 分钟" } ?? "实际未填写"
        return "\(estimatedText) / \(actualText)"
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
