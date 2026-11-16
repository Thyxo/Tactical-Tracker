import Foundation

// MARK: - Rank

enum Rank: Int, Codable, CaseIterable, Identifiable, Comparable {
    case recruit = 0, constable, sergeant, lieutenant, captain

    var id: Int { rawValue }

    static func < (a: Rank, b: Rank) -> Bool { a.rawValue < b.rawValue }

    var displayName: String {
        switch self {
        case .recruit: return "Rekrut"
        case .constable: return "Konstabel"
        case .sergeant: return "Sergent"
        case .lieutenant: return "Løjtnant"
        case .captain: return "Kaptajn"
        }
    }

    var short: String {
        switch self {
        case .recruit: return "REK"
        case .constable: return "KST"
        case .sergeant: return "SG"
        case .lieutenant: return "LT"
        case .captain: return "KN"
        }
    }

    /// Antal vinkler/stjerner til distinktionen.
    var chevrons: Int {
        switch self {
        case .recruit: return 0
        case .constable: return 1
        case .sergeant: return 2
        case .lieutenant: return 1
        case .captain: return 2
        }
    }

    var isOfficer: Bool { self >= .lieutenant }

    var xpNeeded: Int {
        let t = Tuning.rankThresholds
        return rawValue < t.count ? t[rawValue] : (t.last ?? 0)
    }

    var next: Rank? { Rank(rawValue: rawValue + 1) }
    var previous: Rank? { Rank(rawValue: rawValue - 1) }

    /// Højeste rank man har point nok til.
    static func forXP(_ xp: Int) -> Rank {
        var r = Rank.recruit
        for rank in Rank.allCases where xp >= rank.xpNeeded { r = rank }
        return r
    }
}

