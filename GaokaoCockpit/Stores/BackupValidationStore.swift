import Foundation

struct BackupValidationResult {
    let isReadable: Bool
    let schemaName: String?
    let exportVersion: Int?
    let exportedAt: Date?
    let recordSummary: BackupRecordSummary?
    let integrity: BackupIntegritySummary?
    let warnings: [String]
    let errors: [String]
    let isCountConsistent: Bool
    let checksumMatches: Bool?

    var isValid: Bool {
        isReadable && errors.isEmpty
    }
}

enum BackupValidationStore {
    static func validateBackupFile(url: URL) throws -> BackupValidationResult {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            return BackupValidationResult(
                isReadable: false,
                schemaName: nil,
                exportVersion: nil,
                exportedAt: nil,
                recordSummary: nil,
                integrity: nil,
                warnings: [],
                errors: ["文件无法读取：\(error.localizedDescription)"],
                isCountConsistent: false,
                checksumMatches: nil
            )
        }

        let envelope: GaokaoBackupEnvelope
        do {
            envelope = try BackupChecksum.decode(data)
        } catch {
            return BackupValidationResult(
                isReadable: true,
                schemaName: nil,
                exportVersion: nil,
                exportedAt: nil,
                recordSummary: nil,
                integrity: nil,
                warnings: [],
                errors: ["JSON 无法解析为 GaokaoBackupEnvelope：\(error.localizedDescription)"],
                isCountConsistent: false,
                checksumMatches: nil
            )
        }

        var warnings = envelope.warnings
        var errors: [String] = []

        if envelope.schemaName != GaokaoBackupFormat.schemaName {
            errors.append("schemaName 不支持：\(envelope.schemaName)。")
        }

        if envelope.exportVersion != GaokaoBackupFormat.exportVersion {
            errors.append("exportVersion 不支持：\(envelope.exportVersion)，当前仅支持 1。")
        }

        if envelope.exportSchemaVersion != GaokaoBackupFormat.exportSchemaVersion {
            errors.append("exportSchemaVersion 不支持：\(envelope.exportSchemaVersion)，当前仅支持 1。")
        }

        let actualSummary = BackupRecordSummary(envelope: envelope)
        errors.append(contentsOf: envelope.recordSummary.mismatches(comparedTo: actualSummary))

        let imageTotalBytes = envelope.mistakeImages.reduce(0) { $0 + $1.byteCount }
        if envelope.integrity.imageTotalBytes != imageTotalBytes {
            errors.append(
                "imageTotalBytes 不一致：摘要为 \(envelope.integrity.imageTotalBytes)，实际为 \(imageTotalBytes)。"
            )
        }

        let referencedImagePaths = Set(
            envelope.mistakeRecords
                .map { $0.questionImagePath.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
        let exportedImagePaths = Set(envelope.mistakeImages.map(\.relativePath))
        let missingImageCount = referencedImagePaths.subtracting(exportedImagePaths).count
        if envelope.integrity.missingImageCount != missingImageCount {
            errors.append(
                "missingImageCount 不一致：摘要为 \(envelope.integrity.missingImageCount)，实际为 \(missingImageCount)。"
            )
        }

        if envelope.integrity.warningCount != envelope.warnings.count {
            errors.append(
                "warningCount 不一致：摘要为 \(envelope.integrity.warningCount)，实际 warnings 为 \(envelope.warnings.count)。"
            )
        }

        let checksum = envelope.integrity.displayChecksum
        let checksumMatches: Bool?
        if checksum.isEmpty {
            warnings.append("备份文件未包含 checksum，可能来自 Stage 11 旧格式。")
            checksumMatches = nil
        } else {
            do {
                let recalculatedChecksum = try BackupChecksum.payloadWithoutChecksumSHA256(for: envelope)
                checksumMatches = checksum.lowercased() == recalculatedChecksum
                if checksumMatches == false {
                    errors.append("checksum 不一致：备份内容可能被修改，或编码策略与当前版本不一致。")
                }
            } catch {
                checksumMatches = false
                errors.append("checksum 重新计算失败：\(error.localizedDescription)")
            }
        }

        let isCountConsistent = envelope.recordSummary == actualSummary
            && envelope.recordSummary.mistakeImageCount == envelope.mistakeImages.count
            && envelope.integrity.imageTotalBytes == imageTotalBytes
            && envelope.integrity.missingImageCount == missingImageCount
            && envelope.integrity.warningCount == envelope.warnings.count

        return BackupValidationResult(
            isReadable: true,
            schemaName: envelope.schemaName,
            exportVersion: envelope.exportVersion,
            exportedAt: envelope.exportedAt,
            recordSummary: envelope.recordSummary,
            integrity: envelope.integrity,
            warnings: warnings,
            errors: errors,
            isCountConsistent: isCountConsistent,
            checksumMatches: checksumMatches
        )
    }
}
