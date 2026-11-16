import Foundation

/// En lille kopi af appens tilstand, som widgetten kan læse (JSON i App Group-mappen).
struct WidgetHabit: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var icon: String
    var weekdays: [Int]
    var target: Int
    var done: Int
}

struct OperatorSnapshot: Codable {
    var callsign: String
    var camoRaw: String
    var skinRaw: String
    var readiness: Double
    var daysAtZero: Int
    var onLeave: Bool
    var dayKey: String
    var credits: Int
    var rank: Int
    var operation: String
    var equipped: [String]
    var warning: Bool
    var habits: [WidgetHabit]

    static let fileName = "snapshot.json"

    var camo: Camo { Camo(rawValue: camoRaw) ?? .black }
    var skin: SkinTone { SkinTone(rawValue: skinRaw) ?? .light }
    var rankValue: Rank { Rank(rawValue: rank) ?? .recruit }

    var state: ReadinessState {
        ReadinessState.from(readiness: readiness, daysAtZero: daysAtZero, onLeave: onLeave)
    }

    /// Opgaver planlagt på en given dag, med dagens afkrydsninger hvis snapshot er fra samme dag.
    func habits(on date: Date) -> [WidgetHabit] {
        let wd = DayKey.weekday(date)
        let sameDay = DayKey.key(for: date) == dayKey
        return habits
            .filter { $0.weekdays.contains(wd) }
            .map { h in
                var c = h
                if !sameDay { c.done = 0 }
                return c
            }
    }

    static var placeholder: OperatorSnapshot {
        OperatorSnapshot(callsign: "Ulv", camoRaw: Camo.black.rawValue, skinRaw: SkinTone.light.rawValue,
                         readiness: 82, daysAtZero: 0, onLeave: false, dayKey: DayKey.key(), credits: 120,
                         rank: 1, operation: "Operation Kastellet", equipped: ["vest_swat", "helmet_fast"],
                         warning: false,
                         habits: [
                            WidgetHabit(id: "a", name: "8 timers søvn", icon: "🛏️", weekdays: Array(1...7), target: 1, done: 1),
                            WidgetHabit(id: "b", name: "20 min. træning", icon: "🏃", weekdays: Array(1...7), target: 1, done: 0),
                            WidgetHabit(id: "c", name: "Læs 15 min.", icon: "📚", weekdays: Array(1...7), target: 1, done: 0),
                         ])
    }

    static var fileURL: URL { AppGroup.containerURL.appendingPathComponent(fileName) }

    static func load() -> OperatorSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(OperatorSnapshot.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: OperatorSnapshot.fileURL, options: .atomic)
    }

    private mutating func rollToToday() {
        let today = DayKey.key()
        if dayKey != today {
            dayKey = today
            for i in habits.indices { habits[i].done = 0 }
        }
    }

    /// Kaldes fra widgettens knap: afkryds/fortryd og læg ændringen i kø til appen.
    static func toggleFromWidget(habitID: String) {
        guard var snap = load() else { return }
        snap.rollToToday()
        guard let i = snap.habits.firstIndex(where: { $0.id == habitID }) else { return }
        let delta = snap.habits[i].done >= snap.habits[i].target ? -1 : 1
        snap.habits[i].done = max(0, snap.habits[i].done + delta)
        snap.readiness = min(Tuning.readinessMax, max(0, snap.readiness + Double(delta) * Tuning.readinessPerCompletion))
        snap.credits = max(0, snap.credits + delta * Tuning.creditsPerCompletion)
        snap.save()
        PendingQueue.append(PendingToggle(habitID: habitID, dayKey: snap.dayKey, delta: delta))
    }

    /// Kaldes fra Dynamic Island: afkrydser én gang mere (aldrig fortryd).
    @discardableResult
    static func completeFromLiveActivity(habitID: String) -> OperatorSnapshot? {
        guard var snap = load() else { return nil }
        snap.rollToToday()
        guard let i = snap.habits.firstIndex(where: { $0.id == habitID }),
              snap.habits[i].done < snap.habits[i].target else { return nil }
        snap.habits[i].done += 1
        snap.readiness = min(Tuning.readinessMax, snap.readiness + Tuning.readinessPerCompletion)
        snap.credits += Tuning.creditsPerCompletion
        snap.save()
        PendingQueue.append(PendingToggle(habitID: habitID, dayKey: snap.dayKey, delta: 1))
        return snap
    }
}

struct PendingToggle: Codable {
    var habitID: String
    var dayKey: String
    var delta: Int
}

enum PendingQueue {
    static var fileURL: URL { AppGroup.containerURL.appendingPathComponent("pending.json") }

    static func load() -> [PendingToggle] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([PendingToggle].self, from: data)) ?? []
    }

    static func append(_ t: PendingToggle) {
        var list = load()
        list.append(t)
        if let data = try? JSONEncoder().encode(list) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    static func drain() -> [PendingToggle] {
        let list = load()
        try? FileManager.default.removeItem(at: fileURL)
        return list
    }
}
