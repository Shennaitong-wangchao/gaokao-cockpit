import SwiftUI

struct BackupRestorePlanPreviewSection: View {
    let plan: BackupRestorePlan

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("未来恢复计划预览", systemImage: "arrow.triangle.merge")
                .font(.footnote.weight(.semibold))

            Text("这是恢复计划预览，本阶段不会写入数据。")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 7) {
                BackupSummaryRow(title: "策略", value: plan.strategy)
                BackupSummaryRow(title: "是否建议继续", value: plan.isSafeToProceed ? "是" : "否")
            }
            .font(.caption)

            VStack(alignment: .leading, spacing: 7) {
                Text("预计插入")
                    .font(.caption.weight(.semibold))

                BackupSummaryRow(title: "DayPlans", value: "\(plan.plannedSummary.dayPlansToInsert)")
                BackupSummaryRow(title: "StudyTasks", value: "\(plan.plannedSummary.studyTasksToInsert)")
                BackupSummaryRow(title: "FocusSessions", value: "\(plan.plannedSummary.focusSessionsToInsert)")
                BackupSummaryRow(title: "Mistakes", value: "\(plan.plannedSummary.mistakeRecordsToInsert)")
                BackupSummaryRow(title: "Reviews", value: "\(plannedReviewCount)")
                BackupSummaryRow(title: "Images", value: "\(plan.plannedSummary.imagesToRestore)")
            }
            .font(.caption)

            VStack(alignment: .leading, spacing: 7) {
                Text("预计跳过")
                    .font(.caption.weight(.semibold))

                BackupSummaryRow(title: "重复 DayPlan", value: "\(plan.skippedSummary.duplicateDayPlans)")
                BackupSummaryRow(title: "重复任务", value: "\(plan.skippedSummary.duplicateStudyTasks)")
                BackupSummaryRow(title: "重复错题", value: "\(plan.skippedSummary.duplicateMistakes)")
                BackupSummaryRow(title: "内置 Prompt", value: "\(plan.skippedSummary.builtInPromptTemplates)")
                BackupSummaryRow(title: "重复复盘", value: "\(skippedReviewCount)")
            }
            .font(.caption)

            VStack(alignment: .leading, spacing: 7) {
                Text("需要处理的引用")
                    .font(.caption.weight(.semibold))

                BackupSummaryRow(
                    title: "StudyTask 缺失 DayPlan",
                    value: "\(plan.referenceRepairSummary.studyTasksWithMissingDayPlan)"
                )
                BackupSummaryRow(
                    title: "FocusSession 缺失 Task",
                    value: "\(plan.referenceRepairSummary.focusSessionsWithMissingTask)"
                )
                BackupSummaryRow(
                    title: "DailyReview 缺失 Mistake",
                    value: "\(plan.referenceRepairSummary.dailyReviewsWithMissingBestMistake)"
                )
                BackupSummaryRow(
                    title: "总计需修复",
                    value: "\(plan.referenceRepairSummary.totalRecordsNeedingRepair)"
                )

                Text("这些记录不会在预检中被直接判定为跳过。未来真正恢复时需要选择置空引用、重新映射或人工确认。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .font(.caption)

            if !plan.warnings.isEmpty {
                BackupMessageList(
                    title: "restore plan warnings",
                    systemImage: "exclamationmark.triangle",
                    color: .orange,
                    messages: plan.warnings
                )
            }

            if !plan.errors.isEmpty {
                BackupMessageList(
                    title: "restore plan errors",
                    systemImage: "xmark.octagon",
                    color: .red,
                    messages: plan.errors
                )
            }
        }
    }

    private var plannedReviewCount: Int {
        plan.plannedSummary.dailyReviewsToInsert + plan.plannedSummary.weeklyReviewsToInsert
    }

    private var skippedReviewCount: Int {
        plan.skippedSummary.duplicateDailyReviews + plan.skippedSummary.duplicateWeeklyReviews
    }
}
