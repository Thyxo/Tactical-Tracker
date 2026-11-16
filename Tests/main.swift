// Kør: ./Tests/run.sh  (kræver kun Swift, ikke Xcode)
import Foundation

var failures = 0
func check(_ cond: Bool, _ msg: String, line: Int = #line) {
    if !cond { failures += 1; print("FEJL (linje \(line)): \(msg)") }
}

func day(_ i: Int, total: Int = 3, done: Int) -> DayInput {
    let base = DayKey.date(from: "2026-01-05")!   // mandag
    let d = Calendar.current.date(byAdding: .day, value: i, to: base)!
    return DayInput(dayKey: DayKey.key(for: d), weekKey: DayKey.weekKey(for: d), total: total, done: done, anyDone: done > 0)
}

// 1. Tabt dag: −15 readiness, 10 % bøde, slid.
do {
    var s = ServiceState()
    s.autoLeaveCard = false
    s.credits = 100
    s.equipped = ["vest_swat"]
    Discipline.processDay(&s, day(0, done: 0))
    check(s.readiness == 55, "readiness 70-15=55, fik \(s.readiness)")
    check(s.credits == 90, "bøde 10 → 90, fik \(s.credits)")
    check(s.conditionOf("vest_swat") == 92, "slid 8 %, fik \(s.conditionOf("vest_swat"))")
    check(s.lostStreak == 1 && s.missedStreak == 1, "streaks")
    // Bøde loft
    s.credits = 1000
    Discipline.processDay(&s, day(1, done: 0))
    check(s.credits == 975, "bøde-loft 25, fik \(s.credits)")
    // Aldrig under 0
    s.credits = 3
    Discipline.processDay(&s, day(2, done: 0))
    check(s.credits >= 0, "credits under 0")
}

// 2. Fridag og delvis dag.
do {
    var s = ServiceState()
    s.autoLeaveCard = false
    let ev = Discipline.processDay(&s, day(0, total: 0, done: 0))
    check(ev.isEmpty && s.readiness == 70, "fridag skal være neutral")
    Discipline.processDay(&s, day(1, total: 4, done: 2))   // 50 % = ikke tabt
    check(s.lostStreak == 0, "50 % er ikke en tabt dag")
    check(abs(s.readiness - 67) < 0.01, "delvis −3, fik \(s.readiness)")
    Discipline.processDay(&s, day(2, total: 4, done: 1))   // 25 % = tabt
    check(s.lostStreak == 1, "25 % er en tabt dag")
}

// 3. Advarsel efter 3, nedrykning efter 5, bund ved Rekrut.
do {
    var s = ServiceState()
    s.autoLeaveCard = false
    s.xp = 1200
    Discipline.checkPromotion(&s, dayKey: "2025-12-01")
    check(s.rank == Rank.sergeant.rawValue, "forfremmet til sergent")
    for i in 0..<3 { Discipline.processDay(&s, day(i, done: 1)) }
    check(s.warningActive, "advarsel efter 3")
    for i in 3..<5 { Discipline.processDay(&s, day(i, done: 1)) }
    check(s.rank == Rank.constable.rawValue, "nedrykket efter 5, rank \(s.rank)")
    check(s.demotedFrom == Rank.sergeant.rawValue, "kan vindes tilbage")
    // Ingen forfremmelse mens nedrykket
    s.xp = 9999
    check(Discipline.checkPromotion(&s, dayKey: "2026-01-11") == nil, "forfremmelse blokeret under nedrykning")
    s.xp = 1200
    // Comeback: 3 missioner i træk
    for i in 5..<7 { Discipline.processDay(&s, day(i, done: 3)) }
    check(s.rank == Rank.constable.rawValue, "endnu ikke tilbage")
    Discipline.processDay(&s, day(7, done: 3))
    check(s.rank == Rank.sergeant.rawValue && s.demotedFrom == nil, "comeback giver rank tilbage")
    check(s.comebacks == 1, "comeback talt")
}

// 4. Nedrykningsbund
do {
    var s = ServiceState()
    s.autoLeaveCard = false
    for i in 0..<5 { Discipline.processDay(&s, day(i, done: 1)) }
    check(s.rank == 0, "aldrig under Rekrut")
    check(s.log.contains { $0.kind == .demotionBlocked }, "bund-hændelse logget")
}

// 5. Nådeperiode: ingen bøde og ingen nedrykning lige efter ny rank.
do {
    var s = ServiceState()
    s.autoLeaveCard = false
    s.rank = 2; s.maxRank = 2
    s.lostStreak = 4
    s.credits = 100
    s.rankSinceDayKey = day(0, done: 0).dayKey
    Discipline.processDay(&s, day(1, done: 0))
    check(s.rank == 2, "nådeperiode beskytter mod nedrykning")
    check(s.credits == 100, "ingen bøde i nådeperiode")
}

// 6. Orlovskort: automatisk 1 pr. uge.
do {
    var s = ServiceState()
    Discipline.processDay(&s, day(0, done: 0))   // mandag – kort bruges
    check(s.readiness == 70 && s.lostStreak == 0, "orlovskort dækker første tabte dag")
    Discipline.processDay(&s, day(1, done: 0))   // tirsdag – straf
    check(s.readiness == 55, "kun ét kort pr. uge")
    Discipline.processDay(&s, day(7, done: 0))   // næste mandag – nyt kort
    check(s.readiness == 55, "nyt kort ny uge")
    // Manuelt kort
    var m = ServiceState()
    let d = day(2, done: 0)
    check(Discipline.useLeaveCard(&m, dayKey: d.dayKey, weekKey: d.weekKey), "manuelt kort")
    check(!Discipline.useLeaveCard(&m, dayKey: day(3, done: 0).dayKey, weekKey: d.weekKey), "kun ét manuelt kort pr. uge")
    Discipline.processDay(&m, d)
    check(m.readiness == 70, "fritaget dag er neutral")
}

// 7. Orlov efter 7 dage uden indsats, retur efter 3, ingen straf imens.
do {
    var s = ServiceState()
    s.autoLeaveCard = false
    s.credits = 500
    for i in 0..<7 { Discipline.processDay(&s, day(i, done: 0)) }
    check(s.onLeave, "orlov efter 7")
    let c = s.credits
    Discipline.processDay(&s, day(7, done: 0))
    check(s.credits == c, "ingen straf under orlov")
    for i in 8..<11 { Discipline.processDay(&s, day(i, done: 1)) }
    check(!s.onLeave, "retur efter 3")
    check(s.readiness >= 55, "readiness mindst 55 efter orlov")
}

// 8. Readiness-loft pr. dag, suspension og slid-bund.
do {
    var s = ServiceState()
    s.autoLeaveCard = false
    s.equipped = ["a"]
    for i in 0..<20 { Discipline.processDay(&s, day(i, done: 0)); if s.onLeave { break } }
    check(s.readiness == 0, "ned til 0")
    check(s.log.contains { $0.kind == .suspended }, "suspenderet efter 2 dage på 0")
    check(s.conditionOf("a") >= Tuning.Penalty.minCondition, "slid stopper ved bund")
}

// 9. Belønning, mission streak og meritter.
do {
    var s = ServiceState()
    for _ in 0..<3 { Discipline.reward(&s, delta: 1) }
    Discipline.allDoneBonus(&s, sign: 1)
    check(s.credits == 20 + 9 + 5, "credits som Sælliv, fik \(s.credits)")
    check(s.xp == 45, "xp, fik \(s.xp)")
    for i in 0..<7 { Discipline.processDay(&s, day(i, done: 3)) }
    check(s.bestMissionStreak == 7, "streak 7")
    let new = Merits.award(&s, input: MeritInput(), dayKey: "2026-01-12")
    check(new.contains { $0.id == "streak_7" } && new.contains { $0.id == "first_mission" }, "meritter tildelt")
    check(Merits.award(&s, input: MeritInput(), dayKey: "2026-01-13").isEmpty, "ingen dobbelt-merit")
}

// 10. Reparation og score.
do {
    check(Discipline.repairCost(price: 100, condition: 100) == 0, "intet at reparere")
    check(Discipline.repairCost(price: 100, condition: 60) == 12, "100 × 40 % × 0.3 = 12")
    check(LoadoutScore.balance(rates: [1, 1, 1, 1]) == 1, "perfekt balance")
    check(LoadoutScore.balance(rates: [1, 0]) < 0.6, "ubalance straffes")
    check(Rank.forXP(1000) == .sergeant, "rank-tærskel")
}

print(failures == 0 ? "ALLE TESTS OK" : "\(failures) FEJL")
exit(failures == 0 ? 0 : 1)
