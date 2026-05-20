import Foundation

struct BackupRestorePlan: Codable, Equatable {
    let sourceFileName: String
    let strategy: String
    let incomingSummary: BackupRecordSummary
    let plannedSummary: BackupRestorePlannedSummary
    let skippedSummary: BackupRestoreSkippedSummary
    let idMappingSummary: BackupIDMappingSummary
    let imagePlanSummary: BackupImagePlanSummary
    let warnings: [String]
    let errors: [String]
    let isSafeToProceed: Bool
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
    let invalidReferences: Int
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
