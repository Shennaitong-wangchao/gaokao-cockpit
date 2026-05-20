import Foundation

enum BackupRestorePlanBuilder {
    static let defaultStrategy = "merge-with-new-ids"

    static func buildPlan(
        envelope: GaokaoBackupEnvelope,
        dryRun: BackupImportDryRunResult
    ) -> BackupRestorePlan {
        let incomingSummary = dryRun.incomingSummary ?? BackupRecordSummary(envelope: envelope)
        let referenceSummary = makeReferenceSummary(envelope: envelope)
        let referenceRepairSummary = BackupRestoreReferenceRepairSummary(
            studyTasksWithMissingDayPlan: referenceSummary.invalidStudyTaskDayPlanReferences,
            focusSessionsWithMissingTask: referenceSummary.invalidFocusSessionTaskReferences,
            dailyReviewsWithMissingBestMistake: referenceSummary.invalidDailyReviewMistakeReferences,
            totalRecordsNeedingRepair: referenceSummary.invalidReferenceCount
        )
        let builtInPromptTemplates = envelope.promptTemplates.filter(\.isBuiltIn).count
        let skippedSummary = BackupRestoreSkippedSummary(
            duplicateDayPlans: dryRun.conflictSummary.duplicateDayKeys,
            duplicateStudyTasks: dryRun.conflictSummary.duplicateTaskTitlesToday,
            duplicateMistakes: dryRun.conflictSummary.duplicateMistakeFingerprints,
            duplicateDailyReviews: dryRun.conflictSummary.duplicateDailyReviewDayKeys,
            duplicateWeeklyReviews: dryRun.conflictSummary.duplicateWeeklyReviewStartKeys,
            builtInPromptTemplates: builtInPromptTemplates,
            invalidReferences: 0
        )
        let plannedSummary = BackupRestorePlannedSummary(
            dayPlansToInsert: remaining(
                incomingSummary.dayPlanCount,
                skippedSummary.duplicateDayPlans
            ),
            studyTasksToInsert: remaining(
                incomingSummary.studyTaskCount,
                skippedSummary.duplicateStudyTasks
            ),
            focusSessionsToInsert: incomingSummary.focusSessionCount,
            mistakeRecordsToInsert: remaining(
                incomingSummary.mistakeRecordCount,
                skippedSummary.duplicateMistakes
            ),
            promptTemplatesToInsert: remaining(
                incomingSummary.promptTemplateCount,
                skippedSummary.builtInPromptTemplates
            ),
            resourceItemsToInsert: incomingSummary.resourceItemCount,
            dailyReviewsToInsert: remaining(
                incomingSummary.dailyReviewCount,
                skippedSummary.duplicateDailyReviews
            ),
            weeklyReviewsToInsert: remaining(
                incomingSummary.weeklyReviewCount,
                skippedSummary.duplicateWeeklyReviews
            ),
            imagesToRestore: dryRun.imageRestoreSummary.imagesWithBase64
        )
        let idMappingSummary = BackupIDMappingSummary(
            dayPlanMappings: plannedSummary.dayPlansToInsert,
            studyTaskMappings: plannedSummary.studyTasksToInsert,
            focusSessionTaskReferences: referenceSummary.validFocusSessionTaskReferences,
            dailyReviewMistakeReferences: referenceSummary.validDailyReviewMistakeReferences
        )
        let imagePlanSummary = BackupImagePlanSummary(
            incomingImages: dryRun.imageRestoreSummary.incomingImageCount,
            validImages: dryRun.imageRestoreSummary.imagesWithBase64,
            missingImages: dryRun.imageRestoreSummary.missingBase64Count,
            estimatedBytes: dryRun.imageRestoreSummary.totalImageBytes
        )
        let errors = dryRun.validationErrors
        let warnings = makeWarnings(
            envelope: envelope,
            dryRun: dryRun,
            skippedSummary: skippedSummary,
            referenceRepairSummary: referenceRepairSummary
        )

        return BackupRestorePlan(
            sourceFileName: dryRun.fileName,
            strategy: defaultStrategy,
            incomingSummary: incomingSummary,
            plannedSummary: plannedSummary,
            skippedSummary: skippedSummary,
            referenceRepairSummary: referenceRepairSummary,
            idMappingSummary: idMappingSummary,
            imagePlanSummary: imagePlanSummary,
            warnings: warnings,
            errors: errors,
            isSafeToProceed: dryRun.isReadable && errors.isEmpty
        )
    }

    static func makeReferenceRepairSummary(envelope: GaokaoBackupEnvelope) -> BackupRestoreReferenceRepairSummary {
        let referenceSummary = makeReferenceSummary(envelope: envelope)

        return BackupRestoreReferenceRepairSummary(
            studyTasksWithMissingDayPlan: referenceSummary.invalidStudyTaskDayPlanReferences,
            focusSessionsWithMissingTask: referenceSummary.invalidFocusSessionTaskReferences,
            dailyReviewsWithMissingBestMistake: referenceSummary.invalidDailyReviewMistakeReferences,
            totalRecordsNeedingRepair: referenceSummary.invalidReferenceCount
        )
    }

    private static func makeReferenceSummary(envelope: GaokaoBackupEnvelope) -> ReferenceSummary {
        let dayPlanIds = Set(envelope.dayPlans.map(\.id))
        let studyTaskIds = Set(envelope.studyTasks.map(\.id))
        let mistakeIds = Set(envelope.mistakeRecords.map(\.id))

        let invalidStudyTaskDayPlanReferences = envelope.studyTasks.reduce(0) { count, task in
            guard let dayPlanId = task.dayPlanId else {
                return count
            }

            return dayPlanIds.contains(dayPlanId) ? count : count + 1
        }

        let focusSessionTaskReferences = envelope.focusSessions.compactMap(\.taskId)
        let invalidFocusSessionTaskReferences = focusSessionTaskReferences.reduce(0) { count, taskId in
            studyTaskIds.contains(taskId) ? count : count + 1
        }

        let dailyReviewMistakeReferences = envelope.dailyReviews.compactMap(\.bestMistakeId)
        let invalidDailyReviewMistakeReferences = dailyReviewMistakeReferences.reduce(0) { count, mistakeId in
            mistakeIds.contains(mistakeId) ? count : count + 1
        }

        return ReferenceSummary(
            invalidStudyTaskDayPlanReferences: invalidStudyTaskDayPlanReferences,
            invalidFocusSessionTaskReferences: invalidFocusSessionTaskReferences,
            invalidDailyReviewMistakeReferences: invalidDailyReviewMistakeReferences,
            validFocusSessionTaskReferences: focusSessionTaskReferences.count - invalidFocusSessionTaskReferences,
            validDailyReviewMistakeReferences: dailyReviewMistakeReferences.count - invalidDailyReviewMistakeReferences
        )
    }

    private static func makeWarnings(
        envelope: GaokaoBackupEnvelope,
        dryRun: BackupImportDryRunResult,
        skippedSummary: BackupRestoreSkippedSummary,
        referenceRepairSummary: BackupRestoreReferenceRepairSummary
    ) -> [String] {
        var warnings = dryRun.validationWarnings

        if dryRun.conflictSummary.totalIDConflicts > 0 {
            warnings.append("检测到 \(dryRun.conflictSummary.totalIDConflicts) 个 UUID 冲突；恢复计划会使用 new ids，不沿用备份原 UUID。")
        }

        if skippedSummary.duplicateDayPlans > 0 {
            warnings.append("检测到 \(skippedSummary.duplicateDayPlans) 个重复 dayKey 的 DayPlan，默认计划跳过。")
        }

        if skippedSummary.duplicateStudyTasks > 0 {
            warnings.append("检测到 \(skippedSummary.duplicateStudyTasks) 个同日同名 StudyTask，默认计划跳过。")
        }

        if skippedSummary.duplicateMistakes > 0 {
            warnings.append("检测到 \(skippedSummary.duplicateMistakes) 个疑似重复错题 fingerprint，默认计划跳过。")
        }

        if skippedSummary.duplicateDailyReviews > 0 {
            warnings.append("检测到 \(skippedSummary.duplicateDailyReviews) 个重复 dayKey 的 DailyReview，默认计划跳过。")
        }

        if skippedSummary.duplicateWeeklyReviews > 0 {
            warnings.append("检测到 \(skippedSummary.duplicateWeeklyReviews) 个重复 weekStartKey 的 WeeklyReview，默认计划跳过。")
        }

        if skippedSummary.builtInPromptTemplates > 0 {
            warnings.append("检测到 \(skippedSummary.builtInPromptTemplates) 个内置 PromptTemplate，默认计划跳过，只考虑导入自定义模板。")
        }

        if dryRun.imageRestoreSummary.missingBase64Count > 0 {
            warnings.append("检测到 \(dryRun.imageRestoreSummary.missingBase64Count) 张错题图片缺少 base64，未来恢复时不会自动恢复这些图片。")
        }

        if referenceRepairSummary.totalRecordsNeedingRepair > 0 {
            warnings.append("检测到部分记录引用了备份中不存在的对象。Stage 15 将它们标记为需要引用修复，而不是直接视为跳过。未来真实恢复时可选择置空引用、重新映射或人工确认。")
            warnings.append("需要引用修复的记录：StudyTask \(referenceRepairSummary.studyTasksWithMissingDayPlan) 条、FocusSession \(referenceRepairSummary.focusSessionsWithMissingTask) 条、DailyReview \(referenceRepairSummary.dailyReviewsWithMissingBestMistake) 条。")
            warnings.append("当前 restore plan 仍保留这些记录的 planned insert 计数；未来真实恢复前需要先确定引用修复策略。")
        }

        if envelope.resourceItems.contains(where: { $0.uri.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            warnings.append("检测到 URI 为空的 ResourceItem；资料索引可导入，但 URI 失效只作为 warning 处理。")
        } else if !envelope.resourceItems.isEmpty {
            warnings.append("ResourceItem URI 可用性不会在 Stage 14 校验；未来恢复时 URI 失效只作为 warning 处理。")
        }

        return warnings
    }

    private static func remaining(_ incoming: Int, _ skipped: Int) -> Int {
        max(0, incoming - skipped)
    }
}

private struct ReferenceSummary {
    let invalidStudyTaskDayPlanReferences: Int
    let invalidFocusSessionTaskReferences: Int
    let invalidDailyReviewMistakeReferences: Int
    let validFocusSessionTaskReferences: Int
    let validDailyReviewMistakeReferences: Int

    var invalidReferenceCount: Int {
        invalidStudyTaskDayPlanReferences
            + invalidFocusSessionTaskReferences
            + invalidDailyReviewMistakeReferences
    }
}
