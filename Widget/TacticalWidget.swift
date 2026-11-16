import WidgetKit
import SwiftUI
import AppIntents
import ActivityKit

@main
struct TacticalWidgetBundle: WidgetBundle {
    var body: some Widget {
        MissionWidget()
        MissionLiveActivity()
    }
}

// MARK: - Tidslinje

struct MissionEntry: TimelineEntry {
    let date: Date
    let snapshot: OperatorSnapshot
}

struct MissionProvider: TimelineProvider {
    func placeholder(in context: Context) -> MissionEntry {
        MissionEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (MissionEntry) -> Void) {
        completion(MissionEntry(date: Date(), snapshot: OperatorSnapshot.load() ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MissionEntry>) -> Void) {
        let snap = OperatorSnapshot.load() ?? .placeholder
        let now = Date()
        let cal = Calendar.current
        let midnight = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: now) ?? now)
        let entries = [MissionEntry(date: now, snapshot: snap), MissionEntry(date: midnight, snapshot: snap)]
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(30 * 60))))
    }
}

// MARK: - Hjemmeskærms-widget

struct MissionWidget: Widget {
    let kind = "MissionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MissionProvider()) { entry in
            MissionWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetBackdrop() }
        }
        .configurationDisplayName("Dagens mission")
        .description("Readiness, rank og dagens opgaver – afkryds direkte.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct WidgetBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x161D23), Color(hex: 0x0E1317)], startPoint: .top, endPoint: .bottom)
            GridLines().stroke(Color.white.opacity(0.04), lineWidth: 1)
        }
    }
}

struct GridLines: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let step: CGFloat = 16
        var x: CGFloat = 0
        while x < r.width {
            p.move(to: CGPoint(x: x, y: 0))
            p.addLine(to: CGPoint(x: x, y: r.height))
            x += step
        }
        var y: CGFloat = 0
        while y < r.height {
            p.move(to: CGPoint(x: 0, y: y))
            p.addLine(to: CGPoint(x: r.width, y: y))
            y += step
        }
        return p
    }
}

struct MissionWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MissionEntry

    private var snap: OperatorSnapshot { entry.snapshot }
    private var state: MissionActivityAttributes.ContentState { LiveActivityContent.state(from: snap, date: entry.date) }
    private var figureState: ReadinessState { state.allDone && !snap.onLeave ? .ready : snap.state }

    var body: some View {
        switch family {
        case .systemSmall: small
        case .systemLarge: large
        default: medium
        }
    }

    private func figure(_ size: CGFloat) -> some View {
        OperatorFigure(camo: snap.camo, skin: snap.skin, state: figureState, equipped: snap.equipped, animated: false)
            .frame(width: size, height: size)
    }

    private var readinessBar: some View {
        let r = snap.readiness / Tuning.readinessMax
        return GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule().fill(snap.state.tint).frame(width: max(4, g.size.width * r))
            }
        }
        .frame(height: 5)
    }

    private var headline: some View {
        HStack(spacing: 4) {
            Text(snap.rankValue.short).font(.stencil(10, .heavy)).foregroundStyle(Theme.tan)
            Text(snap.callsign).font(.tac(13, .heavy)).foregroundStyle(Theme.text).lineLimit(1)
        }
    }

    private var progressText: some View {
        Group {
            if snap.onLeave {
                Text("PÅ ORLOV").foregroundStyle(Theme.tan)
            } else if state.total == 0 {
                Text("FRIDAG").foregroundStyle(Theme.textSoft)
            } else if state.allDone {
                Text("MISSION COMPLETE").foregroundStyle(Theme.ready)
            } else {
                Text("\(state.done)/\(state.total) LØST").foregroundStyle(Theme.text)
            }
        }
        .font(.stencil(11, .heavy))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    // MARK: Small

    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            headline
            HStack {
                Spacer()
                figure(86)
                Spacer()
            }
            progressText
            readinessBar
        }
    }

    // MARK: Medium

    private var medium: some View {
        HStack(spacing: 10) {
            VStack(spacing: 4) {
                figure(108)
                readinessBar.frame(width: 90)
                Text("READINESS \(Int(snap.readiness))").font(.stencil(9, .bold)).foregroundStyle(Theme.textSoft)
            }
            VStack(alignment: .leading, spacing: 5) {
                headline
                Text(snap.operation.uppercased()).font(.stencil(9, .bold)).foregroundStyle(Theme.tan).lineLimit(1)
                progressText
                ForEach(state.habitList.prefix(3)) { h in
                    HStack(spacing: 6) {
                        Image(systemName: h.isDone ? "checkmark.square.fill" : "square")
                            .foregroundStyle(h.isDone ? Theme.ready : Theme.textSoft)
                        Text(h.name).font(.tac(12, .semibold))
                            .foregroundStyle(h.isDone ? Theme.textSoft : Theme.text)
                            .strikethrough(h.isDone)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: Large (afkrydsning)

    private var large: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                figure(96)
                VStack(alignment: .leading, spacing: 4) {
                    headline
                    Text(snap.operation.uppercased()).font(.stencil(10, .bold)).foregroundStyle(Theme.tan).lineLimit(1)
                    progressText
                    readinessBar
                    if snap.warning {
                        Label("Disciplinærsag", systemImage: "exclamationmark.triangle.fill")
                            .font(.tac(10, .bold)).foregroundStyle(Theme.amber)
                    }
                }
            }
            if state.habitList.isEmpty {
                Text(snap.onLeave ? "På orlov – ingen straf." : "Ingen opgaver i dag.")
                    .font(.tac(13, .medium)).foregroundStyle(Theme.textSoft)
            }
            ForEach(state.habitList.prefix(6)) { h in
                Button(intent: ToggleHabitIntent(habitID: h.id)) {
                    HStack(spacing: 8) {
                        Text(h.icon).font(.system(size: 16))
                        Text(h.name).font(.tac(13, .semibold))
                            .foregroundStyle(h.isDone ? Theme.textSoft : Theme.text)
                            .strikethrough(h.isDone)
                            .lineLimit(1)
                        Spacer()
                        if h.target > 1 {
                            Text("\(h.done)/\(h.target)").font(.stencil(11, .bold)).foregroundStyle(Theme.textSoft)
                        }
                        Image(systemName: h.isDone ? "checkmark.square.fill" : "square")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(h.isDone ? Theme.ready : Theme.textSoft)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Live Activity

struct MissionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MissionActivityAttributes.self) { context in
            LockScreenMissionView(context: context)
                .activityBackgroundTint(Color(hex: 0x10161B))
                .activitySystemActionForegroundColor(Theme.tan)
        } dynamicIsland: { context in
            let st = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Rank(rawValue: context.attributes.rank)?.short ?? "")
                            .font(.stencil(10, .heavy)).foregroundStyle(Theme.tan)
                        Text(context.attributes.callsign).font(.tac(14, .heavy)).foregroundStyle(.white).lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(st.remaining)").font(.stencil(24, .black)).foregroundStyle(st.allDone ? Theme.ready : .white)
                        Text("tilbage").font(.tac(10, .semibold)).foregroundStyle(.white.opacity(0.7))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        MissionSegments(state: st).frame(height: 6)
                        if let next = st.next {
                            Button(intent: CompleteHabitIntent(habitID: next.id)) {
                                HStack {
                                    Text(next.icon)
                                    Text(next.name).font(.tac(14, .bold)).lineLimit(1)
                                    Spacer()
                                    Label("Løst", systemImage: "checkmark")
                                        .font(.tac(13, .heavy))
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(Capsule().fill(Theme.tan))
                                        .foregroundStyle(Theme.night)
                                }
                                .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text("Mission complete ✅").font(.tac(14, .bold)).foregroundStyle(Theme.ready)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: st.state.symbol).foregroundStyle(st.state.tint)
            } compactTrailing: {
                Text("\(st.remaining)").font(.stencil(14, .heavy)).foregroundStyle(st.allDone ? Theme.ready : .white)
            } minimal: {
                Text("\(st.remaining)").font(.stencil(13, .heavy)).foregroundStyle(Theme.tan)
            }
        }
    }
}

struct MissionSegments: View {
    let state: MissionActivityAttributes.ContentState

    var body: some View {
        let total = max(1, state.total)
        HStack(spacing: 2) {
            ForEach(0..<total, id: \.self) { i in
                Capsule().fill(i < state.done ? Theme.ready : Color.white.opacity(0.18))
            }
        }
    }
}

struct LockScreenMissionView: View {
    let context: ActivityViewContext<MissionActivityAttributes>

    var body: some View {
        let st = context.state
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Image(systemName: st.state.symbol)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(st.state.tint)
                Text("\(Int(st.readiness))").font(.stencil(13, .heavy)).foregroundStyle(.white)
                Text("READY").font(.stencil(7, .bold)).foregroundStyle(.white.opacity(0.6))
            }
            .frame(width: 50)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(st.operation.uppercased()).font(.stencil(11, .heavy)).foregroundStyle(Theme.tan).lineLimit(1)
                    Spacer()
                    Text("\(st.done)/\(st.total)").font(.stencil(13, .heavy)).foregroundStyle(.white)
                }
                MissionSegments(state: st).frame(height: 6)
                if let next = st.next {
                    Button(intent: CompleteHabitIntent(habitID: next.id)) {
                        HStack(spacing: 6) {
                            Text(next.icon)
                            Text("Næste: \(next.name)").font(.tac(13, .semibold)).lineLimit(1)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.tan)
                        }
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(st.message).font(.tac(13, .semibold)).foregroundStyle(Theme.ready)
                }
            }
        }
        .padding(14)
    }
}
