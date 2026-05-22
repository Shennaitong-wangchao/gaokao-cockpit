import XCTest
@testable import GaokaoCockpit

final class BackupValidationStoreTests: XCTestCase {
    func testValidateBackupFileAcceptsMatchingChecksum() throws {
        var envelope = makeEnvelope()
        let checksum = try BackupChecksum.payloadWithoutChecksumSHA256(for: envelope)
        envelope.integrity = envelope.integrity.withPayloadChecksum(checksum)

        let result = try validate(envelope)

        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.isCountConsistent)
        XCTAssertEqual(result.checksumMatches, true)
        XCTAssertTrue(result.errors.isEmpty)
    }

    func testValidateBackupFileReportsRecordCountMismatch() throws {
        var envelope = makeEnvelope()
        envelope.recordSummary = BackupRecordSummary(
            dayPlanCount: 1,
            studyTaskCount: 0,
            focusSessionCount: 0,
            mistakeRecordCount: 0,
            promptTemplateCount: 0,
            resourceItemCount: 0,
            dailyReviewCount: 0,
            weeklyReviewCount: 0,
            mistakeImageCount: 0
        )
        let checksum = try BackupChecksum.payloadWithoutChecksumSHA256(for: envelope)
        envelope.integrity = envelope.integrity.withPayloadChecksum(checksum)

        let result = try validate(envelope)

        XCTAssertFalse(result.isValid)
        XCTAssertFalse(result.isCountConsistent)
        XCTAssertEqual(result.checksumMatches, true)
        XCTAssertTrue(result.errors.contains { $0.contains("dayPlanCount") })
    }

    func testValidateBackupFileAllowsLegacyMissingChecksumWithWarning() throws {
        let result = try validate(makeEnvelope())

        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.checksumMatches)
        XCTAssertTrue(result.warnings.contains { $0.contains("未包含 checksum") })
    }

    private func validate(_ envelope: GaokaoBackupEnvelope) throws -> BackupValidationResult {
        let data = try BackupChecksum.encode(envelope)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        try data.write(to: url, options: [.atomic])
        addTeardownBlock {
            try? FileManager.default.removeItem(at: url)
        }

        return try BackupValidationStore.validateBackupFile(url: url)
    }

    private func makeEnvelope(warnings: [String] = []) -> GaokaoBackupEnvelope {
        let summary = BackupRecordSummary(
            dayPlanCount: 0,
            studyTaskCount: 0,
            focusSessionCount: 0,
            mistakeRecordCount: 0,
            promptTemplateCount: 0,
            resourceItemCount: 0,
            dailyReviewCount: 0,
            weeklyReviewCount: 0,
            mistakeImageCount: 0
        )
        let integrity = BackupIntegritySummary(
            jsonPayloadSHA256: "",
            payloadWithoutChecksumSHA256: "",
            imageTotalBytes: 0,
            missingImageCount: 0,
            warningCount: warnings.count
        )

        return GaokaoBackupEnvelope(
            appName: "Gaokao Cockpit",
            appVersion: "1.0",
            exportVersion: GaokaoBackupFormat.exportVersion,
            schemaName: GaokaoBackupFormat.schemaName,
            exportSchemaVersion: GaokaoBackupFormat.exportSchemaVersion,
            exportedAt: Date(timeIntervalSince1970: 1_700_000_000),
            notes: "Unit test fixture",
            recordSummary: summary,
            integrity: integrity,
            warnings: warnings,
            dayPlans: [],
            studyTasks: [],
            focusSessions: [],
            mistakeRecords: [],
            promptTemplates: [],
            resourceItems: [],
            dailyReviews: [],
            weeklyReviews: [],
            mistakeImages: []
        )
    }
}
