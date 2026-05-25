import CryptoKit
import Foundation
import SwiftData

enum GaokaoBackupFormat {
    static let schemaName = "GaokaoCockpitBackup"
    static let exportVersion = 1
    static let exportSchemaVersion = 1
}

struct BackupRecordSummary: Codable, Equatable {
    let dayPlanCount: Int
    let studyTaskCount: Int
    let focusSessionCount: Int
    let mistakeRecordCount: Int
    let promptTemplateCount: Int
    let resourceItemCount: Int
    let dailyReviewCount: Int
    let weeklyReviewCount: Int
    let mistakeImageCount: Int

    var countDictionary: [String: Int] {
        [
            "dayPlans": dayPlanCount,
            "studyTasks": studyTaskCount,
            "focusSessions": focusSessionCount,
            "mistakeRecords": mistakeRecordCount,
            "promptTemplates": promptTemplateCount,
            "resourceItems": resourceItemCount,
            "dailyReviews": dailyReviewCount,
            "weeklyReviews": weeklyReviewCount,
            "mistakeImages": mistakeImageCount
        ]
    }
}

struct BackupIntegritySummary: Codable, Equatable {
    let jsonPayloadSHA256: String
    let payloadWithoutChecksumSHA256: String
    let imageTotalBytes: Int
    let missingImageCount: Int
    let warningCount: Int

    var displayChecksum: String {
        if !payloadWithoutChecksumSHA256.isEmpty {
            return payloadWithoutChecksumSHA256
        }

        return jsonPayloadSHA256
    }

    init(
        jsonPayloadSHA256: String,
        payloadWithoutChecksumSHA256: String,
        imageTotalBytes: Int,
        missingImageCount: Int,
        warningCount: Int
    ) {
        self.jsonPayloadSHA256 = jsonPayloadSHA256
        self.payloadWithoutChecksumSHA256 = payloadWithoutChecksumSHA256
        self.imageTotalBytes = imageTotalBytes
        self.missingImageCount = missingImageCount
        self.warningCount = warningCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        jsonPayloadSHA256 = try container.decodeIfPresent(String.self, forKey: .jsonPayloadSHA256) ?? ""
        payloadWithoutChecksumSHA256 = try container.decodeIfPresent(
            String.self,
            forKey: .payloadWithoutChecksumSHA256
        ) ?? jsonPayloadSHA256
        imageTotalBytes = try container.decodeIfPresent(Int.self, forKey: .imageTotalBytes) ?? 0
        missingImageCount = try container.decodeIfPresent(Int.self, forKey: .missingImageCount) ?? 0
        warningCount = try container.decodeIfPresent(Int.self, forKey: .warningCount) ?? 0
    }

    func clearingChecksumFields() -> BackupIntegritySummary {
        BackupIntegritySummary(
            jsonPayloadSHA256: "",
            payloadWithoutChecksumSHA256: "",
            imageTotalBytes: imageTotalBytes,
            missingImageCount: missingImageCount,
            warningCount: warningCount
        )
    }

    func withPayloadChecksum(_ checksum: String) -> BackupIntegritySummary {
        BackupIntegritySummary(
            jsonPayloadSHA256: checksum,
            payloadWithoutChecksumSHA256: checksum,
            imageTotalBytes: imageTotalBytes,
            missingImageCount: missingImageCount,
            warningCount: warningCount
        )
    }
}

struct GaokaoBackupEnvelope: Codable {
    var appName: String
    var appVersion: String
    var exportVersion: Int
    var schemaName: String
    var exportSchemaVersion: Int
    var exportedAt: Date
    var notes: String
    var recordSummary: BackupRecordSummary
    var integrity: BackupIntegritySummary
    var warnings: [String]
    var dayPlans: [DayPlanSnapshot]
    var studyTasks: [StudyTaskSnapshot]
    var focusSessions: [FocusSessionSnapshot]
    var mistakeRecords: [MistakeRecordSnapshot]
    var promptTemplates: [PromptTemplateSnapshot]
    var resourceItems: [ResourceItemSnapshot]
    var dailyReviews: [DailyReviewSnapshot]
    var weeklyReviews: [WeeklyReviewSnapshot]
    var mistakeImages: [MistakeImageSnapshot]

    init(
        appName: String,
        appVersion: String,
        exportVersion: Int,
        schemaName: String,
        exportSchemaVersion: Int,
        exportedAt: Date,
        notes: String,
        recordSummary: BackupRecordSummary,
        integrity: BackupIntegritySummary,
        warnings: [String],
        dayPlans: [DayPlanSnapshot],
        studyTasks: [StudyTaskSnapshot],
        focusSessions: [FocusSessionSnapshot],
        mistakeRecords: [MistakeRecordSnapshot],
        promptTemplates: [PromptTemplateSnapshot],
        resourceItems: [ResourceItemSnapshot],
        dailyReviews: [DailyReviewSnapshot],
        weeklyReviews: [WeeklyReviewSnapshot],
        mistakeImages: [MistakeImageSnapshot]
    ) {
        self.appName = appName
        self.appVersion = appVersion
        self.exportVersion = exportVersion
        self.schemaName = schemaName
        self.exportSchemaVersion = exportSchemaVersion
        self.exportedAt = exportedAt
        self.notes = notes
        self.recordSummary = recordSummary
        self.integrity = integrity
        self.warnings = warnings
        self.dayPlans = dayPlans
        self.studyTasks = studyTasks
        self.focusSessions = focusSessions
        self.mistakeRecords = mistakeRecords
        self.promptTemplates = promptTemplates
        self.resourceItems = resourceItems
        self.dailyReviews = dailyReviews
        self.weeklyReviews = weeklyReviews
        self.mistakeImages = mistakeImages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        appName = try container.decode(String.self, forKey: .appName)
        appVersion = try container.decode(String.self, forKey: .appVersion)
        exportVersion = try container.decode(Int.self, forKey: .exportVersion)
        schemaName = try container.decodeIfPresent(String.self, forKey: .schemaName) ?? GaokaoBackupFormat.schemaName
        exportSchemaVersion = try container.decodeIfPresent(
            Int.self,
            forKey: .exportSchemaVersion
        ) ?? exportVersion
        exportedAt = try container.decode(Date.self, forKey: .exportedAt)
        notes = try container.decode(String.self, forKey: .notes)
        warnings = try container.decodeIfPresent([String].self, forKey: .warnings) ?? []
        dayPlans = try container.decode([DayPlanSnapshot].self, forKey: .dayPlans)
        studyTasks = try container.decode([StudyTaskSnapshot].self, forKey: .studyTasks)
        focusSessions = try container.decode([FocusSessionSnapshot].self, forKey: .focusSessions)
        mistakeRecords = try container.decode([MistakeRecordSnapshot].self, forKey: .mistakeRecords)
        promptTemplates = try container.decode([PromptTemplateSnapshot].self, forKey: .promptTemplates)
        resourceItems = try container.decode([ResourceItemSnapshot].self, forKey: .resourceItems)
        dailyReviews = try container.decode([DailyReviewSnapshot].self, forKey: .dailyReviews)
        weeklyReviews = try container.decode([WeeklyReviewSnapshot].self, forKey: .weeklyReviews)
        mistakeImages = try container.decode([MistakeImageSnapshot].self, forKey: .mistakeImages)

        let calculatedSummary = BackupRecordSummary(
            dayPlanCount: dayPlans.count,
            studyTaskCount: studyTasks.count,
            focusSessionCount: focusSessions.count,
            mistakeRecordCount: mistakeRecords.count,
            promptTemplateCount: promptTemplates.count,
            resourceItemCount: resourceItems.count,
            dailyReviewCount: dailyReviews.count,
            weeklyReviewCount: weeklyReviews.count,
            mistakeImageCount: mistakeImages.count
        )
        recordSummary = try container.decodeIfPresent(
            BackupRecordSummary.self,
            forKey: .recordSummary
        ) ?? calculatedSummary
        integrity = try container.decodeIfPresent(
            BackupIntegritySummary.self,
            forKey: .integrity
        ) ?? BackupIntegritySummary(
            jsonPayloadSHA256: "",
            payloadWithoutChecksumSHA256: "",
            imageTotalBytes: mistakeImages.reduce(0) { $0 + $1.byteCount },
            missingImageCount: 0,
            warningCount: warnings.count
        )
    }
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

extension BackupRecordSummary {
    init(envelope: GaokaoBackupEnvelope) {
        self.init(
            dayPlanCount: envelope.dayPlans.count,
            studyTaskCount: envelope.studyTasks.count,
            focusSessionCount: envelope.focusSessions.count,
            mistakeRecordCount: envelope.mistakeRecords.count,
            promptTemplateCount: envelope.promptTemplates.count,
            resourceItemCount: envelope.resourceItems.count,
            dailyReviewCount: envelope.dailyReviews.count,
            weeklyReviewCount: envelope.weeklyReviews.count,
            mistakeImageCount: envelope.mistakeImages.count
        )
    }

    func mismatches(comparedTo actual: BackupRecordSummary) -> [String] {
        var messages: [String] = []

        let labels: [(String, Int, Int)] = [
            ("dayPlanCount", dayPlanCount, actual.dayPlanCount),
            ("studyTaskCount", studyTaskCount, actual.studyTaskCount),
            ("focusSessionCount", focusSessionCount, actual.focusSessionCount),
            ("mistakeRecordCount", mistakeRecordCount, actual.mistakeRecordCount),
            ("promptTemplateCount", promptTemplateCount, actual.promptTemplateCount),
            ("resourceItemCount", resourceItemCount, actual.resourceItemCount),
            ("dailyReviewCount", dailyReviewCount, actual.dailyReviewCount),
            ("weeklyReviewCount", weeklyReviewCount, actual.weeklyReviewCount),
            ("mistakeImageCount", mistakeImageCount, actual.mistakeImageCount)
        ]

        for (label, expected, found) in labels where expected != found {
            messages.append("\(label) 不一致：摘要为 \(expected)，实际数组为 \(found)。")
        }

        return messages
    }
}

struct GaokaoBackupResult {
    let fileURL: URL
    let exportedAt: Date
    let exportedRecordCounts: [String: Int]
    let recordSummary: BackupRecordSummary
    let integrity: BackupIntegritySummary
    let warnings: [String]
}

enum BackupChecksum {
    static func encode(_ envelope: GaokaoBackupEnvelope) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(envelope)
    }

    static func decode(_ data: Data) throws -> GaokaoBackupEnvelope {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(GaokaoBackupEnvelope.self, from: data)
    }

    static func payloadWithoutChecksumSHA256(for envelope: GaokaoBackupEnvelope) throws -> String {
        var payloadEnvelope = envelope
        payloadEnvelope.integrity = payloadEnvelope.integrity.clearingChecksumFields()

        // The checksum intentionally hashes the backup payload with checksum fields empty.
        // It is a deterministic export check, not an encryption layer or digital signature.
        return sha256Hex(data: try encode(payloadEnvelope))
    }

    static func sha256Hex(data: Data) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }
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
        let recordSummary = BackupRecordSummary(
            dayPlanCount: dayPlans.count,
            studyTaskCount: studyTasks.count,
            focusSessionCount: focusSessions.count,
            mistakeRecordCount: mistakeRecords.count,
            promptTemplateCount: promptTemplates.count,
            resourceItemCount: resourceItems.count,
            dailyReviewCount: dailyReviews.count,
            weeklyReviewCount: weeklyReviews.count,
            mistakeImageCount: imageExport.snapshots.count
        )
        let imageTotalBytes = imageExport.snapshots.reduce(0) { $0 + $1.byteCount }
        let integrity = BackupIntegritySummary(
            jsonPayloadSHA256: "",
            payloadWithoutChecksumSHA256: "",
            imageTotalBytes: imageTotalBytes,
            missingImageCount: imageExport.warnings.count,
            warningCount: imageExport.warnings.count
        )
        var envelope = GaokaoBackupEnvelope(
            appName: "Gaokao Cockpit",
            appVersion: appVersionText,
            exportVersion: GaokaoBackupFormat.exportVersion,
            schemaName: GaokaoBackupFormat.schemaName,
            exportSchemaVersion: GaokaoBackupFormat.exportSchemaVersion,
            exportedAt: exportedAt,
            notes: "Local JSON backup export. Import/restore is not supported in this MVP.",
            recordSummary: recordSummary,
            integrity: integrity,
            warnings: imageExport.warnings,
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

        let checksum = try BackupChecksum.payloadWithoutChecksumSHA256(for: envelope)
        envelope.integrity = envelope.integrity.withPayloadChecksum(checksum)

        let data = try BackupChecksum.encode(envelope)
        let fileURL = exportDirectory().appendingPathComponent(makeExportFileName(date: exportedAt))
        try data.write(to: fileURL, options: [.atomic])

        return GaokaoBackupResult(
            fileURL: fileURL,
            exportedAt: exportedAt,
            exportedRecordCounts: envelope.recordSummary.countDictionary,
            recordSummary: envelope.recordSummary,
            integrity: envelope.integrity,
            warnings: imageExport.warnings
        )
    }

    static func makeExportFileName(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = AppDateTime.timeZone
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
