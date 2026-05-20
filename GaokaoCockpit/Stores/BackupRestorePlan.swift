import Foundation

struct BackupRestorePlan: Codable, Equatable {
    let sourceFileName: String
    let strategy: String
    let incomingSummary: BackupRecordSummary
    let plannedSummary: BackupRestorePlannedSummary
    let skippedSummary: BackupRestoreSkippedSummary
    let referenceRepairSummary: BackupRestoreReferenceRepairSummary
    let idMappingSummary: BackupIDMappingSummary
    let imagePlanSummary: BackupImagePlanSummary
    let warnings: [String]
    let errors: [String]
    let isSafeToProceed: Bool

    init(
        sourceFileName: String,
        strategy: String,
        incomingSummary: BackupRecordSummary,
        plannedSummary: BackupRestorePlannedSummary,
        skippedSummary: BackupRestoreSkippedSummary,
        referenceRepairSummary: BackupRestoreReferenceRepairSummary = .empty,
        idMappingSummary: BackupIDMappingSummary,
        imagePlanSummary: BackupImagePlanSummary,
        warnings: [String],
        errors: [String],
        isSafeToProceed: Bool
    ) {
        self.sourceFileName = sourceFileName
        self.strategy = strategy
        self.incomingSummary = incomingSummary
        self.plannedSummary = plannedSummary
        self.skippedSummary = skippedSummary
        self.referenceRepairSummary = referenceRepairSummary
        self.idMappingSummary = idMappingSummary
        self.imagePlanSummary = imagePlanSummary
        self.warnings = warnings
        self.errors = errors
        self.isSafeToProceed = isSafeToProceed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        sourceFileName = try container.decode(String.self, forKey: .sourceFileName)
        strategy = try container.decode(String.self, forKey: .strategy)
        incomingSummary = try container.decode(BackupRecordSummary.self, forKey: .incomingSummary)
        plannedSummary = try container.decode(BackupRestorePlannedSummary.self, forKey: .plannedSummary)
        skippedSummary = try container.decode(BackupRestoreSkippedSummary.self, forKey: .skippedSummary)
        referenceRepairSummary = try container.decodeIfPresent(
            BackupRestoreReferenceRepairSummary.self,
            forKey: .referenceRepairSummary
        ) ?? .empty
        idMappingSummary = try container.decode(BackupIDMappingSummary.self, forKey: .idMappingSummary)
        imagePlanSummary = try container.decode(BackupImagePlanSummary.self, forKey: .imagePlanSummary)
        warnings = try container.decode([String].self, forKey: .warnings)
        errors = try container.decode([String].self, forKey: .errors)
        isSafeToProceed = try container.decode(Bool.self, forKey: .isSafeToProceed)
    }
}

struct BackupRestorePlannedSummary: Codable, Equatable {
    let dayPlansToInsert: Int
    let studyTasksToInsert: Int
    let focusSessionsToInsert: Int
    let mistakeRecordsToInsert: Int
    let promptTemplatesToInsert: Int
    let resourceItemsToInsert: Int
    let dailyReviewsToInsert: Int
    let weeklyReviewsToInsert: Int
    let imagesToRestore: Int
}

struct BackupRestoreSkippedSummary: Codable, Equatable {
    let duplicateDayPlans: Int
    let duplicateStudyTasks: Int
    let duplicateMistakes: Int
    let duplicateDailyReviews: Int
    let duplicateWeeklyReviews: Int
    let builtInPromptTemplates: Int
    // Retained for older plan consumers. Stage 15 keeps invalid references in referenceRepairSummary.
    let invalidReferences: Int
}

struct BackupRestoreReferenceRepairSummary: Codable, Equatable {
    let studyTasksWithMissingDayPlan: Int
    let focusSessionsWithMissingTask: Int
    let dailyReviewsWithMissingBestMistake: Int
    let totalRecordsNeedingRepair: Int

    static let empty = BackupRestoreReferenceRepairSummary(
        studyTasksWithMissingDayPlan: 0,
        focusSessionsWithMissingTask: 0,
        dailyReviewsWithMissingBestMistake: 0,
        totalRecordsNeedingRepair: 0
    )
}

struct BackupIDMappingSummary: Codable, Equatable {
    let dayPlanMappings: Int
    let studyTaskMappings: Int
    let focusSessionTaskReferences: Int
    let dailyReviewMistakeReferences: Int
}

struct BackupImagePlanSummary: Codable, Equatable {
    let incomingImages: Int
    let validImages: Int
    let missingImages: Int
    let estimatedBytes: Int
}
