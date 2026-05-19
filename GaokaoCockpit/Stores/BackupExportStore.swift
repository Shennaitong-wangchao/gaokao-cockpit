import Foundation
import SwiftData

struct GaokaoBackupEnvelope: Codable {
    let appName: String
    let appVersion: String
    let exportVersion: Int
    let exportedAt: Date
    let notes: String
    let dayPlans: [DayPlanSnapshot]
    let studyTasks: [StudyTaskSnapshot]
    let focusSessions: [FocusSessionSnapshot]
    let mistakeRecords: [MistakeRecordSnapshot]
    let promptTemplates: [PromptTemplateSnapshot]
    let resourceItems: [ResourceItemSnapshot]
    let dailyReviews: [DailyReviewSnapshot]
    let weeklyReviews: [WeeklyReviewSnapshot]
    let mistakeImages: [MistakeImageSnapshot]
}

struct DayPlanSnapshot: Codable {
    let id: UUID
    let dayKey: String
    let date: Date
    let wakeTime: Date?
    let stateScore: Int?
    let mainSubject: String
    let topTasksText: String
    let baselineTasksText: String
    let bonusTasksText: String
    let tomorrowFirstAction: String
    let createdAt: Date
    let updatedAt: Date

    init(_ dayPlan: DayPlan) {
        id = dayPlan.id
        dayKey = dayPlan.dayKey
        date = dayPlan.date
        wakeTime = dayPlan.wakeTime
        stateScore = dayPlan.stateScore
        mainSubject = dayPlan.mainSubject
        topTasksText = dayPlan.topTasksText
        baselineTasksText = dayPlan.baselineTasksText
        bonusTasksText = dayPlan.bonusTasksText
        tomorrowFirstAction = dayPlan.tomorrowFirstAction
        createdAt = dayPlan.createdAt
        updatedAt = dayPlan.updatedAt
    }
}

struct StudyTaskSnapshot: Codable {
    let id: UUID
    let dayPlanId: UUID?
    let dayKey: String
    let title: String
    let subject: String
    let category: String
    let estimatedMinutes: Int?
    let actualMinutes: Int?
    let status: String
    let outputNote: String
    let createdAt: Date
    let updatedAt: Date

    init(_ task: StudyTask) {
        id = task.id
        dayPlanId = task.dayPlanId
        dayKey = task.dayKey
        title = task.title
        subject = task.subject
        category = task.category
        estimatedMinutes = task.estimatedMinutes
        actualMinutes = task.actualMinutes
        status = task.status
        outputNote = task.outputNote
        createdAt = task.createdAt
        updatedAt = task.updatedAt
    }
}

struct FocusSessionSnapshot: Codable {
    let id: UUID
    let taskId: UUID?
    let dayKey: String
    let subject: String
    let startTime: Date
    let endTime: Date?
    let plannedMinutes: Int
    let actualMinutes: Int?
    let distractionCount: Int
    let completionScore: Int?
    let sessionNote: String
    let nextAction: String
    let createdAt: Date

    init(_ session: FocusSession) {
        id = session.id
        taskId = session.taskId
        dayKey = session.dayKey
        subject = session.subject
        startTime = session.startTime
        endTime = session.endTime
        plannedMinutes = session.plannedMinutes
        actualMinutes = session.actualMinutes
        distractionCount = session.distractionCount
        completionScore = session.completionScore
        sessionNote = session.sessionNote
        nextAction = session.nextAction
        createdAt = session.createdAt
    }
}

struct MistakeRecordSnapshot: Codable {
    let id: UUID
    let subject: String
    let chapter: String
    let source: String
    let questionText: String
    let questionImagePath: String
    let mySolution: String
    let correctSolution: String
    let mistakeType: String
    let rootCause: String
    let questionSignal: String
    let correctModel: String
    let variantTask: String
    let nextReminder: Date?
    let reviewStatus: String
    let createdAt: Date
    let updatedAt: Date

    init(_ mistake: MistakeRecord) {
        id = mistake.id
        subject = mistake.subject
        chapter = mistake.chapter
        source = mistake.source
        questionText = mistake.questionText
        questionImagePath = mistake.questionImagePath
        mySolution = mistake.mySolution
        correctSolution = mistake.correctSolution
        mistakeType = mistake.mistakeType
        rootCause = mistake.rootCause
        questionSignal = mistake.questionSignal
        correctModel = mistake.correctModel
        variantTask = mistake.variantTask
        nextReminder = mistake.nextReminder
        reviewStatus = mistake.reviewStatus
        createdAt = mistake.createdAt
        updatedAt = mistake.updatedAt
    }
}

struct PromptTemplateSnapshot: Codable {
    let id: UUID
    let title: String
    let category: String
    let templateDescription: String
    let templateText: String
    let variablesText: String
    let usageCount: Int
    let isBuiltIn: Bool
    let createdAt: Date
    let updatedAt: Date

    init(_ template: PromptTemplate) {
        id = template.id
        title = template.title
        category = template.category
        templateDescription = template.templateDescription
        templateText = template.templateText
        variablesText = template.variablesText
        usageCount = template.usageCount
        isBuiltIn = template.isBuiltIn
        createdAt = template.createdAt
        updatedAt = template.updatedAt
    }
}

struct ResourceItemSnapshot: Codable {
    let id: UUID
    let title: String
    let subject: String
    let chapter: String
    let type: String
    let uri: String
    let status: String
    let note: String
    let createdAt: Date
    let updatedAt: Date

    init(_ item: ResourceItem) {
        id = item.id
        title = item.title
        subject = item.subject
        chapter = item.chapter
        type = item.type
        uri = item.uri
        status = item.status
        note = item.note
        createdAt = item.createdAt
        updatedAt = item.updatedAt
    }
}

struct DailyReviewSnapshot: Codable {
    let id: UUID
    let dayKey: String
    let date: Date
    let completedSummary: String
    let unfinishedSummary: String
    let biggestProblem: String
    let bestMistakeId: UUID?
    let stateScoreEnd: Int?
    let tomorrowFirstAction: String
    let createdAt: Date
    let updatedAt: Date

    init(_ review: DailyReview) {
        id = review.id
        dayKey = review.dayKey
        date = review.date
        completedSummary = review.completedSummary
        unfinishedSummary = review.unfinishedSummary
        biggestProblem = review.biggestProblem
        bestMistakeId = review.bestMistakeId
        stateScoreEnd = review.stateScoreEnd
        tomorrowFirstAction = review.tomorrowFirstAction
        createdAt = review.createdAt
        updatedAt = review.updatedAt
    }
}

struct WeeklyReviewSnapshot: Codable {
    let id: UUID
    let weekStartKey: String
    let weekEndKey: String
    let weekStartDate: Date
    let weekEndDate: Date
    let totalStudyMinutes: Int
    let subjectBreakdownText: String
    let completedTaskCount: Int
    let mistakeCount: Int
    let mistakeTypeBreakdownText: String
    let keyProblemsText: String
    let nextWeekFocusText: String
    let createdAt: Date
    let updatedAt: Date

    init(_ review: WeeklyReview) {
        id = review.id
        weekStartKey = review.weekStartKey
        weekEndKey = review.weekEndKey
        weekStartDate = review.weekStartDate
        weekEndDate = review.weekEndDate
        totalStudyMinutes = review.totalStudyMinutes
        subjectBreakdownText = review.subjectBreakdownText
        completedTaskCount = review.completedTaskCount
        mistakeCount = review.mistakeCount
        mistakeTypeBreakdownText = review.mistakeTypeBreakdownText
        keyProblemsText = review.keyProblemsText
        nextWeekFocusText = review.nextWeekFocusText
        createdAt = review.createdAt
        updatedAt = review.updatedAt
    }
}

struct MistakeImageSnapshot: Codable {
    let relativePath: String
    let fileName: String
    let base64JPEG: String
    let byteCount: Int
}

struct GaokaoBackupResult {
    let fileURL: URL
    let exportedRecordCounts: [String: Int]
    let warnings: [String]
}

enum BackupExportStore {
    static func exportAllData(in context: ModelContext) throws -> GaokaoBackupResult {
        let dayPlans = try context.fetch(FetchDescriptor<DayPlan>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        ))
        let studyTasks = try context.fetch(FetchDescriptor<StudyTask>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        ))
        let focusSessions = try context.fetch(FetchDescriptor<FocusSession>(
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        ))
        let mistakeRecords = try context.fetch(FetchDescriptor<MistakeRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        ))
        let promptTemplates = try context.fetch(FetchDescriptor<PromptTemplate>(
            sortBy: [
                SortDescriptor(\.category, order: .forward),
                SortDescriptor(\.title, order: .forward)
            ]
        ))
        let resourceItems = try context.fetch(FetchDescriptor<ResourceItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        ))
        let dailyReviews = try context.fetch(FetchDescriptor<DailyReview>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        ))
        let weeklyReviews = try context.fetch(FetchDescriptor<WeeklyReview>(
            sortBy: [SortDescriptor(\.weekStartDate, order: .forward)]
        ))
        let imageExport = makeMistakeImageSnapshots(from: mistakeRecords)
        let exportedAt = Date()
        let envelope = GaokaoBackupEnvelope(
            appName: "Gaokao Cockpit",
            appVersion: appVersionText,
            exportVersion: 1,
            exportedAt: exportedAt,
            notes: "Local JSON backup export. Import/restore is not supported in this MVP.",
            dayPlans: dayPlans.map(DayPlanSnapshot.init),
            studyTasks: studyTasks.map(StudyTaskSnapshot.init),
            focusSessions: focusSessions.map(FocusSessionSnapshot.init),
            mistakeRecords: mistakeRecords.map(MistakeRecordSnapshot.init),
            promptTemplates: promptTemplates.map(PromptTemplateSnapshot.init),
            resourceItems: resourceItems.map(ResourceItemSnapshot.init),
            dailyReviews: dailyReviews.map(DailyReviewSnapshot.init),
            weeklyReviews: weeklyReviews.map(WeeklyReviewSnapshot.init),
            mistakeImages: imageExport.snapshots
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(envelope)
        let fileURL = exportDirectory().appendingPathComponent(makeExportFileName(date: exportedAt))
        try data.write(to: fileURL, options: [.atomic])

        return GaokaoBackupResult(
            fileURL: fileURL,
            exportedRecordCounts: [
                "dayPlans": envelope.dayPlans.count,
                "studyTasks": envelope.studyTasks.count,
                "focusSessions": envelope.focusSessions.count,
                "mistakeRecords": envelope.mistakeRecords.count,
                "promptTemplates": envelope.promptTemplates.count,
                "resourceItems": envelope.resourceItems.count,
                "dailyReviews": envelope.dailyReviews.count,
                "weeklyReviews": envelope.weeklyReviews.count,
                "mistakeImages": envelope.mistakeImages.count
            ],
            warnings: imageExport.warnings
        )
    }

    static func makeExportFileName(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "gaokao-cockpit-backup-\(formatter.string(from: date)).json"
    }

    private static func makeMistakeImageSnapshots(
        from mistakeRecords: [MistakeRecord]
    ) -> (snapshots: [MistakeImageSnapshot], warnings: [String]) {
        var snapshots: [MistakeImageSnapshot] = []
        var warnings: [String] = []
        var exportedPaths = Set<String>()

        for mistake in mistakeRecords {
            let relativePath = mistake.questionImagePath.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !relativePath.isEmpty else {
                continue
            }
            guard exportedPaths.insert(relativePath).inserted else {
                continue
            }

            guard let imageURL = MistakeImageStore.imageURL(path: relativePath) else {
                warnings.append("题图路径无效：\(relativePath)")
                continue
            }

            do {
                let data = try Data(contentsOf: imageURL)
                snapshots.append(
                    MistakeImageSnapshot(
                        relativePath: relativePath,
                        fileName: imageURL.lastPathComponent,
                        base64JPEG: data.base64EncodedString(),
                        byteCount: data.count
                    )
                )
            } catch {
                warnings.append("题图读取失败：\(relativePath)（\(error.localizedDescription)）")
            }
        }

        return (snapshots, warnings)
    }

    private static var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"

        if build == "unknown" {
            return version
        }

        return "\(version) (\(build))"
    }

    private static func exportDirectory() -> URL {
        let fileManager = FileManager.default
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            return documentsURL
        }

        return fileManager.temporaryDirectory
    }
}
