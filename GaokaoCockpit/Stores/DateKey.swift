import Foundation

enum DateKey {
    static func todayKey(calendar: Calendar = .current) -> String {
        key(for: .now, calendar: calendar)
    }

    static func key(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 1
        let day = components.day ?? 1
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func startOfDay(for date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    static func weekStart(for date: Date, calendar: Calendar = .current) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? startOfDay(for: date, calendar: calendar)
    }

    static func weekEnd(for date: Date, calendar: Calendar = .current) -> Date {
        let start = weekStart(for: date, calendar: calendar)
        return calendar.date(byAdding: DateComponents(day: 7, second: -1), to: start) ?? start
    }

    static func weekKeyRange(for date: Date, calendar: Calendar = .current) -> ClosedRange<String> {
        key(for: weekStart(for: date, calendar: calendar), calendar: calendar)...key(for: weekEnd(for: date, calendar: calendar), calendar: calendar)
    }

    static func today(calendar: Calendar = .current) -> String {
        todayKey(calendar: calendar)
    }

    static func string(from date: Date, calendar: Calendar = .current) -> String {
        key(for: date, calendar: calendar)
    }
}
