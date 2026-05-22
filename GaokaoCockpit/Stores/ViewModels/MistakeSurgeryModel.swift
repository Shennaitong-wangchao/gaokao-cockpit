import SwiftData
import SwiftUI

@Observable
final class MistakeSurgeryModel {
    var mistakes: [MistakeRecord] = []
    var selectedSubjectFilter: LearningSubject?
    var selectedReviewFilter: ReviewStatus?
    var totalMistakeCount = 0
    var scheduledCount = 0
    var reviewedCount = 0
    var masteredCount = 0
    var isLoading = true
    var statusMessage: String?
    var activeEditor: MistakeEditorMode?
    var activePromptSheet: MistakePromptSheet?
    var activeImagePreview: MistakeImagePreviewItem?

    func loadMistakes(in context: ModelContext) {
        isLoading = true
        statusMessage = nil

        do {
            try refreshMistakeDataThrowing(in: context)
            isLoading = false
        } catch {
            isLoading = false
            statusMessage = "加载错题失败：\(error.localizedDescription)"
            HapticFeedback.error()
            ToastManager.shared.show(message: "加载错题失败", style: .error)
        }
    }

    func refreshMistakeData(in context: ModelContext) {
        do {
            try refreshMistakeDataThrowing(in: context)
        } catch {
            statusMessage = "刷新错题失败：\(error.localizedDescription)"
            HapticFeedback.error()
        }
    }

    func updateReviewStatus(in context: ModelContext, mistake: MistakeRecord, to status: ReviewStatus) {
        guard ReviewStatus.from(mistake.reviewStatus) != status else {
            return
        }

        do {
            mistake.reviewStatus = status.storageValue
            MistakeRecordStore.updateMistakeTimestamp(mistake)
            try context.save()
            try refreshMistakeDataThrowing(in: context)
            statusMessage = "已更新复习状态：\(status.displayName)。"
            HapticFeedback.lightImpact()
            ToastManager.shared.show(
                message: "已更新复习状态：\(status.displayName)",
                style: .success
            )
        } catch {
            statusMessage = "更新复习状态失败：\(error.localizedDescription)"
            HapticFeedback.error()
            ToastManager.shared.show(message: "更新复习状态失败", style: .error)
        }
    }

    func prepareMistakePrompt(in context: ModelContext, for mistake: MistakeRecord) {
        do {
            guard let template = try PromptTemplateStore.fetchTemplate(title: "错题手术", in: context) else {
                statusMessage = "找不到内置\"错题手术\"模板。请检查 Prompt seed 是否成功。"
                HapticFeedback.error()
                return
            }

            activePromptSheet = MistakePromptSheet(
                template: template,
                values: mistake.promptValues
            )
        } catch {
            statusMessage = "加载错题 Prompt 失败：\(error.localizedDescription)"
            HapticFeedback.error()
        }
    }

    private func refreshMistakeDataThrowing(in context: ModelContext) throws {
        mistakes = try MistakeRecordStore.fetchMistakes(
            subject: selectedSubjectFilter?.storageValue,
            reviewStatus: selectedReviewFilter?.storageValue,
            in: context
        )
        totalMistakeCount = try MistakeRecordStore.countMistakes(in: context)
        scheduledCount = try MistakeRecordStore.countMistakes(
            reviewStatus: ReviewStatus.scheduled.storageValue,
            in: context
        )
        reviewedCount = try MistakeRecordStore.countMistakes(
            reviewStatus: ReviewStatus.reviewed.storageValue,
            in: context
        )
        masteredCount = try MistakeRecordStore.countMistakes(
            reviewStatus: ReviewStatus.mastered.storageValue,
            in: context
        )
    }
}
