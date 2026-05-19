import SwiftData
import SwiftUI

struct ReviewView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var loadState: ReviewLoadState = .loading
    @State private var selectedMode: ReviewMode = .daily
    @State private var statusMessage: String?

    @State private var todayKey = DateKey.todayKey()
    @State private var todayDate = Date()
    @State private var currentWeekStart = DateKey.weekStart(for: Date())
    @State private var currentWeekEnd = DateKey.weekEnd(for: Date())

    @State private var dailyReview: DailyReview?
    @State private var dailySummary = DailyReviewSummary.empty
    @State private var todayMistakes: [MistakeRecord] = []
    @State private var completedSummary = ""
    @State private var unfinishedSummary = ""
    @State private var biggestProblem = ""
    @State private var bestMistakeId: UUID?
    @State private var stateScoreEnd = 6
    @State private var tomorrowFirstAction = ""

    @State private var weeklyReview: WeeklyReview?
    @State private var weeklySummary = WeeklyReviewSummary.empty
    @State private var keyProblemsText = ""
    @State private var nextWeekFocusText = ""

    @State private var activePromptSheet: ReviewPromptSheet?

    var body: some View {
        Group {
            switch loadState {
            case .loading:
                ProgressView("正在加载复盘")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .failed(let message):
                ContentUnavailableView {
                    Label("复盘加载失败", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("重新加载") {
                        loadReviews()
                    }
                    .buttonStyle(.borderedProminent)
                }

            case .loaded:
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ReviewHeaderView()

                        Picker("复盘类型", selection: $selectedMode) {
                            ForEach(ReviewMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("复盘类型")

                        switch selectedMode {
                        case .daily:
                            DailyReviewSection(
                                date: todayDate,
                                summary: dailySummary,
                                todayMistakes: todayMistakes,
                                completedSummary: $completedSummary,
                                unfinishedSummary: $unfinishedSummary,
                                biggestProblem: $biggestProblem,
                                bestMistakeId: $bestMistakeId,
                                stateScoreEnd: $stateScoreEnd,
                                tomorrowFirstAction: $tomorrowFirstAction,
                                onSave: saveDailyReview,
                                onGeneratePrompt: generateDailyPrompt
                            )

                        case .weekly:
                            WeeklyReviewSection(
                                weekStart: currentWeekStart,
                                weekEnd: currentWeekEnd,
                                summary: weeklySummary,
                                keyProblemsText: $keyProblemsText,
                                nextWeekFocusText: $nextWeekFocusText,
                                onSave: saveWeeklyReview,
                                onGeneratePrompt: generateWeeklyPrompt
                            )
                        }

                        if let statusMessage {
                            Text(statusMessage)
                                .font(.footnote)
                                .foregroundStyle(statusMessage.hasPrefix("已") ? Color.secondary : Color.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .refreshable {
                    loadReviews()
                }
            }
        }
        .navigationTitle("复盘")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadReviews()
        }
        .sheet(item: $activePromptSheet) { sheet in
            PromptTemplateDetailView(
                template: sheet.template,
                initialValues: sheet.values
            ) { message in
                statusMessage = message
            }
        }
    }

    private func loadReviews() {
        loadState = .loading
        statusMessage = nil

        do {
            let review = try DailyReviewStore.fetchOrCreateTodayReview(in: modelContext)
            let weekReview = try WeeklyReviewStore.fetchOrCreateCurrentWeekReview(in: modelContext)

            todayKey = review.dayKey
            todayDate = review.date
            dailyReview = review

            currentWeekStart = weekReview.weekStartDate
            currentWeekEnd = weekReview.weekEndDate
            weeklyReview = weekReview

            todayMistakes = try fetchMistakes(for: review.dayKey)
            applyDailyReview(review)
            applyWeeklyReview(weekReview)

            var warnings: [String] = []
            do {
                dailySummary = try makeDailySummary(dayKey: review.dayKey)
            } catch {
                dailySummary = .empty
                warnings.append("今日汇总失败：\(error.localizedDescription)")
            }

            do {
                weeklySummary = try makeWeeklySummary(start: weekReview.weekStartDate, end: weekReview.weekEndDate)
            } catch {
                weeklySummary = .empty
                warnings.append("本周汇总失败：\(error.localizedDescription)")
            }

            statusMessage = warnings.isEmpty ? nil : warnings.joined(separator: "\n")
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    private func applyDailyReview(_ review: DailyReview) {
        completedSummary = review.completedSummary
        unfinishedSummary = review.unfinishedSummary
        biggestProblem = review.biggestProblem
        stateScoreEnd = review.stateScoreEnd ?? 6
        tomorrowFirstAction = review.tomorrowFirstAction

        if let id = review.bestMistakeId, todayMistakes.contains(where: { $0.id == id }) {
            bestMistakeId = id
        } else {
            bestMistakeId = nil
        }
    }

    private func applyWeeklyReview(_ review: WeeklyReview) {
        keyProblemsText = review.keyProblemsText
        nextWeekFocusText = review.nextWeekFocusText
    }

    private func makeDailySummary(dayKey: String) throws -> DailyReviewSummary {
        DailyReviewSummary(
            taskCount: try ReviewAggregationStore.todayTaskCount(dayKey: dayKey, in: modelContext),
            completedTaskCount: try ReviewAggregationStore.todayCompletedTaskCount(dayKey: dayKey, in: modelContext),
            focusMinutes: try ReviewAggregationStore.todayFocusMinutes(dayKey: dayKey, in: modelContext),
            focusSessionCount: try ReviewAggregationStore.todayFocusSessionCount(dayKey: dayKey, in: modelContext),
            mistakeCount: try ReviewAggregationStore.todayMistakeCount(dayKey: dayKey, in: modelContext)
        )
    }

    private func makeWeeklySummary(start: Date, end: Date) throws -> WeeklyReviewSummary {
        WeeklyReviewSummary(
            focusMinutes: try ReviewAggregationStore.weekFocusMinutes(start: start, end: end, in: modelContext),
            completedTaskCount: try ReviewAggregationStore.weekCompletedTaskCount(start: start, end: end, in: modelContext),
            mistakeCount: try ReviewAggregationStore.weekMistakeCount(start: start, end: end, in: modelContext),
            subjectBreakdownText: try ReviewAggregationStore.weekSubjectBreakdownText(start: start, end: end, in: modelContext),
            mistakeTypeBreakdownText: try ReviewAggregationStore.weekMistakeTypeBreakdownText(start: start, end: end, in: modelContext)
        )
    }

    private func saveDailyReview() {
        guard let review = dailyReview else {
            statusMessage = "保存失败：每日复盘尚未加载。"
            return
        }

        do {
            review.completedSummary = clean(completedSummary)
            review.unfinishedSummary = clean(unfinishedSummary)
            review.biggestProblem = clean(biggestProblem)
            review.bestMistakeId = bestMistakeId
            review.stateScoreEnd = stateScoreEnd
            review.tomorrowFirstAction = clean(tomorrowFirstAction)
            DailyReviewStore.updateDailyReviewTimestamp(review)

            let dayPlan = try DayPlanStore.fetchOrCreateToday(in: modelContext)
            dayPlan.tomorrowFirstAction = review.tomorrowFirstAction
            DayPlanStore.updateDayPlanTimestamp(dayPlan)

            try modelContext.save()
            statusMessage = "已保存每日复盘，并同步明日第一步。"
        } catch {
            statusMessage = "保存每日复盘失败：\(error.localizedDescription)"
        }
    }

    private func saveWeeklyReview() {
        guard let review = weeklyReview else {
            statusMessage = "保存失败：周复盘尚未加载。"
            return
        }

        do {
            review.totalStudyMinutes = weeklySummary.focusMinutes
            review.subjectBreakdownText = weeklySummary.subjectBreakdownText
            review.completedTaskCount = weeklySummary.completedTaskCount
            review.mistakeCount = weeklySummary.mistakeCount
            review.mistakeTypeBreakdownText = weeklySummary.mistakeTypeBreakdownText
            review.keyProblemsText = clean(keyProblemsText)
            review.nextWeekFocusText = clean(nextWeekFocusText)
            WeeklyReviewStore.updateWeeklyReviewTimestamp(review)

            try modelContext.save()
            statusMessage = "已保存周复盘。"
        } catch {
            statusMessage = "保存周复盘失败：\(error.localizedDescription)"
        }
    }

    private func generateDailyPrompt() {
        do {
            guard let template = try PromptTemplateStore.fetchTemplate(title: "每日复盘", in: modelContext) else {
                statusMessage = "找不到内置“每日复盘”模板。请检查 Prompt seed 是否成功。"
                return
            }

            activePromptSheet = ReviewPromptSheet(
                template: template,
                values: dailyPromptValues()
            )
        } catch {
            statusMessage = "加载每日复盘 Prompt 失败：\(error.localizedDescription)"
        }
    }

    private func generateWeeklyPrompt() {
        do {
            guard let template = try PromptTemplateStore.fetchTemplate(title: "周复盘", in: modelContext) else {
                statusMessage = "找不到内置“周复盘”模板。请检查 Prompt seed 是否成功。"
                return
            }

            activePromptSheet = ReviewPromptSheet(
                template: template,
                values: weeklyPromptValues()
            )
        } catch {
            statusMessage = "加载周复盘 Prompt 失败：\(error.localizedDescription)"
        }
    }

    private func dailyPromptValues() -> [String: String] {
        [
            "date": Self.dayFormatter.string(from: todayDate),
            "completedTasks": promptText(
                completedSummary,
                fallback: "已完成 \(dailySummary.completedTaskCount)/\(dailySummary.taskCount) 个任务"
            ),
            "unfinishedTasks": promptText(
                unfinishedSummary,
                fallback: dailySummary.taskCount == dailySummary.completedTaskCount ? "今日任务已完成" : "未完成 \(dailySummary.taskCount - dailySummary.completedTaskCount) 个任务"
            ),
            "focusSummary": "\(dailySummary.focusMinutes) 分钟，\(dailySummary.focusSessionCount) 次专注",
            "mistakeSummary": dailyMistakeSummaryText(),
            "stateScoreEnd": "\(stateScoreEnd)/10"
        ]
    }

    private func weeklyPromptValues() -> [String: String] {
        [
            "weekRange": "\(Self.shortDateFormatter.string(from: currentWeekStart)) - \(Self.shortDateFormatter.string(from: currentWeekEnd))",
            "totalStudyMinutes": "\(weeklySummary.focusMinutes)",
            "subjectBreakdown": weeklySummary.subjectBreakdownText,
            "completedTaskCount": "\(weeklySummary.completedTaskCount)",
            "mistakeTypeBreakdown": weeklySummary.mistakeTypeBreakdownText,
            "keyDailyProblems": weeklyProblemSummaryText()
        ]
    }

    private func dailyMistakeSummaryText() -> String {
        let base = "\(dailySummary.mistakeCount) 条错题"

        guard
            let bestMistakeId,
            let mistake = todayMistakes.first(where: { $0.id == bestMistakeId })
        else {
            return base
        }

        return "\(base)\n最佳错题：\(mistake.displayTitle)"
    }

    private func weeklyProblemSummaryText() -> String {
        do {
            let range = DateKey.key(for: currentWeekStart)...DateKey.key(for: currentWeekEnd)
            let descriptor = FetchDescriptor<DailyReview>(
                sortBy: [SortDescriptor(\.dayKey, order: .forward)]
            )

            let problems = try modelContext.fetch(descriptor)
                .filter { range.contains($0.dayKey) }
                .compactMap { review -> String? in
                    let problem = clean(review.biggestProblem)
                    return problem.isEmpty ? nil : "\(review.dayKey)：\(problem)"
                }

            if !problems.isEmpty {
                return problems.joined(separator: "\n")
            }
        } catch {
            return promptText(keyProblemsText, fallback: "每日关键问题读取失败：\(error.localizedDescription)")
        }

        return promptText(keyProblemsText, fallback: "暂无每日关键问题")
    }

    private func fetchMistakes(for dayKey: String) throws -> [MistakeRecord] {
        let descriptor = FetchDescriptor<MistakeRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        return try modelContext.fetch(descriptor).filter { mistake in
            DateKey.key(for: mistake.createdAt) == dayKey
        }
    }

    private func clean(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func promptText(_ value: String, fallback: String) -> String {
        let trimmed = clean(value)
        return trimmed.isEmpty ? fallback : trimmed
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()
}

private enum ReviewLoadState: Equatable {
    case loading
    case loaded
    case failed(String)
}

private enum ReviewMode: String, CaseIterable, Identifiable {
    case daily
    case weekly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily:
            return "每日复盘"
        case .weekly:
            return "周复盘"
        }
    }
}

private struct ReviewPromptSheet: Identifiable {
    let id = UUID()
    let template: PromptTemplate
    let values: [String: String]
}

private struct DailyReviewSummary {
    let taskCount: Int
    let completedTaskCount: Int
    let focusMinutes: Int
    let focusSessionCount: Int
    let mistakeCount: Int

    static let empty = DailyReviewSummary(
        taskCount: 0,
        completedTaskCount: 0,
        focusMinutes: 0,
        focusSessionCount: 0,
        mistakeCount: 0
    )
}

private struct WeeklyReviewSummary {
    let focusMinutes: Int
    let completedTaskCount: Int
    let mistakeCount: Int
    let subjectBreakdownText: String
    let mistakeTypeBreakdownText: String

    static let empty = WeeklyReviewSummary(
        focusMinutes: 0,
        completedTaskCount: 0,
        mistakeCount: 0,
        subjectBreakdownText: "暂无科目记录",
        mistakeTypeBreakdownText: "暂无错题类型记录"
    )
}

private struct ReviewHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("复盘")
                .font(.largeTitle.bold())

            Text("今天收束，明天继续")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct DailyReviewSection: View {
    let date: Date
    let summary: DailyReviewSummary
    let todayMistakes: [MistakeRecord]
    @Binding var completedSummary: String
    @Binding var unfinishedSummary: String
    @Binding var biggestProblem: String
    @Binding var bestMistakeId: UUID?
    @Binding var stateScoreEnd: Int
    @Binding var tomorrowFirstAction: String
    let onSave: () -> Void
    let onGeneratePrompt: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ReviewCard {
                VStack(alignment: .leading, spacing: 14) {
                    ReviewSectionTitle(title: "今日摘要", systemImage: "calendar")

                    ReviewStatsGrid(
                        stats: [
                            ReviewStat(title: "今日任务", value: "\(summary.taskCount)"),
                            ReviewStat(title: "已完成", value: "\(summary.completedTaskCount)", tint: .green),
                            ReviewStat(title: "专注分钟", value: "\(summary.focusMinutes)", tint: .blue),
                            ReviewStat(title: "专注次数", value: "\(summary.focusSessionCount)"),
                            ReviewStat(title: "今日错题", value: "\(summary.mistakeCount)", tint: .orange)
                        ]
                    )
                }
            }

            ReviewCard {
                VStack(alignment: .leading, spacing: 16) {
                    ReviewSectionTitle(title: "每日复盘", systemImage: "square.and.pencil")

                    ReviewTextEditor(
                        title: "今日完成",
                        placeholder: "今天真正完成了什么",
                        text: $completedSummary
                    )

                    ReviewTextEditor(
                        title: "未完成与原因",
                        placeholder: "没完成什么，原因是什么",
                        text: $unfinishedSummary
                    )

                    ReviewTextEditor(
                        title: "最大问题",
                        placeholder: "今天最值得处理的问题",
                        text: $biggestProblem
                    )

                    BestMistakePicker(
                        mistakes: todayMistakes,
                        selectedMistakeId: $bestMistakeId
                    )

                    Stepper(value: $stateScoreEnd, in: 1...10) {
                        HStack {
                            Text("晚间状态评分")
                            Spacer()
                            Text("\(stateScoreEnd)/10")
                                .font(.headline.monospacedDigit())
                        }
                    }
                    .accessibilityLabel("晚间状态评分")
                    .accessibilityValue("\(stateScoreEnd) 分")

                    ReviewTextEditor(
                        title: "明日第一步",
                        placeholder: "明天打开 App 后第一件事",
                        text: $tomorrowFirstAction,
                        minHeight: 70
                    )
                }
            }

            ReviewActionButtons(
                saveTitle: "保存每日复盘",
                promptTitle: "生成每日复盘 Prompt",
                onSave: onSave,
                onGeneratePrompt: onGeneratePrompt
            )
        }
    }
}

private struct WeeklyReviewSection: View {
    let weekStart: Date
    let weekEnd: Date
    let summary: WeeklyReviewSummary
    @Binding var keyProblemsText: String
    @Binding var nextWeekFocusText: String
    let onSave: () -> Void
    let onGeneratePrompt: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ReviewCard {
                VStack(alignment: .leading, spacing: 14) {
                    ReviewSectionTitle(title: "本周摘要", systemImage: "chart.bar.xaxis")

                    Text("\(Self.formatter.string(from: weekStart)) - \(Self.formatter.string(from: weekEnd))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ReviewStatsGrid(
                        stats: [
                            ReviewStat(title: "专注分钟", value: "\(summary.focusMinutes)", tint: .blue),
                            ReviewStat(title: "完成任务", value: "\(summary.completedTaskCount)", tint: .green),
                            ReviewStat(title: "错题数量", value: "\(summary.mistakeCount)", tint: .orange)
                        ]
                    )

                    ReviewBreakdownBlock(
                        title: "科目分布",
                        text: summary.subjectBreakdownText
                    )

                    ReviewBreakdownBlock(
                        title: "错题类型分布",
                        text: summary.mistakeTypeBreakdownText
                    )
                }
            }

            ReviewCard {
                VStack(alignment: .leading, spacing: 16) {
                    ReviewSectionTitle(title: "周复盘", systemImage: "list.bullet.clipboard")

                    ReviewTextEditor(
                        title: "本周关键问题",
                        placeholder: "本周真正反复出现的问题",
                        text: $keyProblemsText
                    )

                    ReviewTextEditor(
                        title: "下周重点",
                        placeholder: "下周最多抓住的重点",
                        text: $nextWeekFocusText
                    )
                }
            }

            ReviewActionButtons(
                saveTitle: "保存周复盘",
                promptTitle: "生成周复盘 Prompt",
                onSave: onSave,
                onGeneratePrompt: onGeneratePrompt
            )
        }
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()
}

private struct BestMistakePicker: View {
    let mistakes: [MistakeRecord]
    @Binding var selectedMistakeId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("最佳错题")
                .font(.subheadline.weight(.semibold))

            if mistakes.isEmpty {
                Text("今天暂无可选错题。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Picker("最佳错题", selection: $selectedMistakeId) {
                    Text("暂不选择").tag(UUID?.none)
                    ForEach(mistakes, id: \.id) { mistake in
                        Text(mistake.displayTitle).tag(Optional(mistake.id))
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("最佳错题")
            }
        }
    }
}

private struct ReviewActionButtons: View {
    let saveTitle: String
    let promptTitle: String
    let onSave: () -> Void
    let onGeneratePrompt: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button {
                onSave()
            } label: {
                Label(saveTitle, systemImage: "tray.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                onGeneratePrompt()
            } label: {
                Label(promptTitle, systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct ReviewStatsGrid: View {
    let stats: [ReviewStat]

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(stats) { stat in
                ReviewStatTile(stat: stat)
            }
        }
    }
}

private struct ReviewStat: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    var tint: Color = .primary
}

private struct ReviewStatTile: View {
    let stat: ReviewStat

    var body: some View {
        VStack(spacing: 4) {
            Text(stat.value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(stat.tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(stat.title)
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

private struct ReviewTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 96

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))

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

private struct ReviewBreakdownBlock: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(text.isEmpty ? "暂无记录" : text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .textSelection(.enabled)
        }
    }
}

private struct ReviewCard<Content: View>: View {
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

private struct ReviewSectionTitle: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
    }
}

private extension MistakeRecord {
    var displayTitle: String {
        let subjectText = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let sourceText = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let chapterText = chapter.trimmingCharacters(in: .whitespacesAndNewlines)
        let typeText = mistakeType.trimmingCharacters(in: .whitespacesAndNewlines)

        let headline = [subjectText, chapterText, typeText]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")

        if !sourceText.isEmpty {
            return headline.isEmpty ? sourceText : "\(headline) · \(sourceText)"
        }

        return headline.isEmpty ? "未命名错题" : headline
    }
}

#Preview {
    NavigationStack {
        ReviewView()
    }
    .modelContainer(try! AppModelContainerFactory.make(inMemory: true))
}
