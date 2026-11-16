import Foundation

// MARK: - Dag-nøgler

enum DayKey {
    static func key(for date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func date(from key: String) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    static func weekday(_ date: Date) -> Int {
        Calendar.current.component(.weekday, from: date)
    }

    /// Uge-nøgle (ISO-uge, mandag først), fx "2026-W47". Bruges til orlovskort.
    static func weekKey(for date: Date = Date()) -> String {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = Calendar.current.timeZone
        let c = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return String(format: "%04d-W%02d", c.yearForWeekOfYear ?? 0, c.weekOfYear ?? 0)
    }

    /// Antal hele dage mellem to dag-nøgler (b - a).
    static func days(from a: String, to b: String) -> Int? {
        guard let da = date(from: a), let db = date(from: b) else { return nil }
        return Calendar.current.dateComponents([.day], from: da, to: db).day
    }

    /// Stabil hash (Swifts hashValue ændrer sig mellem kørsler).
    static func stableHash(_ s: String) -> Int {
        var h = 5381
        for u in s.unicodeScalars {
            h = (h &* 33 &+ Int(u.value)) & 0x7fffffff
        }
        return h
    }
}

