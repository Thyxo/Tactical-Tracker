import Foundation
import SwiftData

/// Vane-kategorier. Loadout-scoren stiger, når der er balance mellem dem.
enum HabitCategory: String, Codable, CaseIterable, Identifiable {
    case sleep, exercise, learning, family, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sleep: return "Søvn"
        case .exercise: return "Motion"
        case .learning: return "Læring"
        case .family: return "Familie"
        case .other: return "Andet"
        }
    }

    var symbol: String {
        switch self {
        case .sleep: return "bed.double.fill"
        case .exercise: return "figure.run"
        case .learning: return "book.fill"
        case .family: return "person.3.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }

    /// Kategorier der indgår i balance-målingen.
    static let balanced: [HabitCategory] = [.sleep, .exercise, .learning, .family]
}

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "💧"
    var categoryRaw: String = "other"
    /// Calendar-ugedage: 1 = søndag … 7 = lørdag
    var weekdays: [Int] = [1, 2, 3, 4, 5, 6, 7]
    var timesPerDay: Int = 1
    var reminderEnabled: Bool = false
    /// Minutter efter midnat
    var reminderMinutes: Int = 540
    var createdAt: Date = Date()
    var sortOrder: Int = 0
    var archived: Bool = false

    init(name: String, icon: String, category: HabitCategory, weekdays: [Int], timesPerDay: Int,
         reminderEnabled: Bool, reminderMinutes: Int, sortOrder: Int, createdAt: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.categoryRaw = category.rawValue
        self.weekdays = weekdays
        self.timesPerDay = timesPerDay
        self.reminderEnabled = reminderEnabled
        self.reminderMinutes = reminderMinutes
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    var category: HabitCategory {
        get { HabitCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var reminderText: String {
        String(format: "%02d:%02d", reminderMinutes / 60, reminderMinutes % 60)
    }
}

@Model
final class HabitLog {
    var habitID: UUID = UUID()
    var dayKey: String = ""
    var count: Int = 0

    init(habitID: UUID, dayKey: String, count: Int) {
        self.habitID = habitID
        self.dayKey = dayKey
        self.count = count
    }
}

/// Dagsrapport (svarer til Sællivs humør-check-in).
@Model
final class MoodEntry {
    var dayKey: String = ""
    var mood: Int = 3
    var note: String = ""
    var createdAt: Date = Date()

    init(dayKey: String, mood: Int, note: String) {
        self.dayKey = dayKey
        self.mood = mood
        self.note = note
        self.createdAt = Date()
    }
}

@Model
final class OperatorProfile {
    var callsign: String = "Ulv"
    var camoRaw: String = "black"
    var skinRaw: String = "light"
    var onboarded: Bool = false
    var lastProcessedDayKey: String = ""
    var lastBackup: Date? = nil
    var createdAt: Date = Date()
    /// ServiceState som JSON (readiness, credits, rank, udstyr, journal …).
    var serviceData: Data = Data()

    init() {}

    var camo: Camo {
        get { Camo(rawValue: camoRaw) ?? .black }
        set { camoRaw = newValue.rawValue }
    }

    var skin: SkinTone {
        get { SkinTone(rawValue: skinRaw) ?? .light }
        set { skinRaw = newValue.rawValue }
    }

    func loadService() -> ServiceState {
        guard !serviceData.isEmpty,
              let s = try? JSONDecoder().decode(ServiceState.self, from: serviceData) else {
            var fresh = ServiceState()
            fresh.owned = [GearCatalog.defaultBackground]
            return fresh
        }
        return s
    }

    func storeService(_ s: ServiceState) {
        if let d = try? JSONEncoder().encode(s) { serviceData = d }
    }
}

enum ReportChoice: Int, CaseIterable, Identifiable {
    case awful = 1, meh, okay, good, great
    var id: Int { rawValue }
    var emoji: String {
        switch self {
        case .awful: return "😣"
        case .meh: return "😕"
        case .okay: return "😐"
        case .good: return "🙂"
        case .great: return "💪"
        }
    }
    var label: String {
        switch self {
        case .awful: return "Hårdt"
        case .meh: return "Meh"
        case .okay: return "Okay"
        case .good: return "Godt"
        case .great: return "Stærkt"
        }
    }
    var reply: String {
        switch self {
        case .awful: return "Modtaget. Hårde dage tæller også. Vi tager én opgave ad gangen."
        case .meh: return "Forstået. Lav fart er stadig fremdrift. Jeg dækker dig."
        case .okay: return "Okay er en fin status. Holdet kører videre."
        case .good: return "God melding! Fortsæt i det tempo."
        case .great: return "Stærkt! Det er sådan en dag, man husker på holdet."
        }
    }
}
