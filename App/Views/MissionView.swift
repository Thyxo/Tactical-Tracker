import SwiftUI

/// Hovedskærm: operatøren, dagens mission og opgaverne. Bygget som Sællivs hjem-skærm.
struct MissionView: View {
    @Environment(GameStore.self) private var store
    @State private var editing: Habit?
    @State private var creating = false
    @State private var reporting = false
    @State private var settings = false
    @State private var confirmCard = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                OperatorStage(onSettings: { settings = true })
                missionCard
                statusCard
                if store.todayReport == nil && store.profile.onboarded { reportCard }
                taskList
                if store.needsBackupNudge { backupCard }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Theme.night.ignoresSafeArea())
        .sheet(item: $editing) { h in HabitEditorView(habit: h) }
        .sheet(isPresented: $creating) { HabitEditorView(habit: nil) }
        .sheet(isPresented: $reporting) { ReportView().presentationDetents([.medium, .large]) }
        .sheet(isPresented: $settings) { SettingsView() }
        .confirmationDialog("Brug ugens orlovskort i dag?", isPresented: $confirmCard, titleVisibility: .visible) {
            Button("Brug orlovskort") {
                if !store.useLeaveCardToday() { store.flash("Ugens orlovskort er allerede brugt") }
            }
        } message: {
            Text("Dagen tæller ikke: ingen straf, men heller ingen streak. Du har \(Tuning.Penalty.leaveCardsPerWeek) kort pr. uge.")
        }
    }

    // MARK: Dagens mission

    private var missionCard: some View {
        let done = store.todayDone
        let total = store.todayTotal
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: phaseSymbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.tan)
                    .frame(width: 38, height: 38)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.tanLight))
                VStack(alignment: .leading, spacing: 1) {
                    Text(phaseTitle).font(.tac(13, .medium)).foregroundStyle(Theme.textSoft)
                    Text(store.operation).font(.tac(19, .bold)).foregroundStyle(Theme.text)
                        .lineLimit(1).minimumScaleFactor(0.8)
                }
                Spacer()
            }
            if total > 0 {
                ZStack {
                    SegmentBar(progress: Double(done) / Double(total),
                               tint: store.allDoneToday ? Theme.ready : Theme.tan, height: 26)
                    Text(store.allDoneToday ? "Mission complete" : "\(done) / \(total)")
                        .font(.tac(14, .bold))
                        .foregroundStyle(done * 2 >= total ? Theme.onAccent : Theme.text)
                        .contentTransition(.numericText(value: Double(done)))
                }
            }
            Text(phaseHint)
                .font(.tac(13, .medium))
                .foregroundStyle(Theme.textSoft)
                .fixedSize(horizontal: false, vertical: true)
            if showCardButton {
                Button { confirmCard = true } label: {
                    Label("Brug ugens orlovskort", systemImage: "ticket")
                        .font(.tac(13, .semibold))
                        .foregroundStyle(Theme.tan)
                }
            }
        }
        .card()
    }

    private var showCardButton: Bool {
        store.leaveCardAvailable && !store.isTodayExcused && store.todayTotal > 0
            && !store.service.onLeave && !store.allDoneToday
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
        case .briefing: return "sunrise"
        case .mission: return "scope"
        case .debrief: return "moon.stars"
        case .night: return "moon.zzz"
        }
    }

    private var phaseHint: String {
        let total = store.todayTotal
        if total == 0 { return "Fridag – ingen opgaver og ingen straf." }
        if store.isTodayExcused { return "Orlovskort aktivt – dagen tæller ikke." }
        if store.allDoneToday { return "Godt arbejde. Bonus er udbetalt." }
        let needed = Int((Double(total) * Tuning.Penalty.lostDayBelowRatio).rounded(.up))
        if store.todayDone < needed {
            return "Løs mindst \(needed) i dag for at undgå en tabt dag."
        }
        return "\(store.remainingToday) tilbage til mission complete."
    }

    // MARK: Én status ad gangen

    @ViewBuilder private var statusCard: some View {
        if store.service.onLeave {
            notice(Theme.tan, "airplane", "På orlov",
                   "Løs én opgave \(Tuning.leaveReturnStreak) dage i træk for at vende tilbage (\(store.service.leaveReturnStreak)/\(Tuning.leaveReturnStreak)).")
        } else if store.service.warningActive {
            notice(Theme.amber, "exclamationmark.triangle", "Advarsel",
                   "\(store.service.lostStreak) tabte dage i træk. Ved \(Tuning.Penalty.demoteAfterLostDays) rykkes du ét trin ned.")
        } else if let d = store.service.demotedFrom, let r = Rank(rawValue: d) {
            notice(Theme.steady, "arrow.uturn.up", "Comeback \(store.service.comebackStreak)/\(Tuning.Penalty.comebackDays)",
                   "Løs alle opgaver \(Tuning.Penalty.comebackDays) dage i træk for at få \(r.displayName) tilbage.")
        }
    }

    private func notice(_ color: Color, _ symbol: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).font(.system(size: 18, weight: .semibold)).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.tac(15, .bold)).foregroundStyle(Theme.text)
                Text(text).font(.tac(13, .medium)).foregroundStyle(Theme.textSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .card(color.opacity(0.12))
    }

    // MARK: Dagsrapport

    private var reportCard: some View {
        Button { reporting = true } label: {
            HStack(spacing: 12) {
                Text("😣😕😐🙂💪").font(.system(size: 18))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hvordan går det?").font(.tac(16, .bold)).foregroundStyle(Theme.text)
                    Text("Kort dagsrapport – kun for dig").font(.tac(12, .medium)).foregroundStyle(Theme.textSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.textSoft)
            }
            .card()
        }
        .buttonStyle(BouncyStyle(scale: 0.97))
    }

    // MARK: Opgaver

    private var taskList: some View {
        VStack(spacing: 10) {
            HStack {
                Text(store.todayTotal == 0 ? "Opgaver" : (store.remainingToday == 0 ? "Alt løst i dag" : "\(store.remainingToday) tilbage i dag"))
                    .font(.tac(20, .bold))
                    .foregroundStyle(Theme.text)
                Spacer()
                Button { creating = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.onAccent)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Theme.tan))
                }
                .buttonStyle(BouncyStyle())
            }
            .padding(.top, 4)
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
                Text("Ikke i dag")
                    .font(.tac(15, .bold))
                    .foregroundStyle(Theme.textSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)
                ForEach(store.otherHabits) { h in
                    RestingHabitRow(habit: h) { editing = h }
                }
            }
        }
    }

    private var backupCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "externaldrive")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.amber)
            VStack(alignment: .leading, spacing: 2) {
                Text("Lille backup?").font(.tac(15, .bold)).foregroundStyle(Theme.text)
                Text("Sideloadede apps udløber efter 7 dage.").font(.tac(12, .medium)).foregroundStyle(Theme.textSoft)
            }
            Spacer()
            Button("Gem") { settings = true }
                .font(.tac(14, .bold))
                .foregroundStyle(Theme.onAccent)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(Capsule().fill(Theme.tan))
        }
        .card(Theme.amber.opacity(0.12))
    }
}

// MARK: - Scene med operatør

struct OperatorStage: View {
    @Environment(GameStore.self) private var store
    var onSettings: () -> Void = {}
    @State private var poke = 0

    var body: some View {
        let state = store.displayState
        ZStack {
            SceneBackground(id: store.service.background)
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    statusPill(state)
                    Spacer()
                    CreditsBadge(credits: store.service.credits)
                    Button(action: onSettings) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.text)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Theme.surface))
                    }
                    .buttonStyle(BouncyStyle())
                }
                RadioBubble(text: store.radioLine)
                    .padding(.horizontal, 22)
                Spacer(minLength: 0)
            }
            .padding(12)
            OperatorFigure(camo: store.profile.camo, skin: store.profile.skin, state: state,
                           equipped: store.service.equipped, condition: store.service.condition)
                .frame(width: 210, height: 210)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 4)
                .modifier(Wiggle(active: poke % 2 == 1))
                .onTapGesture {
                    poke += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { poke += 1 }
                }
                .sensoryFeedback(.impact(weight: .light), trigger: poke)
        }
        .frame(height: 380)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func statusPill(_ state: ReadinessState) -> some View {
        HStack(spacing: 8) {
            RankInsignia(rank: store.rank, size: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(store.profile.callsign).font(.tac(15, .bold)).foregroundStyle(Theme.text).lineLimit(1)
                SegmentBar(progress: store.service.readiness / Tuning.readinessMax, tint: state.tint, height: 5)
                    .frame(width: 70)
            }
        }
        .padding(.leading, 6)
        .padding(.trailing, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Theme.surface))
    }
}
