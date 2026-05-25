import Foundation

enum AppDateTime {
    static let timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)!

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.firstWeekday = 2
        return calendar
    }
}

enum DateKey {
    static func todayKey(calendar: Calendar = AppDateTime.calendar) -> String {
        key(for: .now, calendar: calendar)
    }

    static func key(for date: Date, calendar: Calendar = AppDateTime.calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 1
        let day = components.day ?? 1
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func startOfDay(for date: Date, calendar: Calendar = AppDateTime.calendar) -> Date {
        calendar.startOfDay(for: date)
    }

    static func weekStart(for date: Date, calendar: Calendar = AppDateTime.calendar) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? startOfDay(for: date, calendar: calendar)
    }

    static func weekEnd(for date: Date, calendar: Calendar = AppDateTime.calendar) -> Date {
        let start = weekStart(for: date, calendar: calendar)
        return calendar.date(byAdding: DateComponents(day: 7, second: -1), to: start) ?? start
    }

    static func weekKeyRange(for date: Date, calendar: Calendar = AppDateTime.calendar) -> ClosedRange<String> {
        key(for: weekStart(for: date, calendar: calendar), calendar: calendar)...key(for: weekEnd(for: date, calendar: calendar), calendar: calendar)
    }

    static func dateInterval(forKey key: String, calendar: Calendar = AppDateTime.calendar) -> DateInterval? {
        let parts = key.split(separator: "-")
        guard
            parts.count == 3,
            let year = Int(parts[0]),
            let month = Int(parts[1]),
            let day = Int(parts[2])
        else {
            return nil
        }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day

        guard
            let start = calendar.date(from: components),
            let end = calendar.date(byAdding: .day, value: 1, to: start)
        else {
            return nil
        }

        let resolvedComponents = calendar.dateComponents([.year, .month, .day], from: start)
        guard
            resolvedComponents.year == year,
            resolvedComponents.month == month,
            resolvedComponents.day == day
        else {
            return nil
        }

        return DateInterval(start: start, end: end)
    }

    static func exclusiveEnd(after inclusiveEnd: Date, calendar: Calendar = AppDateTime.calendar) -> Date {
        calendar.date(byAdding: .second, value: 1, to: inclusiveEnd) ?? inclusiveEnd
    }

    static func today(calendar: Calendar = AppDateTime.calendar) -> String {
        todayKey(calendar: calendar)
    }

    static func string(from date: Date, calendar: Calendar = AppDateTime.calendar) -> String {
        key(for: date, calendar: calendar)
    }
}
