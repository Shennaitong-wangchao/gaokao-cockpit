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

#Preview {
    BackupExportView()
        .modelContainer(try! AppModelContainerFactory.make(inMemory: true))
}
