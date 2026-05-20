import Foundation
import SwiftData

struct BackupImportDryRunResult: Codable {
    let fileName: String
    let isReadable: Bool
    let schemaName: String?
    let exportVersion: Int?
    let exportSchemaVersion: Int?
    let exportedAt: Date?
    let validationWarnings: [String]
    let validationErrors: [String]
    let incomingSummary: BackupRecordSummary?
    let localSummary: BackupRecordSummary?
    let conflictSummary: BackupConflictSummary
    let imageRestoreSummary: BackupImageRestoreSummary
    let restorePlan: BackupRestorePlan?
    let recommendation: String
}

struct BackupConflictSummary: Codable {
    let duplicateDayPlanIds: Int
    let duplicateStudyTaskIds: Int
    let duplicateFocusSessionIds: Int
    let duplicateMistakeRecordIds: Int
    let duplicatePromptTemplateIds: Int
    let duplicateResourceItemIds: Int
    let duplicateDailyReviewIds: Int
    let duplicateWeeklyReviewIds: Int
    let duplicateDayKeys: Int
    let duplicateTaskTitlesToday: Int
    let duplicateMistakeFingerprints: Int
    let duplicateDailyReviewDayKeys: Int
    let duplicateWeeklyReviewStartKeys: Int

    static let empty = BackupConflictSummary(
        duplicateDayPlanIds: 0,
        duplicateStudyTaskIds: 0,
        duplicateFocusSessionIds: 0,
        duplicateMistakeRecordIds: 0,
        duplicatePromptTemplateIds: 0,
        duplicateResourceItemIds: 0,
        duplicateDailyReviewIds: 0,
        duplicateWeeklyReviewIds: 0,
        duplicateDayKeys: 0,
        duplicateTaskTitlesToday: 0,
        duplicateMistakeFingerprints: 0,
        duplicateDailyReviewDayKeys: 0,
        duplicateWeeklyReviewStartKeys: 0
    )

    var totalIDConflicts: Int {
        duplicateDayPlanIds
            + duplicateStudyTaskIds
            + duplicateFocusSessionIds
            + duplicateMistakeRecordIds
            + duplicatePromptTemplateIds
            + duplicateResourceItemIds
            + duplicateDailyReviewIds
            + duplicateWeeklyReviewIds
    }
}

struct BackupImageRestoreSummary: Codable {
    let incomingImageCount: Int
    let imagesWithBase64: Int
    let missingBase64Count: Int
    let totalImageBytes: Int
    let estimatedRestoreDirectory: String

    static let empty = BackupImageRestoreSummary(
        incomingImageCount: 0,
        imagesWithBase64: 0,
        missingBase64Count: 0,
        totalImageBytes: 0,
        estimatedRestoreDirectory: "Application Support/MistakeImages/"
    )
}

enum BackupImportDryRunStore {
    static func dryRunImportBackup(url: URL, context: ModelContext) throws -> BackupImportDryRunResult {
        let hasSecurityScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityScopedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let fileName = url.lastPathComponent
        let validationResult = try BackupValidationStore.validateBackupFile(url: url)

        guard validationResult.isReadable else {
            return unreadableResult(
                fileName: fileName,
                validationWarnings: validationResult.warnings,
                validationErrors: validationResult.errors
            )
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            return unreadableResult(
                fileName: fileName,
                validationWarnings: validationResult.warnings,
                validationErrors: validationResult.errors + ["文件无法再次读取：\(error.localizedDescription)"]
            )
        }

        let envelope: GaokaoBackupEnvelope
        do {
            envelope = try BackupChecksum.decode(data)
        } catch {
            let errors = validationResult.errors.isEmpty
                ? ["JSON 无法解析为 GaokaoBackupEnvelope：\(error.localizedDescription)"]
                : validationResult.errors
            return unreadableResult(
                fileName: fileName,
                validationWarnings: validationResult.warnings,
                validationErrors: errors
            )
        }

        let localData = try LocalBackupData.fetch(from: context)
        let incomingSummary = BackupRecordSummary(envelope: envelope)
        let localSummary = localData.recordSummary
        let conflictSummary = makeConflictSummary(envelope: envelope, localData: localData)
        let imageRestoreSummary = makeImageRestoreSummary(envelope: envelope)
        let recommendation = makeRecommendation(
            validationErrors: validationResult.errors,
            conflictSummary: conflictSummary,
            imageRestoreSummary: imageRestoreSummary
        )

        let resultWithoutPlan = BackupImportDryRunResult(
            fileName: fileName,
            isReadable: true,
            schemaName: envelope.schemaName,
            exportVersion: envelope.exportVersion,
            exportSchemaVersion: envelope.exportSchemaVersion,
            exportedAt: envelope.exportedAt,
            validationWarnings: validationResult.warnings,
            validationErrors: validationResult.errors,
            incomingSummary: incomingSummary,
            localSummary: localSummary,
            conflictSummary: conflictSummary,
            imageRestoreSummary: imageRestoreSummary,
            restorePlan: nil,
            recommendation: recommendation
        )
        let restorePlan = BackupRestorePlanBuilder.buildPlan(
            envelope: envelope,
            dryRun: resultWithoutPlan
        )

        return BackupImportDryRunResult(
            fileName: resultWithoutPlan.fileName,
            isReadable: resultWithoutPlan.isReadable,
            schemaName: resultWithoutPlan.schemaName,
            exportVersion: resultWithoutPlan.exportVersion,
            exportSchemaVersion: resultWithoutPlan.exportSchemaVersion,
            exportedAt: resultWithoutPlan.exportedAt,
            validationWarnings: resultWithoutPlan.validationWarnings,
            validationErrors: resultWithoutPlan.validationErrors,
            incomingSummary: resultWithoutPlan.incomingSummary,
            localSummary: resultWithoutPlan.localSummary,
            conflictSummary: resultWithoutPlan.conflictSummary,
            imageRestoreSummary: resultWithoutPlan.imageRestoreSummary,
            restorePlan: restorePlan,
            recommendation: resultWithoutPlan.recommendation
        )
    }

    private static func unreadableResult(
        fileName: String,
        validationWarnings: [String],
        validationErrors: [String]
    ) -> BackupImportDryRunResult {
        BackupImportDryRunResult(
            fileName: fileName,
            isReadable: false,
            schemaName: nil,
            exportVersion: nil,
            exportSchemaVersion: nil,
            exportedAt: nil,
            validationWarnings: validationWarnings,
            validationErrors: validationErrors,
            incomingSummary: nil,
            localSummary: nil,
            conflictSummary: .empty,
            imageRestoreSummary: .empty,
            restorePlan: nil,
            recommendation: "不建议恢复：备份文件无法完成读取或解析。请重新选择有效的 Gaokao Cockpit JSON 备份；本阶段不会写入 SwiftData 或恢复图片。"
        )
    }

    private static func makeConflictSummary(
        envelope: GaokaoBackupEnvelope,
        localData: LocalBackupData
    ) -> BackupConflictSummary {
        let localDayPlanIds = Set(localData.dayPlans.map(\.id))
        let localStudyTaskIds = Set(localData.studyTasks.map(\.id))
        let localFocusSessionIds = Set(localData.focusSessions.map(\.id))
        let localMistakeRecordIds = Set(localData.mistakeRecords.map(\.id))
        let localPromptTemplateIds = Set(localData.promptTemplates.map(\.id))
        let localResourceItemIds = Set(localData.resourceItems.map(\.id))
        let localDailyReviewIds = Set(localData.dailyReviews.map(\.id))
        let localWeeklyReviewIds = Set(localData.weeklyReviews.map(\.id))

        let localDayKeys = Set(localData.dayPlans.map { normalizedKey($0.dayKey) })
        let duplicateDayKeys = envelope.dayPlans.reduce(0) { count, dayPlan in
            localDayKeys.contains(normalizedKey(dayPlan.dayKey)) ? count + 1 : count
        }

        let localTaskKeys = Set(localData.studyTasks.compactMap {
            taskDuplicateKey(dayKey: $0.dayKey, title: $0.title)
        })
        let duplicateTaskTitlesToday = envelope.studyTasks.reduce(0) { count, task in
            guard let key = taskDuplicateKey(dayKey: task.dayKey, title: task.title) else {
                return count
            }

            return localTaskKeys.contains(key) ? count + 1 : count
        }

        let localMistakeFingerprints = Set(localData.mistakeRecords.compactMap {
            mistakeFingerprint(
                subject: $0.subject,
                chapter: $0.chapter,
                source: $0.source,
                questionText: $0.questionText
            )
        })
        let duplicateMistakeFingerprints = envelope.mistakeRecords.reduce(0) { count, mistake in
            guard let fingerprint = mistakeFingerprint(
                subject: mistake.subject,
                chapter: mistake.chapter,
                source: mistake.source,
                questionText: mistake.questionText
            ) else {
                return count
            }

            return localMistakeFingerprints.contains(fingerprint) ? count + 1 : count
        }

        let localDailyReviewDayKeys = Set(localData.dailyReviews.map { normalizedKey($0.dayKey) })
        let duplicateDailyReviewDayKeys = envelope.dailyReviews.reduce(0) { count, review in
            localDailyReviewDayKeys.contains(normalizedKey(review.dayKey)) ? count + 1 : count
        }

        let localWeeklyReviewStartKeys = Set(localData.weeklyReviews.map { normalizedKey($0.weekStartKey) })
        let duplicateWeeklyReviewStartKeys = envelope.weeklyReviews.reduce(0) { count, review in
            localWeeklyReviewStartKeys.contains(normalizedKey(review.weekStartKey)) ? count + 1 : count
        }

        return BackupConflictSummary(
            duplicateDayPlanIds: duplicateCount(incoming: envelope.dayPlans.map(\.id), local: localDayPlanIds),
            duplicateStudyTaskIds: duplicateCount(incoming: envelope.studyTasks.map(\.id), local: localStudyTaskIds),
            duplicateFocusSessionIds: duplicateCount(incoming: envelope.focusSessions.map(\.id), local: localFocusSessionIds),
            duplicateMistakeRecordIds: duplicateCount(incoming: envelope.mistakeRecords.map(\.id), local: localMistakeRecordIds),
            duplicatePromptTemplateIds: duplicateCount(incoming: envelope.promptTemplates.map(\.id), local: localPromptTemplateIds),
            duplicateResourceItemIds: duplicateCount(incoming: envelope.resourceItems.map(\.id), local: localResourceItemIds),
            duplicateDailyReviewIds: duplicateCount(incoming: envelope.dailyReviews.map(\.id), local: localDailyReviewIds),
            duplicateWeeklyReviewIds: duplicateCount(incoming: envelope.weeklyReviews.map(\.id), local: localWeeklyReviewIds),
            duplicateDayKeys: duplicateDayKeys,
            duplicateTaskTitlesToday: duplicateTaskTitlesToday,
            duplicateMistakeFingerprints: duplicateMistakeFingerprints,
            duplicateDailyReviewDayKeys: duplicateDailyReviewDayKeys,
            duplicateWeeklyReviewStartKeys: duplicateWeeklyReviewStartKeys
        )
    }

    private static func makeImageRestoreSummary(envelope: GaokaoBackupEnvelope) -> BackupImageRestoreSummary {
        let imagesWithBase64 = envelope.mistakeImages.filter {
            !$0.base64JPEG.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count
        let totalImageBytes = envelope.mistakeImages.reduce(0) { total, image in
            if image.byteCount > 0 {
                return total + image.byteCount
            }

            if let data = Data(base64Encoded: image.base64JPEG) {
                return total + data.count
            }

            return total
        }

        return BackupImageRestoreSummary(
            incomingImageCount: envelope.mistakeImages.count,
            imagesWithBase64: imagesWithBase64,
            missingBase64Count: envelope.mistakeImages.count - imagesWithBase64,
            totalImageBytes: totalImageBytes,
            estimatedRestoreDirectory: "Application Support/MistakeImages/"
        )
    }

    private static func makeRecommendation(
        validationErrors: [String],
        conflictSummary: BackupConflictSummary,
        imageRestoreSummary: BackupImageRestoreSummary
    ) -> String {
        if !validationErrors.isEmpty {
            return "不建议恢复：备份存在 schema、version、summary 或 checksum 校验错误。请优先重新导出或修正备份文件；本阶段不会写入 SwiftData 或恢复图片。"
        }

        var recommendations: [String] = []

        if conflictSummary.totalIDConflicts > 0 {
            recommendations.append("未来真正恢复应采用 merge-with-new-ids，避免沿用原 UUID 覆盖本地记录。")
        }

        if conflictSummary.duplicateDayKeys > 0 {
            recommendations.append("检测到同 dayKey 计划冲突，恢复时应支持跳过或合并同日 DayPlan。")
        }

        if conflictSummary.duplicateTaskTitlesToday > 0 {
            recommendations.append("检测到同日同名任务，恢复时应按 dayKey + title 去重或保留副本。")
        }

        if conflictSummary.duplicateMistakeFingerprints > 0 {
            recommendations.append("检测到疑似重复错题，恢复时应允许逐条跳过、合并或保留副本。")
        }

        if conflictSummary.duplicateDailyReviewDayKeys > 0 {
            recommendations.append("检测到同 dayKey 每日复盘，恢复时应默认跳过，避免覆盖本地复盘。")
        }

        if conflictSummary.duplicateWeeklyReviewStartKeys > 0 {
            recommendations.append("检测到同 weekStartKey 周复盘，恢复时应默认跳过，避免覆盖本地复盘。")
        }

        if imageRestoreSummary.missingBase64Count > 0 {
            recommendations.append("部分错题图片缺少 base64，未来恢复时这些图片不可自动恢复。")
        }

        if recommendations.isEmpty {
            recommendations.append("备份结构可用于未来恢复；本阶段只做 dry-run，不会写入 SwiftData 或恢复图片。")
        } else {
            recommendations.append("本阶段只做 dry-run，不会写入 SwiftData 或恢复图片。")
        }

        return recommendations.joined(separator: " ")
    }

    private static func duplicateCount<T: Hashable>(incoming: [T], local: Set<T>) -> Int {
        incoming.reduce(0) { count, value in
            local.contains(value) ? count + 1 : count
        }
    }

    private static func taskDuplicateKey(dayKey: String, title: String) -> String? {
        let normalizedTitle = PlanTaskParser.normalizedTitleKey(title)
        guard !normalizedTitle.isEmpty else {
            return nil
        }

        return "\(normalizedKey(dayKey))|\(normalizedTitle)"
    }

    private static func mistakeFingerprint(
        subject: String,
        chapter: String,
        source: String,
        questionText: String
    ) -> String? {
        let questionPrefix = String(questionText.prefix(80))
        let parts = [
            normalizedKey(subject),
            normalizedKey(chapter),
            normalizedKey(source),
            normalizedKey(questionPrefix)
        ]

        guard parts.contains(where: { !$0.isEmpty }) else {
            return nil
        }

        return parts.joined(separator: "|")
    }

    private static func normalizedKey(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
    }
}

private struct LocalBackupData {
    let dayPlans: [DayPlan]
    let studyTasks: [StudyTask]
    let focusSessions: [FocusSession]
    let mistakeRecords: [MistakeRecord]
    let promptTemplates: [PromptTemplate]
    let resourceItems: [ResourceItem]
    let dailyReviews: [DailyReview]
    let weeklyReviews: [WeeklyReview]

    var recordSummary: BackupRecordSummary {
        BackupRecordSummary(
            dayPlanCount: dayPlans.count,
            studyTaskCount: studyTasks.count,
            focusSessionCount: focusSessions.count,
            mistakeRecordCount: mistakeRecords.count,
            promptTemplateCount: promptTemplates.count,
            resourceItemCount: resourceItems.count,
            dailyReviewCount: dailyReviews.count,
            weeklyReviewCount: weeklyReviews.count,
            mistakeImageCount: mistakeRecords.filter {
                !$0.questionImagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }.count
        )
    }

    static func fetch(from context: ModelContext) throws -> LocalBackupData {
        LocalBackupData(
            dayPlans: try context.fetch(FetchDescriptor<DayPlan>()),
            studyTasks: try context.fetch(FetchDescriptor<StudyTask>()),
            focusSessions: try context.fetch(FetchDescriptor<FocusSession>()),
            mistakeRecords: try context.fetch(FetchDescriptor<MistakeRecord>()),
            promptTemplates: try context.fetch(FetchDescriptor<PromptTemplate>()),
            resourceItems: try context.fetch(FetchDescriptor<ResourceItem>()),
            dailyReviews: try context.fetch(FetchDescriptor<DailyReview>()),
            weeklyReviews: try context.fetch(FetchDescriptor<WeeklyReview>())
        )
    }
}
