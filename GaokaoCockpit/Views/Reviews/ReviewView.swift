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
    @State private var activeBackupSheet: ReviewBackupSheet?

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
                                onApplyQuickTemplate: applyDailyQuickTemplate,
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
                                .foregroundStyle(statusMessage.contains("失败") ? Color.red : Color.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        ReviewBackupEntryCard {
                            activeBackupSheet = ReviewBackupSheet()
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
        .sheet(item: $activeBackupSheet) { _ in
            BackupExportView()
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
            statusMessage = "复盘已保存，明日第一步已回流到 Today。"
        } catch {
            statusMessage = "保存每日复盘失败：\(error.localizedDescription)"
        }
    }

    private func applyDailyQuickTemplate() {
        if clean(completedSummary).isEmpty {
            completedSummary = "完成了主要学习任务，记录了任务与专注情况。"
        }

        if clean(unfinishedSummary).isEmpty {
            unfinishedSummary = "未完成内容待补充。"
        }

        if clean(biggestProblem).isEmpty {
            biggestProblem = "今日最大问题待总结。"
        }

        if clean(tomorrowFirstAction).isEmpty {
            tomorrowFirstAction = "打开 Today，先完成一个保底任务。"
        }

        statusMessage = "已填入空白复盘字段。"
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

private struct ReviewBackupSheet: Identifiable {
    let id = UUID()
}

#Preview {
    NavigationStack {
        ReviewView()
    }
    .modelContainer(try! AppModelContainerFactory.make(inMemory: true))
}
