import SwiftData
import SwiftUI

struct BackupExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var isExporting = false
    @State private var exportResult: GaokaoBackupResult?
    @State private var errorMessage: String?
    @State private var shareItem: BackupShareItem?
    @State private var isValidating = false
    @State private var validationResult: BackupValidationResult?
    @State private var validationErrorMessage: String?
    @State private var isDocumentPickerPresented = false
    @State private var isDryRunningImport = false
    @State private var dryRunResult: BackupImportDryRunResult?
    @State private var dryRunErrorMessage: String?

    private let countDisplayOrder: [(key: String, title: String)] = [
        ("dayPlans", "计划"),
        ("studyTasks", "任务"),
        ("focusSessions", "专注"),
        ("mistakeRecords", "错题"),
        ("promptTemplates", "Prompt"),
        ("resourceItems", "资料"),
        ("dailyReviews", "每日复盘"),
        ("weeklyReviews", "周复盘"),
        ("mistakeImages", "错题图片")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    BackupHeaderCard()

                    Button {
                        exportBackup()
                    } label: {
                        if isExporting {
                            Label("正在导出", systemImage: "hourglass")
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("导出备份", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isExporting)
                    .accessibilityLabel("导出备份")

                    if isExporting {
                        BackupCard {
                            HStack(spacing: 10) {
                                ProgressView()
                                Text("正在生成本地 JSON 备份文件")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if let errorMessage {
                        BackupCard(tint: .red) {
                            Label(errorMessage, systemImage: "exclamationmark.triangle")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.red)
                        }
                    }

                    if let exportResult {
                        BackupResultCard(
                            result: exportResult,
                            countDisplayOrder: countDisplayOrder,
                            isValidating: isValidating,
                            validationResult: validationResult,
                            validationErrorMessage: validationErrorMessage
                        ) {
                            shareItem = BackupShareItem(fileURL: exportResult.fileURL)
                        } onValidate: {
                            validateExportedBackup(exportResult)
                        }
                    }

                    BackupImportDryRunCard(
                        countDisplayOrder: countDisplayOrder,
                        isDryRunning: isDryRunningImport,
                        result: dryRunResult,
                        errorMessage: dryRunErrorMessage
                    ) {
                        isDocumentPickerPresented = true
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("数据备份")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(activityItems: [item.fileURL])
        }
        .sheet(isPresented: $isDocumentPickerPresented) {
            DocumentPicker { url in
                dryRunImportBackup(url: url)
            }
        }
    }

    private func exportBackup() {
        isExporting = true
        errorMessage = nil
        validationResult = nil
        validationErrorMessage = nil

        Task { @MainActor in
            await Task.yield()

            do {
                exportResult = try BackupExportStore.exportAllData(in: modelContext)
            } catch {
                errorMessage = "备份失败：\(error.localizedDescription)"
            }

            isExporting = false
        }
    }

    private func validateExportedBackup(_ result: GaokaoBackupResult) {
        isValidating = true
        validationResult = nil
        validationErrorMessage = nil

        Task { @MainActor in
            await Task.yield()

            do {
                validationResult = try BackupValidationStore.validateBackupFile(url: result.fileURL)
            } catch {
                validationErrorMessage = "验证失败：\(error.localizedDescription)"
            }

            isValidating = false
        }
    }

    private func dryRunImportBackup(url: URL) {
        isDryRunningImport = true
        dryRunResult = nil
        dryRunErrorMessage = nil

        Task { @MainActor in
            await Task.yield()

            do {
                dryRunResult = try BackupImportDryRunStore.dryRunImportBackup(
                    url: url,
                    context: modelContext
                )
            } catch {
                dryRunErrorMessage = "预检失败：\(error.localizedDescription)"
            }

            isDryRunningImport = false
        }
    }
}

private struct BackupShareItem: Identifiable {
    let id = UUID()
    let fileURL: URL
}

private struct BackupHeaderCard: View {
    var body: some View {
        BackupCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("数据备份", systemImage: "externaldrive")
                    .font(.title2.bold())

                Text("导出一个本地 JSON 备份文件，包含计划、任务、专注、错题、Prompt、复盘和错题图片。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("本阶段支持导出、验证和导入预检；不会真正导入、覆盖数据或恢复图片。")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct BackupImportDryRunCard: View {
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

private struct BackupResultCard: View {
    let result: GaokaoBackupResult
    let countDisplayOrder: [(key: String, title: String)]
    let isValidating: Bool
    let validationResult: BackupValidationResult?
    let validationErrorMessage: String?
    let onShare: () -> Void
    let onValidate: () -> Void

    var body: some View {
        BackupCard(tint: .green) {
            VStack(alignment: .leading, spacing: 14) {
                Label("备份已导出", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.fileURL.lastPathComponent)
                        .font(.footnote.weight(.semibold))
                        .textSelection(.enabled)

                    Text(result.fileURL.deletingLastPathComponent().path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .textSelection(.enabled)
                }

                VStack(alignment: .leading, spacing: 8) {
                    BackupSummaryRow(title: "导出时间", value: result.exportedAt.formatted(date: .abbreviated, time: .shortened))
                    BackupSummaryRow(title: "错题图片", value: "\(result.recordSummary.mistakeImageCount) 张")
                    BackupSummaryRow(title: "图片总大小", value: Self.byteFormatter.string(fromByteCount: Int64(result.integrity.imageTotalBytes)))
                    BackupSummaryRow(title: "warnings", value: "\(result.integrity.warningCount) 条")
                    BackupSummaryRow(title: "checksum", value: checksumPreview)
                }
                .font(.footnote)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(countDisplayOrder, id: \.key) { item in
                        BackupCountTile(
                            title: item.title,
                            count: result.exportedRecordCounts[item.key, default: 0]
                        )
                    }
                }

                if !result.warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("导出提醒", systemImage: "exclamationmark.triangle")
                            .font(.subheadline.weight(.semibold))

                        ForEach(result.warnings, id: \.self) { warning in
                            Text(warning)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Text("checksum 基于 checksum 字段为空时的备份内容计算，用于检测导出流程是否稳定，不是加密签名。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    onValidate()
                } label: {
                    if isValidating {
                        Label("正在验证备份", systemImage: "hourglass")
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("验证刚刚导出的备份", systemImage: "checkmark.shield")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isValidating)

                if let validationErrorMessage {
                    Label(validationErrorMessage, systemImage: "exclamationmark.triangle")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.red)
                }

                if let validationResult {
                    BackupValidationResultView(result: validationResult)
                }

                Button {
                    onShare()
                } label: {
                    Label("分享/保存备份文件", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var checksumPreview: String {
        let checksum = result.integrity.displayChecksum
        guard !checksum.isEmpty else {
            return "未生成"
        }

        return "\(String(checksum.prefix(12)))..."
    }

    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter
    }()
}

private struct BackupSummaryRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }
}

private struct BackupValidationResultView: View {
    let result: BackupValidationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(result.isValid ? "备份结构可读" : "备份需要检查", systemImage: result.isValid ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(result.isValid ? Color.green : Color.red)

            VStack(alignment: .leading, spacing: 8) {
                BackupSummaryRow(title: "文件读取", value: result.isReadable ? "可读" : "不可读")
                BackupSummaryRow(title: "schema", value: result.schemaName ?? "未识别")
                BackupSummaryRow(title: "version", value: result.exportVersion.map { String($0) } ?? "未识别")
                BackupSummaryRow(title: "数量一致", value: result.isCountConsistent ? "一致" : "不一致")
                BackupSummaryRow(title: "checksum", value: checksumStatus)
            }
            .font(.footnote)

            if !result.warnings.isEmpty {
                BackupMessageList(title: "warnings", systemImage: "exclamationmark.triangle", color: .orange, messages: result.warnings)
            }

            if !result.errors.isEmpty {
                BackupMessageList(title: "errors", systemImage: "xmark.octagon", color: .red, messages: result.errors)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var checksumStatus: String {
        switch result.checksumMatches {
        case .some(true):
            return "匹配"
        case .some(false):
            return "不匹配"
        case .none:
            return "未校验"
        }
    }
}

private struct BackupImportDryRunResultView: View {
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

private struct BackupRestorePlanPreviewSection: View {
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

private struct BackupRecordSummarySection: View {
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

private struct BackupConflictSummarySection: View {
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

private struct BackupImageRestoreSummarySection: View {
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

private struct BackupMessageList: View {
    let title: String
    let systemImage: String
    let color: Color
    let messages: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(color)

            ForEach(messages, id: \.self) { message in
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct BackupCountTile: View {
    let title: String
    let count: Int

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title3.weight(.bold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct BackupCard<Content: View>: View {
    var tint: Color?
    let content: Content

    init(tint: Color? = nil, @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var background: some ShapeStyle {
        if let tint {
            return AnyShapeStyle(tint.opacity(0.12))
        }

        return AnyShapeStyle(Color(.secondarySystemBackground))
    }
}

#Preview {
    BackupExportView()
        .modelContainer(try! AppModelContainerFactory.make(inMemory: true))
}
