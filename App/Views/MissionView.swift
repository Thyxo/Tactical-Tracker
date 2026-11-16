import SwiftUI

/// Hovedskærm: morgen-briefing, dagens mission og aftens-debrief.
struct MissionView: View {
    @Environment(GameStore.self) private var store
    @State private var editing: Habit?
    @State private var creating = false
    @State private var reporting = false
    @State private var settings = false
    @State private var confirmCard = false
    @State private var showJournal = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                header
                OperatorStage()
                ReadinessPanel()
                phaseCard
                statusCards
                taskList
                if store.needsBackupNudge { backupCard }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.night.ignoresSafeArea())
        .sheet(item: $editing) { h in HabitEditorView(habit: h) }
        .sheet(isPresented: $creating) { HabitEditorView(habit: nil) }
        .sheet(isPresented: $reporting) { ReportView().presentationDetents([.medium, .large]) }
        .sheet(isPresented: $settings) { SettingsView() }
        .sheet(isPresented: $showJournal) { JournalView() }
        .confirmationDialog("Brug ugens orlovskort i dag?", isPresented: $confirmCard, titleVisibility: .visible) {
            Button("Brug orlovskort") {
                if !store.useLeaveCardToday() { store.flash("Ugens orlovskort er allerede brugt") }
            }
        } message: {
            Text("Dagen tæller ikke: ingen straf, men heller ingen streak. Du har \(Tuning.Penalty.leaveCardsPerWeek) kort pr. uge.")
        }
    }

    // MARK: Top

    private var header: some View {
        HStack(spacing: 10) {
            RankInsignia(rank: store.rank, size: 38)
            VStack(alignment: .leading, spacing: 1) {
                Text(store.rank.displayName.uppercased())
                    .font(.stencil(11, .bold))
                    .foregroundStyle(Theme.tan)
                Text(store.profile.callsign)
                    .font(.tac(24, .heavy))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
            }
            Spacer()
            CreditsBadge(credits: store.service.credits)
            Button { settings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.textSoft)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.panel))
            }
            .buttonStyle(BouncyStyle())
        }
        .padding(.top, 8)
    }

    // MARK: Briefing / mission / debrief

    @ViewBuilder private var phaseCard: some View {
        let done = store.todayDone
        let total = store.todayTotal
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionLabel(text: phaseTitle, symbol: phaseSymbol)
                Spacer()
                Text(store.operation.uppercased())
                    .font(.stencil(10, .bold))
                    .foregroundStyle(Theme.tan)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            if total == 0 {
                Text("Ingen planlagte opgaver i dag. Fridag – ingen straf.")
                    .font(.tac(14, .medium)).foregroundStyle(Theme.textSoft)
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(done)/\(total)")
                        .font(.stencil(30, .black))
                        .foregroundStyle(store.allDoneToday ? Theme.ready : Theme.text)
                        .contentTransition(.numericText(value: Double(done)))
                    Text(store.allDoneToday ? "MISSION COMPLETE" : "opgaver løst")
                        .font(.stencil(12, .bold))
                        .foregroundStyle(store.allDoneToday ? Theme.ready : Theme.textSoft)
                    Spacer()
                }
                SegmentBar(progress: total > 0 ? Double(done) / Double(total) : 0,
                           tint: store.allDoneToday ? Theme.ready : Theme.tan, segments: max(total, 1) * 2, height: 8)
                Text(phaseHint)
                    .font(.tac(13, .medium))
                    .foregroundStyle(Theme.textSoft)
            }
            HStack(spacing: 8) {
                smallButton(store.todayReport == nil ? "Dagsrapport" : "Rapport ✓", "text.bubble.fill") { reporting = true }
                if store.leaveCardAvailable && !store.isTodayExcused && store.todayTotal > 0 && !store.service.onLeave && !store.allDoneToday {
                    smallButton("Orlovskort", "ticket.fill") { confirmCard = true }
                }
                smallButton("Journal", "list.bullet.clipboard") { showJournal = true }
            }
        }
        .card()
    }

    private var phaseTitle: String {
        switch store.phase {
        case .briefing: return "Morgen-briefing"
        case .mission: return "Dagens mission"
        case .debrief: return "Aftens-debrief"
        case .night: return "Nattevagt"
        }
    }

    private var phaseSymbol: String {
        switch store.phase {
        case .briefing: return "sunrise.fill"
        case .mission: return "scope"
        case .debrief: return "moon.stars.fill"
        case .night: return "moon.zzz.fill"
        }
    }

    private var phaseHint: String {
        if store.isTodayExcused { return "Orlovskort aktivt – dagen tæller ikke." }
        if store.allDoneToday { return "Alle opgaver løst. Bonus udbetalt: +\(Tuning.creditsAllDoneBonus) credits, +\(Tuning.xpAllDoneBonus) xp." }
        let total = store.todayTotal
        let needed = Int((Double(total) * Tuning.Penalty.lostDayBelowRatio).rounded(.up))
        switch store.phase {
        case .briefing:
            return "Dagens ordre: \(total) opgaver. Løs mindst \(needed) for at undgå en tabt dag."
        case .debrief, .night:
            if store.todayDone < needed { return "⚠️ Under \(needed) løst = tabt dag ved midnat: −\(Int(Tuning.Penalty.readinessMissedDay)) readiness, bøde og slid." }
            return "Godt holdt. \(store.remainingToday) tilbage til mission complete."
        case .mission:
            return "\(store.remainingToday) tilbage. Under \(needed) løst ved midnat tæller som en tabt dag."
        }
    }

    private func smallButton(_ title: String, _ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.tac(12, .bold))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Capsule().fill(Theme.panelHigh))
        }
        .buttonStyle(BouncyStyle())
    }

    // MARK: Status (disciplinærsag, comeback, orlov)

    @ViewBuilder private var statusCards: some View {
        if store.service.onLeave {
            alertCard(color: Theme.tan, symbol: "airplane",
                      title: "På orlov",
                      text: "Ingen straf under orlov. Løs mindst én opgave \(Tuning.leaveReturnStreak) dage i træk for at vende tilbage (\(store.service.leaveReturnStreak)/\(Tuning.leaveReturnStreak)).")
        }
        if store.service.warningActive {
            alertCard(color: Theme.amber, symbol: "exclamationmark.triangle.fill",
                      title: "Disciplinærsag – advarsel",
                      text: "\(store.service.lostStreak) tabte dage i træk. Ved \(Tuning.Penalty.demoteAfterLostDays) rykkes du ét trin ned. En dag med mindst halvdelen løst lukker sagen.")
        }
        if let d = store.service.demotedFrom, let r = Rank(rawValue: d) {
            alertCard(color: Theme.steady, symbol: "arrow.uturn.up.circle.fill",
                      title: "Comeback \(store.service.comebackStreak)/\(Tuning.Penalty.comebackDays)",
                      text: "Løs alle opgaver \(Tuning.Penalty.comebackDays) planlagte dage i træk for at få \(r.displayName) tilbage.")
        }
        if Discipline.inGrace(store.service, dayKey: store.todayKey) {
            alertCard(color: Theme.ready, symbol: "hand.raised.fill",
                      title: "Nådeperiode",
                      text: "Ny rank: ingen bøder eller nedrykning de første \(Tuning.Penalty.graceDaysAfterNewRank) dage.")
        }
    }

    private func alertCard(color: Color, symbol: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).font(.system(size: 20, weight: .bold)).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.tac(15, .heavy)).foregroundStyle(Theme.text)
                Text(text).font(.tac(13, .medium)).foregroundStyle(Theme.textSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(color.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(color.opacity(0.5), lineWidth: 1))
    }

    // MARK: Opgaver

    private var taskList: some View {
        VStack(spacing: 8) {
            HStack {
                SectionLabel(text: "Opgaver i dag", symbol: "checklist")
                Button { creating = true } label: {
                    Label("Ny", systemImage: "plus")
                        .font(.tac(13, .heavy))
                        .foregroundStyle(Theme.night)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.tan))
                }
                .buttonStyle(BouncyStyle())
            }
            if store.habits.isEmpty {
                Text("Ingen opgaver endnu. Tilføj din første – fx søvn, træning, lektier eller familietid.")
                    .font(.tac(14, .medium))
                    .foregroundStyle(Theme.textSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
            }
            ForEach(Array(store.todayHabits.enumerated()), id: \.element.id) { i, h in
                HabitRow(habit: h, index: i) { editing = h }
                    .appearIn(Double(i) * 0.04)
            }
            if !store.otherHabits.isEmpty {
                SectionLabel(text: "Ikke planlagt i dag", symbol: "calendar")
                    .padding(.top, 6)
                ForEach(store.otherHabits) { h in
                    RestingHabitRow(habit: h) { editing = h }
                }
            }
        }
    }

    private var backupCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "externaldrive.fill.badge.timemachine")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.amber)
            VStack(alignment: .leading, spacing: 2) {
                Text("Tid til backup").font(.tac(15, .heavy)).foregroundStyle(Theme.text)
                Text("Sideloadede apps udløber efter 7 dage. Gem din journal (+\(Tuning.creditsBackup) cr).")
                    .font(.tac(12, .medium)).foregroundStyle(Theme.textSoft)
            }
            Spacer()
            Button("Åbn") { settings = true }
                .font(.tac(13, .heavy))
                .foregroundStyle(Theme.night)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Capsule().fill(Theme.amber))
        }
        .card()
    }
}

// MARK: - Scene med operatør

struct OperatorStage: View {
    @Environment(GameStore.self) private var store
    @State private var poke = 0

    var body: some View {
        let state = store.displayState
        ZStack {
            SceneBackground(id: store.service.background)
            LinearGradient(colors: [.clear, Theme.night.opacity(0.5)], startPoint: .center, endPoint: .bottom)
            OperatorFigure(camo: store.profile.camo, skin: store.profile.skin, state: state,
                           equipped: store.service.equipped, condition: store.service.condition)
                .frame(width: 230, height: 230)
                .offset(y: 22)
                .modifier(Wiggle(active: poke % 2 == 1))
                .onTapGesture {
                    poke += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { poke += 1 }
                }
                .sensoryFeedback(.impact(weight: .light), trigger: poke)
            VStack {
                RadioBubble(text: store.radioLine)
                    .padding(10)
                Spacer()
                HStack {
                    Label(state.displayName.uppercased(), systemImage: state.symbol)
                        .font(.stencil(12, .heavy))
                        .foregroundStyle(Theme.night)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(state.tint))
                    Spacer()
                    Text("SCORE \(store.loadoutScore)")
                        .font(.stencil(12, .heavy))
                        .foregroundStyle(Theme.text)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(Color.black.opacity(0.55)))
                }
                .padding(10)
            }
        }
        .frame(height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }
}

struct ReadinessPanel: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        let r = store.service.readiness
        let state = store.readinessState
        VStack(spacing: 8) {
            HStack {
                Text("READINESS").font(.stencil(12, .bold)).foregroundStyle(Theme.textSoft)
                Spacer()
                Text("\(Int(r.rounded()))")
                    .font(.stencil(20, .black))
                    .foregroundStyle(state.tint)
                    .contentTransition(.numericText(value: r))
                Text("/ 100").font(.stencil(12, .bold)).foregroundStyle(Theme.textSoft)
            }
            SegmentBar(progress: r / Tuning.readinessMax, tint: state.tint)
            HStack {
                xpLine
                Spacer()
                Text("Streak \(store.service.missionStreak) 🔥")
                    .font(.stencil(11, .bold))
                    .foregroundStyle(Theme.textSoft)
            }
        }
        .card()
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: r)
    }

    @ViewBuilder private var xpLine: some View {
        let xp = store.service.xp
        if let next = store.rank.next, store.service.demotedFrom == nil {
            Text("\(xp)/\(next.xpNeeded) xp → \(next.displayName)")
                .font(.stencil(11, .bold)).foregroundStyle(Theme.textSoft)
        } else {
            Text("\(xp) xp").font(.stencil(11, .bold)).foregroundStyle(Theme.textSoft)
        }
    }
}
