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

                            TodayDebugDisclosureCard()
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
            loadState = .failed(error.localizedDescription)
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
            saveMessage = "已保存今日计划：\(Date.now.formatted(date: .omitted, time: .shortened))"
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
        guard task.status == ModelDefaults.StudyTaskStatus.pending
            || task.status == ModelDefaults.StudyTaskStatus.done
        else {
            taskMessage = "Stage 3A 只支持 pending / done 快速切换。"
            return
        }

        do {
            task.status = task.status == ModelDefaults.StudyTaskStatus.done
                ? ModelDefaults.StudyTaskStatus.pending
                : ModelDefaults.StudyTaskStatus.done
            task.updatedAt = Date()
            try modelContext.save()
            try refreshTaskDataThrowing(for: todayKey)
            taskMessage = task.status == ModelDefaults.StudyTaskStatus.done ? "已标记完成。" : "已撤回待做。"
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

private struct TodayHeaderView: View {
    let date: Date
    let dayKey: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日驾驶舱")
                .font(.largeTitle.bold())

            Text(Self.dateFormatter.string(from: date))
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text(dayKey)
                Text("每天启动、专注、错题、复盘")
            }
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

private struct TodayStartupCard: View {
    @Binding var stateScore: Int
    @Binding var mainSubject: String

    var body: some View {
        TodayCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(title: "今日启动", systemImage: "sun.max")

                Stepper(value: $stateScore, in: 1...10) {
                    HStack {
                        Text("状态评分")
                        Spacer()
                        Text("\(stateScore)/10")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(stateScore <= 4 ? .orange : .primary)
                    }
                }
                .accessibilityLabel("状态评分")
                .accessibilityValue("\(stateScore) 分")

                VStack(alignment: .leading, spacing: 8) {
                    Text("主攻科目")
                        .font(.subheadline.weight(.semibold))

                    TextField("例如：数学", text: $mainSubject)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("主攻科目")
                }
            }
        }
    }
}

private struct LowEnergyModeCard: View {
    var body: some View {
        TodayCard(tint: .orange) {
            VStack(alignment: .leading, spacing: 8) {
                Label("今天只保住链条", systemImage: "bolt.heart")
                    .font(.headline)

                Text("先做保底任务，不追求完美。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct TodayPlanTextCard: View {
    @Binding var topTasksText: String
    @Binding var baselineTasksText: String
    @Binding var bonusTasksText: String
    let isLowEnergyMode: Bool

    var body: some View {
        TodayCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(title: "今日三层任务", systemImage: "square.stack.3d.up")

                LabeledTextEditor(
                    title: "Top Tasks",
                    subtitle: "今天最重要的 1-3 件事",
                    placeholder: "今天最重要的 1-3 件事",
                    text: $topTasksText
                )

                LabeledTextEditor(
                    title: "Baseline Tasks",
                    subtitle: "状态差也要完成",
                    placeholder: "最少要完成的事",
                    text: $baselineTasksText
                )

                if isLowEnergyMode {
                    Label("加分任务已收起，今天先保住链条。", systemImage: "tray")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    LabeledTextEditor(
                        title: "Bonus Tasks",
                        subtitle: "状态好时追加",
                        placeholder: "有余力就多做一点",
                        text: $bonusTasksText
                    )
                }
            }
        }
    }
}

private struct PlanToTaskActionCard: View {
    let onGenerate: () -> Void

    var body: some View {
        TodayCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(title: "计划转任务", systemImage: "arrow.triangle.branch")

                Text("按行拆分 Top / 保底 / 加分任务，自动生成今日任务。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button {
                    onGenerate()
                } label: {
                    Label("把计划加入任务页", systemImage: "text.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

private struct PlanTaskGenerationState: Identifiable {
    let id = UUID()
    let items: [PlanTaskConfirmationItem]

    var parsedTasks: [ParsedPlanTask] {
        items.map(\.parsedTask)
    }

    var creatableItems: [PlanTaskConfirmationItem] {
        items.filter { !$0.alreadyExists }
    }

    var duplicateItems: [PlanTaskConfirmationItem] {
        items.filter(\.alreadyExists)
    }
}

private struct PlanTaskConfirmationItem: Identifiable {
    let id = UUID()
    let parsedTask: ParsedPlanTask
    let alreadyExists: Bool
}

private struct PlanTaskGenerationResult: Equatable {
    let created: Int
    let skipped: Int

    var message: String {
        "已添加 \(created) 个任务，跳过 \(skipped) 个重复项。"
    }
}

private struct PlanTaskGenerationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let generation: PlanTaskGenerationState
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("已存在的同名任务会自动跳过。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !generation.creatableItems.isEmpty {
                    Section("将创建") {
                        ForEach(generation.creatableItems) { item in
                            PlanTaskPreviewRow(item: item)
                        }
                    }
                }

                if !generation.duplicateItems.isEmpty {
                    Section("已存在，将跳过") {
                        ForEach(generation.duplicateItems) { item in
                            PlanTaskPreviewRow(item: item)
                        }
                    }
                }
            }
            .navigationTitle("生成今日任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("确认添加") {
                        onConfirm()
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct PlanTaskPreviewRow: View {
    let item: PlanTaskConfirmationItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.alreadyExists ? "checkmark.circle" : "plus.circle")
                .foregroundStyle(item.alreadyExists ? Color.secondary : Color.green)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 5) {
                Text(item.parsedTask.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(item.alreadyExists ? .secondary : .primary)

                HStack(spacing: 8) {
                    SmallTag(text: item.parsedTask.sourceTitle)
                    SmallTag(text: item.parsedTask.category)
                    if item.alreadyExists {
                        Text("将跳过")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct TodayTaskSummaryCard: View {
    let totalTaskCount: Int
    let completedTaskCount: Int
    let pendingTaskCount: Int
    let builtInPromptTemplateCount: Int

    var body: some View {
        TodayCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle(title: "今日任务摘要", systemImage: "chart.bar.doc.horizontal")

                HStack(spacing: 10) {
                    StatPill(title: "任务", value: "\(totalTaskCount)")
                    StatPill(title: "已完成", value: "\(completedTaskCount)", isPositive: totalTaskCount > 0 && totalTaskCount == completedTaskCount)
                    StatPill(title: "未完成", value: "\(pendingTaskCount)")
                }

                Text("内置 Prompt 模板：\(builtInPromptTemplateCount) 个")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct TodayTaskListCard: View {
    let tasks: [StudyTask]
    let taskMessage: String?
    let planTaskGenerationResult: PlanTaskGenerationResult?
    let onToggleStatus: (StudyTask) -> Void
    let onQuickAdd: () -> Void
    let onViewTasks: () -> Void

    var body: some View {
        TodayCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionTitle(title: "今日任务列表", systemImage: "checklist")
                    Spacer()
                    Button {
                        onQuickAdd()
                    } label: {
                        Label("快速新增", systemImage: "plus.circle")
                    }
                    .buttonStyle(.bordered)
                }

                if tasks.isEmpty {
                    Text("先添加一个能立刻开始的任务。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                } else {
                    VStack(spacing: 10) {
                        ForEach(tasks, id: \.id) { task in
                            TodayTaskRowView(task: task) {
                                onToggleStatus(task)
                            }

                            if task.id != tasks.last?.id {
                                Divider()
                            }
                        }
                    }
                }

                if let planTaskGenerationResult {
                    PlanTaskGenerationResultView(
                        result: planTaskGenerationResult,
                        onViewTasks: onViewTasks
                    )
                }

                if let taskMessage {
                    Text(taskMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct PlanTaskGenerationResultView: View {
    let result: PlanTaskGenerationResult
    let onViewTasks: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(result.message, systemImage: "checkmark.circle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.green)

            Button {
                onViewTasks()
            } label: {
                Label("查看任务页", systemImage: "checklist")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(10)
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct TodayTaskRowView: View {
    let task: StudyTask
    let onToggleStatus: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                onToggleStatus()
            } label: {
                Image(systemName: task.statusIconName)
                    .font(.title3)
                    .foregroundStyle(task.statusIconColor)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .disabled(!task.canToggleInStage3A)
            .accessibilityLabel(task.status == ModelDefaults.StudyTaskStatus.done ? "撤回待做" : "标记完成")

            VStack(alignment: .leading, spacing: 7) {
                Text(task.title.isEmpty ? "未命名任务" : task.title)
                    .font(.subheadline.weight(.semibold))
                    .strikethrough(task.status == ModelDefaults.StudyTaskStatus.done)
                    .foregroundStyle(task.status == ModelDefaults.StudyTaskStatus.done ? .secondary : .primary)

                HStack(spacing: 8) {
                    SmallTag(text: task.subject.isEmpty ? "未设科目" : task.subject)
                    SmallTag(text: task.category.isEmpty ? "未分类" : task.category)
                    Text(task.statusDisplayText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let estimatedMinutes = task.estimatedMinutes {
                        Text("\(estimatedMinutes) 分钟")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
    }
}

private struct TomorrowFirstActionCard: View {
    @Binding var text: String

    var body: some View {
        TodayCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(title: "明日第一步", systemImage: "arrow.forward.circle")

                LabeledTextEditor(
                    title: "明天打开 App 后第一件事",
                    subtitle: "写一句能直接执行的话",
                    placeholder: "明天打开 App 后第一件事",
                    text: $text,
                    minHeight: 70
                )
            }
        }
    }
}

private struct SavePlanCard: View {
    let saveMessage: String?
    let onSave: () -> Void

    var body: some View {
        TodayCard {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    onSave()
                } label: {
                    Label("保存今日计划", systemImage: "tray.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if let saveMessage {
                    Text(saveMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("编辑内容会先留在本页，点击按钮后统一写回 DayPlan。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct TodayDebugDisclosureCard: View {
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Stage2DebugPersistenceView()
                .padding(.top, 10)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Label("Stage 2 Debug", systemImage: "wrench.and.screwdriver")
                    .font(.footnote.weight(.semibold))
                Text("Stage 2 Debug only - will be removed later.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct TodayQuickAddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let dayKey: String
    let dayPlanID: UUID?
    let defaultSubject: String
    let onSaved: () -> Void

    @State private var title = ""
    @State private var subject: String
    @State private var category = "做题"
    @State private var estimatedMinutes = 25
    @State private var errorMessage: String?

    private let categories = ["做题", "预习", "复盘", "背诵", "整理", "其他"]

    init(
        dayKey: String,
        dayPlanID: UUID?,
        defaultSubject: String,
        onSaved: @escaping () -> Void
    ) {
        self.dayKey = dayKey
        self.dayPlanID = dayPlanID
        self.defaultSubject = defaultSubject
        self.onSaved = onSaved
        _subject = State(initialValue: defaultSubject)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("具体要做什么？", text: $title)
                        .accessibilityLabel("任务标题")

                    TextField("科目", text: $subject)
                        .accessibilityLabel("科目")

                    Picker("类型", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }

                    Stepper(value: $estimatedMinutes, in: 5...180, step: 5) {
                        Text("预计 \(estimatedMinutes) 分钟")
                    }
                    .accessibilityLabel("预计分钟")
                    .accessibilityValue("\(estimatedMinutes) 分钟")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("快速新增任务")
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
        }
    }

    private func saveTask() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            errorMessage = "请先填写任务标题。"
            return
        }

        do {
            let task = try StudyTaskStore.createTask(
                dayKey: dayKey,
                title: cleanTitle,
                subject: subject.trimmingCharacters(in: .whitespacesAndNewlines),
                category: category,
                estimatedMinutes: estimatedMinutes,
                in: modelContext
            )
            task.dayPlanId = dayPlanID
            task.updatedAt = Date()
            try modelContext.save()

            title = ""
            subject = defaultSubject
            category = categories[0]
            estimatedMinutes = 25
            errorMessage = nil
            onSaved()
            dismiss()
        } catch {
            errorMessage = "保存任务失败：\(error.localizedDescription)"
        }
    }
}

private struct LabeledTextEditor: View {
    let title: String
    let subtitle: String
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 92

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .frame(minHeight: minHeight)
                    .scrollContentBackground(.hidden)
                    .accessibilityLabel(title)

                if text.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
            .padding(8)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(.separator).opacity(0.45), lineWidth: 1)
            }
        }
    }
}

private struct TodayCard<Content: View>: View {
    var tint: Color?
    let content: Content

    init(tint: Color? = nil, @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var background: some ShapeStyle {
        if let tint {
            return AnyShapeStyle(tint.opacity(0.12))
        }

        return AnyShapeStyle(Color(.secondarySystemBackground))
    }
}

private struct SectionTitle: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
    }
}

private struct StatPill: View {
    let title: String
    let value: String
    var isPositive = false

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(isPositive ? .green : .primary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct SmallTag: View {
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

private extension StudyTask {
    var canToggleInStage3A: Bool {
        status == ModelDefaults.StudyTaskStatus.pending || status == ModelDefaults.StudyTaskStatus.done
    }

    var statusDisplayText: String {
        switch status {
        case ModelDefaults.StudyTaskStatus.pending:
            return "待做"
        case ModelDefaults.StudyTaskStatus.inProgress:
            return "进行中"
        case ModelDefaults.StudyTaskStatus.done:
            return "已完成"
        case ModelDefaults.StudyTaskStatus.skipped:
            return "已跳过"
        default:
            return status
        }
    }

    var statusIconName: String {
        switch status {
        case ModelDefaults.StudyTaskStatus.done:
            return "checkmark.circle.fill"
        case ModelDefaults.StudyTaskStatus.inProgress:
            return "circle.lefthalf.filled"
        case ModelDefaults.StudyTaskStatus.skipped:
            return "minus.circle"
        default:
            return "circle"
        }
    }

    var statusIconColor: Color {
        switch status {
        case ModelDefaults.StudyTaskStatus.done:
            return .green
        case ModelDefaults.StudyTaskStatus.inProgress:
            return .blue
        case ModelDefaults.StudyTaskStatus.skipped:
            return .secondary
        default:
            return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        TodayCockpitView()
    }
    .modelContainer(try! AppModelContainerFactory.make(inMemory: true))
}
