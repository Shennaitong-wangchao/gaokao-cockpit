import XCTest
@testable import GaokaoCockpit

final class DateKeyTests: XCTestCase {
    func testKeyUsesSuppliedCalendar() throws {
        let calendar = makeCalendar()
        let date = try makeDate(year: 2026, month: 5, day: 22, hour: 23, calendar: calendar)

        XCTAssertEqual(DateKey.key(for: date, calendar: calendar), "2026-05-22")
    }

    func testDefaultKeyUsesAppUTC8Calendar() throws {
        let date = try makeUTCDate("2026-05-24T16:30:00Z")

        XCTAssertEqual(DateKey.key(for: date), "2026-05-25")
    }

    func testGreetingUsesCurrentInstantInAppUTC8Calendar() throws {
        let beijingAfternoon = try makeUTCDate("2026-05-25T08:30:00Z")

        XCTAssertEqual(EncouragementSystem.getGreeting(for: beijingAfternoon), "下午好！继续保持专注")
    }

    func testGreetingUsesExpectedUTC8TimeSegments() throws {
        let cases = [
            ("2026-05-24T16:30:00Z", "凌晨了，先放轻一点"),
            ("2026-05-24T21:30:00Z", "早起好！新的一天开始了"),
            ("2026-05-25T00:30:00Z", "上午好！学习的黄金时间"),
            ("2026-05-25T04:30:00Z", "中午好！记得休息一下"),
            ("2026-05-25T08:30:00Z", "下午好！继续保持专注"),
            ("2026-05-25T10:30:00Z", "晚上好！稳稳收束今天"),
            ("2026-05-25T14:30:00Z", "深夜了，注意休息")
        ]

        for (dateString, expectedGreeting) in cases {
            XCTAssertEqual(
                EncouragementSystem.getGreeting(for: try makeUTCDate(dateString)),
                expectedGreeting,
                dateString
            )
        }
    }

    func testWeekKeyRangeCrossesYearBoundary() throws {
        var calendar = makeCalendar()
        calendar.firstWeekday = 2
        let date = try makeDate(year: 2026, month: 1, day: 1, calendar: calendar)

        let range = DateKey.weekKeyRange(for: date, calendar: calendar)

        XCTAssertEqual(range.lowerBound, "2025-12-29")
        XCTAssertEqual(range.upperBound, "2026-01-04")
    }

    func testDateIntervalForKeyBuildsOneCalendarDay() throws {
        let calendar = makeCalendar()
        let interval = try XCTUnwrap(DateKey.dateInterval(forKey: "2026-05-22", calendar: calendar))

        XCTAssertEqual(DateKey.key(for: interval.start, calendar: calendar), "2026-05-22")
        XCTAssertEqual(DateKey.key(for: interval.end, calendar: calendar), "2026-05-23")
    }

    func testDateIntervalRejectsMalformedKey() {
        XCTAssertNil(DateKey.dateInterval(forKey: "2026/05/22", calendar: makeCalendar()))
    }

    func testDateIntervalRejectsImpossibleDate() {
        XCTAssertNil(DateKey.dateInterval(forKey: "2026-02-30", calendar: makeCalendar()))
    }

    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)!
        return calendar
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 12,
        calendar: Calendar
    ) throws -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour

        return try XCTUnwrap(calendar.date(from: components))
    }

    private func makeUTCDate(_ value: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        return try XCTUnwrap(formatter.date(from: value))
    }
}
