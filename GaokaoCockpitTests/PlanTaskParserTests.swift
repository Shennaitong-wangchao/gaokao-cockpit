import XCTest
@testable import GaokaoCockpit

final class PlanTaskParserTests: XCTestCase {
    func testParseLinesCleansListMarkersAndDeduplicatesTitles() {
        let text = """
        1. 函数导数压轴题
        - 英语阅读 C 篇精读
        [ ] 函数导数压轴题
        • 物理模型复盘
        """

        let lines = PlanTaskParser.parseLines(from: text)

        XCTAssertEqual(lines, [
            "函数导数压轴题",
            "英语阅读 C 篇精读",
            "物理模型复盘"
        ])
    }

    func testParsePlanSectionsMapsSourcesAndSkipsCrossSectionDuplicates() {
        let tasks = PlanTaskParser.parsePlanSections(
            top: "函数导数压轴题",
            baseline: "函数导数压轴题\n英语阅读复盘",
            bonus: "数学加分题"
        )

        XCTAssertEqual(tasks.map(\.title), [
            "函数导数压轴题",
            "英语阅读复盘",
            "数学加分题"
        ])
        XCTAssertEqual(tasks.map(\.source), [
            PlanTaskParser.Source.top,
            PlanTaskParser.Source.baseline,
            PlanTaskParser.Source.bonus
        ])
        XCTAssertEqual(tasks.map(\.category), [
            StudyTaskCategory.exercise.storageValue,
            StudyTaskCategory.review.storageValue,
            StudyTaskCategory.other.storageValue
        ])
    }

    func testNormalizedTitleKeyCollapsesWhitespaceAndCase() {
        XCTAssertEqual(
            PlanTaskParser.normalizedTitleKey("  English   Reading  "),
            "english reading"
        )
    }
}
