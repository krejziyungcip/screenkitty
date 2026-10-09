import Foundation

/// Small date helpers shared by the mood and nag engines.
public enum DayMath {
    public static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    public static func isSameDay(_ a: Date, _ b: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }

    public static func daysBetween(_ a: Date, _ b: Date, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: startOfDay(a, calendar: calendar),
                                to: startOfDay(b, calendar: calendar)).day ?? 0
    }

    /// "20261009" style key used for deterministic notification IDs.
    public static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Date on the same day as `date` at the given hour/minute.
    public static func date(_ date: Date, hour: Int, minute: Int = 0, calendar: Calendar = .current) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }
}
