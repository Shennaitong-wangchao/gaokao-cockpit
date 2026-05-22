import XCTest
@testable import GaokaoCockpit

final class DateKeyTests: XCTestCase {
    func testKeyUsesSuppliedCalendar() throws {
        let calendar = makeCalendar()
        let date = try makeDate(year: 2026, month: 5, day: 22, hour: 23, calendar: calendar)

        XCTAssertEqual(DateKey.key(for: date, calendar: calendar), "2026-05-22")
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
}
