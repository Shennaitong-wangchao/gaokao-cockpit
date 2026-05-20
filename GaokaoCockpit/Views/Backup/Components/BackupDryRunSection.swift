import Foundation
import SwiftUI

struct BackupImportDryRunCard: View {
    let countDisplayOrder: [(key: String, title: String)]
    let isDryRunning: Bool
    let result: BackupImportDryRunResult?
    let errorMessage: String?
    let onSelectFile: () -> Void

    var body: some View {
        BackupCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("导入预检（Dry-run）", systemImage: "doc.badge.magnifyingglass")
                    .font(.headline)

                Text("选择一个备份 JSON，只做读取和冲突预检，不会写入或覆盖任何数据。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("本阶段不会导入数据，只做预检。")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                Button {
                    onSelectFile()
                } label: {
                    if isDryRunning {
                        Label("正在预检备份", systemImage: "hourglass")
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("选择备份文件并预检", systemImage: "doc")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isDryRunning)

                if isDryRunning {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("正在读取 JSON 并计算冲突摘要")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.red)
                }

                if let result {
                    BackupImportDryRunResultView(
                        result: result,
                        countDisplayOrder: countDisplayOrder
                    )
                }
            }
        }
    }
}

struct BackupImportDryRunResultView: View {
    let result: BackupImportDryRunResult
    let countDisplayOrder: [(key: String, title: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(resultTitle, systemImage: result.validationErrors.isEmpty && result.isReadable ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(result.validationErrors.isEmpty && result.isReadable ? Color.green : Color.red)

            Text("本阶段不会导入数据，只做预检。")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                BackupSummaryRow(title: "文件名", value: result.fileName)
                BackupSummaryRow(title: "schema", value: result.schemaName ?? "未识别")
                BackupSummaryRow(title: "exportVersion", value: result.exportVersion.map(String.init) ?? "未识别")
                BackupSummaryRow(title: "schemaVersion", value: result.exportSchemaVersion.map(String.init) ?? "未识别")
                BackupSummaryRow(title: "exportedAt", value: formattedDate(result.exportedAt))
                BackupSummaryRow(title: "读取状态", value: result.isReadable ? "可读" : "不可读")
            }
            .font(.footnote)

            if !result.validationWarnings.isEmpty {
                BackupMessageList(
                    title: "validation warnings",
                    systemImage: "exclamationmark.triangle",
                    color: .orange,
                    messages: result.validationWarnings
                )
            }

            if !result.validationErrors.isEmpty {
                BackupMessageList(
                    title: "validation errors",
                    systemImage: "xmark.octagon",
                    color: .red,
                    messages: result.validationErrors
                )
            }

            BackupRecordSummarySection(
                title: "将会导入",
                summary: result.incomingSummary,
                countDisplayOrder: countDisplayOrder
            )

            BackupRecordSummarySection(
                title: "当前本地",
                summary: result.localSummary,
                countDisplayOrder: countDisplayOrder
            )

            BackupConflictSummarySection(summary: result.conflictSummary)
            BackupImageRestoreSummarySection(summary: result.imageRestoreSummary)

            VStack(alignment: .leading, spacing: 6) {
                Label("建议策略", systemImage: "lightbulb")
                    .font(.footnote.weight(.semibold))

                Text(result.recommendation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            if let restorePlan = result.restorePlan {
                Divider()
                BackupRestorePlanPreviewSection(plan: restorePlan)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var resultTitle: String {
        if !result.isReadable {
            return "备份不可读"
        }

        if result.validationErrors.isEmpty {
            return "预检完成"
        }

        return "预检发现问题"
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else {
            return "未识别"
        }

        return date.formatted(date: .abbreviated, time: .shortened)
    }
}

struct BackupRecordSummarySection: View {
    let title: String
    let summary: BackupRecordSummary?
    let countDisplayOrder: [(key: String, title: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: "number")
                .font(.footnote.weight(.semibold))

            if let summary {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(countDisplayOrder, id: \.key) { item in
                        BackupCountTile(
                            title: item.title,
                            count: summary.countDictionary[item.key, default: 0]
                        )
                    }
                }
            } else {
                Text("未能读取数量摘要")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct BackupConflictSummarySection: View {
    let summary: BackupConflictSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("冲突摘要", systemImage: "exclamationmark.arrow.triangle.2.circlepath")
                .font(.footnote.weight(.semibold))

            VStack(alignment: .leading, spacing: 7) {
                BackupSummaryRow(title: "DayPlan ID", value: "\(summary.duplicateDayPlanIds)")
                BackupSummaryRow(title: "StudyTask ID", value: "\(summary.duplicateStudyTaskIds)")
                BackupSummaryRow(title: "FocusSession ID", value: "\(summary.duplicateFocusSessionIds)")
                BackupSummaryRow(title: "MistakeRecord ID", value: "\(summary.duplicateMistakeRecordIds)")
                BackupSummaryRow(title: "PromptTemplate ID", value: "\(summary.duplicatePromptTemplateIds)")
                BackupSummaryRow(title: "ResourceItem ID", value: "\(summary.duplicateResourceItemIds)")
                BackupSummaryRow(title: "DailyReview ID", value: "\(summary.duplicateDailyReviewIds)")
                BackupSummaryRow(title: "WeeklyReview ID", value: "\(summary.duplicateWeeklyReviewIds)")
                BackupSummaryRow(title: "dayKey", value: "\(summary.duplicateDayKeys)")
                BackupSummaryRow(title: "同日同名任务", value: "\(summary.duplicateTaskTitlesToday)")
                BackupSummaryRow(title: "错题 fingerprint", value: "\(summary.duplicateMistakeFingerprints)")
                BackupSummaryRow(title: "DailyReview dayKey", value: "\(summary.duplicateDailyReviewDayKeys)")
                BackupSummaryRow(title: "WeeklyReview weekStartKey", value: "\(summary.duplicateWeeklyReviewStartKeys)")
            }
            .font(.caption)
        }
    }
}

struct BackupImageRestoreSummarySection: View {
    let summary: BackupImageRestoreSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("图片恢复预览", systemImage: "photo")
                .font(.footnote.weight(.semibold))

            VStack(alignment: .leading, spacing: 7) {
                BackupSummaryRow(title: "备份内图片", value: "\(summary.incomingImageCount)")
                BackupSummaryRow(title: "含 base64", value: "\(summary.imagesWithBase64)")
                BackupSummaryRow(title: "缺少 base64", value: "\(summary.missingBase64Count)")
                BackupSummaryRow(title: "图片总大小", value: Self.byteFormatter.string(fromByteCount: Int64(summary.totalImageBytes)))
                BackupSummaryRow(title: "预计目录", value: summary.estimatedRestoreDirectory)
            }
            .font(.caption)
        }
    }

    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter
    }()
}
