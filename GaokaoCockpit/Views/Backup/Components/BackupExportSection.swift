import Foundation
import SwiftUI

struct BackupHeaderCard: View {
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

struct BackupResultCard: View {
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

struct BackupValidationResultView: View {
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
