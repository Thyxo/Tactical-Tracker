import SwiftUI

struct RankView: View {
    @Environment(GameStore.self) private var store
    @State private var journal = false
    @State private var rules = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                HStack {
                    Text("Rank & meritter").font(.tac(26, .heavy)).foregroundStyle(Theme.text)
                    Spacer()
                }
                .padding(.top, 8)
                ladder
                statsCard
                HeatmapCard()
                meritsCard
                HStack(spacing: 8) {
                    Button { journal = true } label: { Label("Tjenestejournal", systemImage: "list.bullet.clipboard") }
                    Button { rules = true } label: { Label("Regler & straf", systemImage: "scale.3d") }
                }
                .font(.tac(13, .bold))
                .buttonStyle(.bordered)
                .tint(Theme.tan)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.night.ignoresSafeArea())
        .sheet(isPresented: $journal) { JournalView() }
        .sheet(isPresented: $rules) { RulesView() }
    }

    private var ladder: some View {
        let s = store.service
        return VStack(spacing: 8) {
            ForEach(Rank.allCases.reversed()) { r in
                let current = r.rawValue == s.rank
                let reached = r.rawValue <= s.rank
                let lost = s.demotedFrom.map { r.rawValue > s.rank && r.rawValue <= $0 } ?? false
                HStack(spacing: 12) {
                    RankInsignia(rank: r, size: 34).opacity(reached || lost ? 1 : 0.4)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(r.displayName).font(.tac(16, .heavy)).foregroundStyle(reached ? Theme.text : Theme.textSoft)
                        Text(lost ? "Mistet – vind tilbage med comeback" : "\(r.xpNeeded) xp")
                            .font(.stencil(11, .bold)).foregroundStyle(lost ? Theme.amber : Theme.textSoft)
                    }
                    Spacer()
                    if current {
                        Text("NU").font(.stencil(11, .heavy)).foregroundStyle(.white)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Capsule().fill(Theme.tan))
                    } else if reached {
                        Image(systemName: "checkmark").foregroundStyle(Theme.ready)
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(current ? Theme.tan.opacity(0.12) : Theme.panel))
            }
            if let next = store.rank.next, s.demotedFrom == nil {
                let prev = store.rank.xpNeeded
                let p = Double(s.xp - prev) / Double(max(1, next.xpNeeded - prev))
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(s.xp) / \(next.xpNeeded) xp til \(next.displayName)").font(.stencil(11, .bold)).foregroundStyle(Theme.textSoft)
                    SegmentBar(progress: p, tint: Theme.tan, segments: 24, height: 8)
                }
                .padding(.top, 4)
            }
        }
        .card()
    }

    private var statsCard: some View {
        let s = store.service
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            stat("Streak", "\(s.missionStreak)")
            stat("Bedste", "\(s.bestMissionStreak)")
            stat("Missioner", "\(s.missionsCompleted)")
            stat("Tabte i træk", "\(s.lostStreak)")
            stat("Credits i alt", "\(s.lifetimeCredits)")
            stat("Comebacks", "\(s.comebacks)")
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.stencil(20, .black)).foregroundStyle(Theme.text)
            Text(title).font(.stencil(11, .bold)).foregroundStyle(Theme.textSoft).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.panel))
    }

    private var meritsCard: some View {
        let earned = store.service.merits
        return VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Meritter \(earned.count)/\(Merits.all.count)", symbol: "rosette")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 10) {
                ForEach(Merits.all) { m in
                    let has = earned[m.id] != nil
                    VStack(spacing: 4) {
                        Image(systemName: m.symbol)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(has ? Color.white : Theme.textSoft)
                            .frame(width: 46, height: 46)
                            .background(Circle().fill(has ? Theme.gold : Theme.panelHigh))
                        Text(m.name).font(.tac(9, .bold)).foregroundStyle(has ? Theme.text : Theme.textSoft)
                            .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.8)
                    }
                    .help(m.detail)
                    .contextMenu { Text(m.detail) }
                }
            }
            Text("Hold fingeren på en merit for at se kravet.").font(.tac(10, .medium)).foregroundStyle(Theme.textSoft)
        }
        .card()
    }
}

/// Kalender over de sidste 5 uger: grøn = mission complete, gul = delvis, rød = tabt, grå = fri.
struct HeatmapCard: View {
    @Environment(GameStore.self) private var store
    static let days = ["M", "T", "O", "T", "F", "L", "S"]

    var body: some View {
        let cells = buildCells()
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Sidste 5 uger", symbol: "calendar")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(0..<7, id: \.self) { i in
                    Text(Self.days[i]).font(.stencil(11, .bold)).foregroundStyle(Theme.textSoft)
                }
                ForEach(7..<(7 + cells.count), id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(cells[i - 7])
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            HStack(spacing: 10) {
                legend(Theme.ready, "Complete")
                legend(Theme.amber, "Delvis")
                legend(Theme.alert, "Tabt")
                legend(Theme.panelHigh, "Fri")
            }
        }
        .card()
    }

    private func legend(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2).fill(c).frame(width: 9, height: 9)
            Text(t).font(.tac(10, .medium)).foregroundStyle(Theme.textSoft)
        }
    }

    private func buildCells() -> [Color] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // Mandag i ugen for 4 uger siden.
        let wd = (cal.component(.weekday, from: today) + 5) % 7
        guard let start = cal.date(byAdding: .day, value: -(wd + 28), to: today) else { return [] }
        let logs = store.allLogs()
        var out: [Color] = []
        for i in 0..<35 {
            guard let d = cal.date(byAdding: .day, value: i, to: start) else { continue }
            if d > today { out.append(Color.clear); continue }
            let key = DayKey.key(for: d)
            let list = store.scheduled(on: d)
            let total = list.reduce(0) { $0 + $1.timesPerDay }
            if total == 0 || store.service.excusedDays.contains(key) { out.append(Theme.panelHigh); continue }
            let c = logs[key] ?? [:]
            let done = list.reduce(0) { $0 + min(c[$1.id] ?? 0, $1.timesPerDay) }
            let ratio = Double(done) / Double(total)
            if ratio >= 1 { out.append(Theme.ready) }
            else if ratio >= Tuning.Penalty.lostDayBelowRatio { out.append(Theme.amber) }
            else if d == today { out.append(Theme.line) }
            else { out.append(Theme.alert.opacity(0.8)) }
        }
        return out
    }
}

struct JournalView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 8) {
                    if store.service.log.isEmpty {
                        Text("Journalen er tom. Hændelser som forfremmelser, straf og meritter lander her.")
                            .font(.tac(14, .medium)).foregroundStyle(Theme.textSoft).card()
                    }
                    ForEach(store.service.log.reversed()) { e in EventRow(event: e) }
                }
                .padding(16)
            }
            .background(Theme.night.ignoresSafeArea())
            .navigationTitle("Tjenestejournal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Luk") { dismiss() } } }
        }
    }
}

/// Regler og straffetabel – vises i appen, så intet kommer bag på brugeren.
struct RulesView: View {
    @Environment(\.dismiss) private var dismiss
    typealias P = Tuning.Penalty

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    group("Belønning", rows: [
                        ("Løst opgave", "+\(Int(Tuning.readinessPerCompletion)) readiness · +\(Tuning.creditsPerCompletion) cr · +\(Tuning.xpPerCompletion) xp"),
                        ("Mission complete", "+\(Int(Tuning.readinessAllDoneBonus)) readiness · +\(Tuning.creditsAllDoneBonus) cr · +\(Tuning.xpAllDoneBonus) xp"),
                        ("Dagsrapport / backup", "+\(Tuning.creditsCheckIn) cr / +\(Tuning.creditsBackup) cr"),
                    ])
                    group("Tabt dag (under \(Int(P.lostDayBelowRatio * 100)) % løst)", rows: [
                        ("Readiness", "−\(Int(P.readinessMissedDay)) (loft −\(Int(P.readinessMaxDailyDrop)) pr. dag)"),
                        ("Bøde", "\(Int(P.fineRatio * 100)) % af credits, max \(P.fineMax), aldrig under 0"),
                        ("Slid", "−\(Int(P.wearPerLostDay)) % stand på påtaget udstyr (min. \(Int(P.minCondition)) %)"),
                    ])
                    group("Delvis dag (\(Int(P.lostDayBelowRatio * 100))–99 %)", rows: [
                        ("Readiness", "op til −\(Int(P.readinessPartialDayMax))"),
                        ("Streak", "Mission-streak nulstilles"),
                    ])
                    group("Disciplinærsag", rows: [
                        ("\(P.warningAfterLostDays) tabte dage i træk", "Advarsel"),
                        ("\(P.demoteAfterLostDays) tabte dage i træk", "Nedrykning ét trin – igen hver \(P.demoteEvery). dag"),
                        ("\(Tuning.leaveAfterMissedDays) dage uden indsats", "Orlov (ingen straf, retur efter \(Tuning.leaveReturnStreak) dage)"),
                        ("Readiness 0 i \(Tuning.suspendedAfterDaysAtZero) dage", "Suspenderet"),
                    ])
                    group("Beskyttelse", rows: [
                        ("Orlovskort", "\(P.leaveCardsPerWeek) pr. uge (auto eller manuelt)"),
                        ("Nådeperiode", "\(P.graceDaysAfterNewRank) dage efter forfremmelse: ingen bøde/nedrykning"),
                        ("Bund", "Aldrig under Rekrut · ejet udstyr fjernes aldrig"),
                        ("Fridage og orlov", "Ingen straf"),
                    ])
                    group("Comeback", rows: [
                        ("\(P.comebackDays) missioner i træk", "Mistet rank gives tilbage"),
                    ])
                }
                .padding(16)
            }
            .background(Theme.night.ignoresSafeArea())
            .navigationTitle("Regler & straf")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Luk") { dismiss() } } }
        }
    }

    private func group(_ title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: title)
            ForEach(rows.indices, id: \.self) { i in
                VStack(alignment: .leading, spacing: 2) {
                    Text(rows[i].0).font(.tac(14, .bold)).foregroundStyle(Theme.text)
                    Text(rows[i].1).font(.tac(13, .medium)).foregroundStyle(Theme.textSoft)
                }
                if i < rows.count - 1 { Divider().overlay(Theme.line) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}
