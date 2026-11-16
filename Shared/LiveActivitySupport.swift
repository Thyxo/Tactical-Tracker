import Foundation
import AppIntents
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit

/// Én opgave, som Live Activity'en viser (hele ContentState skal under 4 KB).
struct LiveHabit: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var icon: String
    var target: Int
    var done: Int

    var isDone: Bool { done >= target }
}

struct MissionActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var readiness: Double
        var stateRaw: String
        var done: Int
        var total: Int
        var operation: String
        var message: String
        var habits: [LiveHabit]? = nil

        var state: ReadinessState { ReadinessState(rawValue: stateRaw) ?? .steady }
        var habitList: [LiveHabit] { habits ?? [] }
        var next: LiveHabit? { habitList.first { !$0.isDone } }
        var allDone: Bool { total > 0 && done >= total }
        var remaining: Int { max(0, total - done) }
        var progress: Double { total > 0 ? min(1, Double(done) / Double(total)) : 0 }
    }

    var callsign: String
    var rank: Int
    var dayKey: String
}

// MARK: - Knap i Dynamic Island

/// Afkrydser næste opgave direkte fra Dynamic Island / låseskærmen.
struct CompleteHabitIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Markér opgave som løst"
    static var description = IntentDescription("Afkrydser dagens næste opgave fra Live Activity.")
    static var isDiscoverable: Bool = false

    @Parameter(title: "Opgave-ID")
    var habitID: String

    init() {}

    init(habitID: String) {
        self.habitID = habitID
    }

    func perform() async throws -> some IntentResult {
        guard let snap = OperatorSnapshot.completeFromLiveActivity(habitID: habitID) else { return .result() }
        await LiveActivityContent.refresh(from: snap)
        return .result()
    }
}

/// Afkryds/fortryd fra hjemmeskærms-widgetten (large).
struct ToggleHabitIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Afkryds opgave"
    static var description = IntentDescription("Afkrydser en opgave for i dag.")
    static var isDiscoverable: Bool = false

    @Parameter(title: "Opgave-ID")
    var habitID: String

    init() {}

    init(habitID: String) {
        self.habitID = habitID
    }

    func perform() async throws -> some IntentResult {
        OperatorSnapshot.toggleFromWidget(habitID: habitID)
        if let snap = OperatorSnapshot.load() {
            await LiveActivityContent.refresh(from: snap)
        }
        return .result()
    }
}

// MARK: - Fælles opbygning og opdatering

enum LiveActivityContent {
    static let dismissAfter: TimeInterval = 30 * 60

    @MainActor private static var finishing = Set<String>()

    static func refresh(from snap: OperatorSnapshot) async {
        WidgetCenter.shared.reloadAllTimelines()
        let state = state(from: snap)
        for activity in Activity<MissionActivityAttributes>.activities
        where activity.attributes.dayKey == snap.dayKey && activity.activityState == .active {
            await apply(state, to: activity, callsign: snap.callsign)
        }
    }

    static func message(done: Int, total: Int, operation: String) -> String {
        if total > 0 && done >= total { return "Mission complete ✅" }
        if done == 0 { return "\(operation) · \(total) opgaver" }
        return "\(operation) · \(total - done) tilbage"
    }

    static func state(from snap: OperatorSnapshot, date: Date = Date()) -> MissionActivityAttributes.ContentState {
        let todays = snap.habits(on: date)
        let habits = todays.map { LiveHabit(id: $0.id, name: $0.name, icon: $0.icon, target: $0.target, done: min($0.done, $0.target)) }
        let total = habits.reduce(0) { $0 + $1.target }
        let done = habits.reduce(0) { $0 + $1.done }
        return .init(readiness: snap.readiness, stateRaw: snap.state.rawValue, done: done, total: total,
                     operation: snap.operation, message: message(done: done, total: total, operation: snap.operation),
                     habits: habits)
    }

    /// Opdaterer aktiviteten. Når alt er klaret: kort alert, derefter afslut.
    static func apply(_ state: MissionActivityAttributes.ContentState,
                      to activity: Activity<MissionActivityAttributes>, callsign: String) async {
        let content = ActivityContent(state: state, staleDate: nil)
        guard state.allDone else {
            await activity.update(content)
            return
        }
        let isNew = await MainActor.run { finishing.insert(activity.id).inserted }
        guard isNew else { return }
        let alert = AlertConfiguration(title: "Mission complete ✅",
                                       body: "\(callsign): \(state.operation) er gennemført.",
                                       sound: .default)
        await activity.update(content, alertConfiguration: alert)
        try? await Task.sleep(for: .seconds(4))
        await activity.end(content, dismissalPolicy: .after(Date().addingTimeInterval(dismissAfter)))
        _ = await MainActor.run { finishing.remove(activity.id) }
    }
}
#endif
