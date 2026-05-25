import SwiftData
import SwiftUI

@Observable
final class ReviewModel {
    var loadState: ReviewLoadState = .loading
    var selectedMode: ReviewMode = .daily
    var statusMessage: String?

    var todayKey = DateKey.todayKey()
    var todayDate = Date()
    var currentWeekStart = DateKey.weekStart(for: Date())
    var currentWeekEnd = DateKey.weekEnd(for: Date())

    var dailyReview: DailyReview?
    var dailySummary = DailyReviewSummary.empty
    var todayMistakes: [MistakeRecord] = []
    var completedSummary = ""
    var unfinishedSummary = ""
    var biggestProblem = ""
    var bestMistakeId: UUID?
    var stateScoreEnd = 6
    var tomorrowFirstAction = ""

    var weeklyReview: WeeklyReview?
    var weeklySummary = WeeklyReviewSummary.empty
    var keyProblemsText = ""
    var nextWeekFocusText = ""

    var activePromptSheet: ReviewPromptSheet?
    var activeBackupSheet: ReviewBackupSheet?

    func loadReviews(in context: ModelContext) {
        loadState = .loading
        statusMessage = nil

        do {
            let review = try DailyReviewStore.fetchOrCreateTodayReview(in: context)
            let weekReview = try WeeklyReviewStore.fetchOrCreateCurrentWeekReview(in: context)

            todayKey = review.dayKey
            todayDate = review.date
            dailyReview = review

            currentWeekStart = weekReview.weekStartDate
            currentWeekEnd = weekReview.weekEndDate
            weeklyReview = weekReview

            todayMistakes = try fetchMistakes(in: context, for: review.dayKey)
            applyDailyReview(review)
            applyWeeklyReview(weekReview)

            var warnings: [String] = []
            do {
                dailySummary = try makeDailySummary(in: context, dayKey: review.dayKey)
            } catch {
                dailySummary = .empty
                warnings.append("今日汇总失败：\(error.localizedDescription)")
            }

            do {
                weeklySummary = try makeWeeklySummary(in: context, start: weekReview.weekStartDate, end: weekReview.weekEndDate)
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

    func saveDailyReview(in context: ModelContext) {
        guard let review = dailyReview else {
            statusMessage = "保存失败：每日复盘尚未加载。"
            HapticFeedback.error()
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

            let dayPlan = try DayPlanStore.fetchOrCreateToday(in: context)
            dayPlan.tomorrowFirstAction = review.tomorrowFirstAction
            DayPlanStore.updateDayPlanTimestamp(dayPlan)

            try context.save()
            statusMessage = "复盘已保存，明日第一步已回流到 Today。"
            HapticFeedback.success()
            ToastManager.shared.show(message: "复盘已保存", style: .success)
        } catch {
            statusMessage = "保存每日复盘失败：\(error.localizedDescription)"
            HapticFeedback.error()
            ToastManager.shared.show(message: "保存复盘失败", style: .error)
        }
    }

    func applyDailyQuickTemplate() {
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
        HapticFeedback.lightImpact()
    }

    func saveWeeklyReview(in context: ModelContext) {
        guard let review = weeklyReview else {
            statusMessage = "保存失败：周复盘尚未加载。"
            HapticFeedback.error()
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

            try context.save()
            statusMessage = "已保存周复盘。"
            HapticFeedback.success()
            ToastManager.shared.show(message: "周复盘已保存", style: .success)
        } catch {
            statusMessage = "保存周复盘失败：\(error.localizedDescription)"
            HapticFeedback.error()
            ToastManager.shared.show(message: "保存周复盘失败", style: .error)
        }
    }

    func generateDailyPrompt(in context: ModelContext) {
        do {
            guard let template = try PromptTemplateStore.fetchTemplate(title: "每日复盘", in: context) else {
                statusMessage = "找不到内置\"每日复盘\"模板。请检查 Prompt seed 是否成功。"
                HapticFeedback.error()
                return
            }

            activePromptSheet = ReviewPromptSheet(
                template: template,
                values: dailyPromptValues()
            )
        } catch {
            statusMessage = "加载每日复盘 Prompt 失败：\(error.localizedDescription)"
            HapticFeedback.error()
        }
    }

    func generateWeeklyPrompt(in context: ModelContext) {
        do {
            guard let template = try PromptTemplateStore.fetchTemplate(title: "周复盘", in: context) else {
                statusMessage = "找不到内置\"周复盘\"模板。请检查 Prompt seed 是否成功。"
                HapticFeedback.error()
                return
            }

            activePromptSheet = ReviewPromptSheet(
                template: template,
                values: weeklyPromptValues(in: context)
            )
        } catch {
            statusMessage = "加载周复盘 Prompt 失败：\(error.localizedDescription)"
            HapticFeedback.error()
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

    private func makeDailySummary(in context: ModelContext, dayKey: String) throws -> DailyReviewSummary {
        DailyReviewSummary(
            taskCount: try ReviewAggregationStore.todayTaskCount(dayKey: dayKey, in: context),
            completedTaskCount: try ReviewAggregationStore.todayCompletedTaskCount(dayKey: dayKey, in: context),
            focusMinutes: try ReviewAggregationStore.todayFocusMinutes(dayKey: dayKey, in: context),
            focusSessionCount: try ReviewAggregationStore.todayFocusSessionCount(dayKey: dayKey, in: context),
            mistakeCount: try ReviewAggregationStore.todayMistakeCount(dayKey: dayKey, in: context)
        )
    }

    private func makeWeeklySummary(in context: ModelContext, start: Date, end: Date) throws -> WeeklyReviewSummary {
        WeeklyReviewSummary(
            focusMinutes: try ReviewAggregationStore.weekFocusMinutes(start: start, end: end, in: context),
            completedTaskCount: try ReviewAggregationStore.weekCompletedTaskCount(start: start, end: end, in: context),
            mistakeCount: try ReviewAggregationStore.weekMistakeCount(start: start, end: end, in: context),
            subjectBreakdownText: try ReviewAggregationStore.weekSubjectBreakdownText(start: start, end: end, in: context),
            mistakeTypeBreakdownText: try ReviewAggregationStore.weekMistakeTypeBreakdownText(start: start, end: end, in: context)
        )
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

    private func weeklyPromptValues(in context: ModelContext) -> [String: String] {
        [
            "weekRange": "\(Self.shortDateFormatter.string(from: currentWeekStart)) - \(Self.shortDateFormatter.string(from: currentWeekEnd))",
            "totalStudyMinutes": "\(weeklySummary.focusMinutes)",
            "subjectBreakdown": weeklySummary.subjectBreakdownText,
            "completedTaskCount": "\(weeklySummary.completedTaskCount)",
            "mistakeTypeBreakdown": weeklySummary.mistakeTypeBreakdownText,
            "keyDailyProblems": weeklyProblemSummaryText(in: context)
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

    private func weeklyProblemSummaryText(in context: ModelContext) -> String {
        do {
            let startKey = DateKey.key(for: currentWeekStart)
            let endKey = DateKey.key(for: currentWeekEnd)
            let descriptor = FetchDescriptor<DailyReview>(
                predicate: #Predicate<DailyReview> { review in
                    review.dayKey >= startKey && review.dayKey <= endKey
                },
                sortBy: [SortDescriptor(\.dayKey, order: .forward)]
            )

            let problems = try context.fetch(descriptor)
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

    private func fetchMistakes(in context: ModelContext, for dayKey: String) throws -> [MistakeRecord] {
        guard let interval = DateKey.dateInterval(forKey: dayKey) else {
            return []
        }

        let start = interval.start
        let end = interval.end
        let descriptor = FetchDescriptor<MistakeRecord>(
            predicate: #Predicate<MistakeRecord> { mistake in
                mistake.createdAt >= start && mistake.createdAt < end
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        return try context.fetch(descriptor)
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
        formatter.timeZone = AppDateTime.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = AppDateTime.timeZone
        formatter.dateFormat = "M月d日"
        return formatter
    }()
}
