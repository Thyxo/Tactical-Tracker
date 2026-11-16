import Foundation

// Regelmotoren for readiness, credits, rank, straf, orlov og meritter.
// Ren Swift (ingen SwiftUI/SwiftData), så den kan testes alene – se Tests/.
// Alle tal kommer fra Tuning.swift.

// MARK: - Tilstand

/// Alt der ændrer sig over tid for operatøren. Gemmes som JSON i profilen og i backup.
struct ServiceState: Codable, Equatable {
    var readiness: Double = Tuning.startReadiness
    var credits: Int = Tuning.startCredits
    var xp: Int = 0
    var rank: Int = 0
    /// Højeste rank nogensinde (til meritter).
    var maxRank: Int = 0
    var daysAtZero: Int = 0

    /// Planlagte dage i træk helt uden afkrydsning (→ orlov).
    var missedStreak: Int = 0
    /// Tabte dage i træk (→ advarsel og nedrykning).
    var lostStreak: Int = 0
    var warningActive: Bool = false

    var onLeave: Bool = false
    var leaveReturnStreak: Int = 0

    /// Sat når operatøren er rykket ned: den rank der kan vindes tilbage.
    var demotedFrom: Int? = nil
    var comebackStreak: Int = 0
    /// Dagen den nuværende rank blev opnået (nådeperiode).
    var rankSinceDayKey: String = ""

    /// Uge (DayKey.weekKey) hvor orlovskortet sidst blev brugt.
    var leaveCardWeekKey: String = ""
    var autoLeaveCard: Bool = true
    /// Dage der er fritaget manuelt med orlovskort.
    var excusedDays: [String] = []

    var missionStreak: Int = 0
    var bestMissionStreak: Int = 0
    var missionsCompleted: Int = 0
    var lifetimeCredits: Int = 0
    var checkIns: Int = 0
    var backups: Int = 0
    var comebacks: Int = 0
    var balanceDays: Int = 0

    /// Udstyr.
    var owned: [String] = []
    /// Påtaget udstyr i tegnerækkefølge (første tegnes nederst). Flere fra samme kategori er tilladt.
    var equipped: [String] = []
    var background: String = "hq"
    /// Stand pr. ting i procent (mangler = 100).
    var condition: [String: Double] = [:]

    /// Dag-flag.
    var bonusDayKey: String = ""
    var debriefSeenDayKey: String = ""
    var briefingSeenDayKey: String = ""
    var checkInDayKey: String = ""

    /// Merit-id → dag-nøgle hvor den blev opnået.
    var merits: [String: String] = [:]

    /// Tjenestejournal (nyeste sidst, max `ServiceLog.maxEntries`).
    var log: [ServiceEvent] = []
    /// Antal journal-linjer brugeren har set i en debrief.
    var seenLogCount: Int = 0

    var rankValue: Rank { Rank(rawValue: rank) ?? .recruit }

    func conditionOf(_ id: String) -> Double { condition[id] ?? 100 }
}

// MARK: - Journal

enum ServiceEventKind: String, Codable {
    case lostDay, partialDay, fine, wear, warning, demotion, demotionBlocked, grace
    case promotion, comebackProgress, comeback, leaveStart, leaveEnd, cardUsed
    case suspended, merit, repair, mission
}

struct ServiceEvent: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var dayKey: String
    var kind: ServiceEventKind
    var title: String
    var detail: String
    var readinessDelta: Double = 0
    var creditsDelta: Int = 0

    var isPenalty: Bool {
        switch kind {
        case .lostDay, .partialDay, .fine, .wear, .warning, .demotion, .suspended, .leaveStart: return true
        default: return false
        }
    }
}

enum ServiceLog {
    static let maxEntries = 250

    static func append(_ e: ServiceEvent, to s: inout ServiceState) {
        s.log.append(e)
        if s.log.count > maxEntries {
            let cut = s.log.count - maxEntries
            s.log.removeFirst(cut)
            s.seenLogCount = max(0, s.seenLogCount - cut)
        }
    }

    static func unseen(_ s: ServiceState) -> [ServiceEvent] {
        guard s.seenLogCount < s.log.count else { return [] }
        return Array(s.log[s.seenLogCount...])
    }
}

// MARK: - Input for én afsluttet dag

struct DayInput {
    var dayKey: String
    var weekKey: String
    /// Antal planlagte afkrydsninger og hvor mange der blev lavet.
    var total: Int
    var done: Int
    var anyDone: Bool
    /// Navn på ugedag til tekster ("tirsdag").
    var dayName: String = ""
}

// MARK: - Motoren

enum Discipline {
    typealias P = Tuning.Penalty

    // MARK: Løbende belønning

    /// +1 / −1 afkrydsning.
    static func reward(_ s: inout ServiceState, delta: Int) {
        let d = Double(delta)
        s.readiness = clamp(s.readiness + d * Tuning.readinessPerCompletion)
        s.credits = max(0, s.credits + delta * Tuning.creditsPerCompletion)
        s.xp = max(0, s.xp + delta * Tuning.xpPerCompletion)
        if delta > 0 {
            s.lifetimeCredits += Tuning.creditsPerCompletion
            if s.readiness > 0 { s.daysAtZero = 0 }
        }
    }

    /// Mission complete-bonus (fortegn −1 når en afkrydsning fortrydes).
    static func allDoneBonus(_ s: inout ServiceState, sign: Int) {
        let d = Double(sign)
        s.readiness = clamp(s.readiness + d * Tuning.readinessAllDoneBonus)
        s.credits = max(0, s.credits + sign * Tuning.creditsAllDoneBonus)
        s.xp = max(0, s.xp + sign * Tuning.xpAllDoneBonus)
        if sign > 0 { s.lifetimeCredits += Tuning.creditsAllDoneBonus }
    }

    static func earn(_ s: inout ServiceState, credits: Int) {
        s.credits += credits
        if credits > 0 { s.lifetimeCredits += credits }
    }

    /// Forfremmelse efter point. Blokeret mens en nedrykning kan vindes tilbage (comeback).
    @discardableResult
    static func checkPromotion(_ s: inout ServiceState, dayKey: String) -> ServiceEvent? {
        guard s.demotedFrom == nil else { return nil }
        let target = Rank.forXP(s.xp).rawValue
        guard target > s.rank else { return nil }
        s.rank = target
        s.maxRank = max(s.maxRank, target)
        s.rankSinceDayKey = dayKey
        let name = s.rankValue.displayName
        let e = ServiceEvent(dayKey: dayKey, kind: .promotion, title: "Forfremmet til \(name)",
                             detail: "\(s.xp) tjenestepoint. \(P.graceDaysAfterNewRank) dages nådeperiode mod nedrykning.")
        ServiceLog.append(e, to: &s)
        return e
    }

    static func inGrace(_ s: ServiceState, dayKey: String) -> Bool {
        guard !s.rankSinceDayKey.isEmpty, let d = DayKey.days(from: s.rankSinceDayKey, to: dayKey) else { return false }
        return d >= 0 && d < P.graceDaysAfterNewRank
    }

    static func leaveCardAvailable(_ s: ServiceState, weekKey: String) -> Bool {
        P.leaveCardsPerWeek > 0 && s.leaveCardWeekKey != weekKey
    }

    /// Manuelt orlovskort for en dag (typisk i dag). Returnerer false hvis ugens kort er brugt.
    @discardableResult
    static func useLeaveCard(_ s: inout ServiceState, dayKey: String, weekKey: String) -> Bool {
        guard leaveCardAvailable(s, weekKey: weekKey), !s.excusedDays.contains(dayKey) else { return false }
        s.leaveCardWeekKey = weekKey
        s.excusedDays.append(dayKey)
        if s.excusedDays.count > 60 { s.excusedDays.removeFirst(s.excusedDays.count - 60) }
        ServiceLog.append(ServiceEvent(dayKey: dayKey, kind: .cardUsed, title: "Orlovskort brugt",
                                       detail: "Dagen tæller ikke. Ingen straf, ingen streak brudt."), to: &s)
        return true
    }

    // MARK: Dagsafslutning

    /// Behandler én afsluttet dag og returnerer de hændelser, der skete.
    @discardableResult
    static func processDay(_ s: inout ServiceState, _ day: DayInput) -> [ServiceEvent] {
        var events: [ServiceEvent] = []
        func log(_ e: ServiceEvent) {
            events.append(e)
            ServiceLog.append(e, to: &s)
        }
        let key = day.dayKey
        let when = day.dayName.isEmpty ? "" : " (\(day.dayName))"

        // Fridag: ingen planlagte opgaver → neutral.
        guard day.total > 0 else { return events }

        // Orlov: ingen straf. Tilbage efter X dage i træk med mindst én afkrydsning.
        if s.onLeave {
            s.leaveReturnStreak = day.anyDone ? s.leaveReturnStreak + 1 : 0
            if s.leaveReturnStreak >= Tuning.leaveReturnStreak {
                endLeave(&s)
                log(ServiceEvent(dayKey: key, kind: .leaveEnd, title: "Tilbage i tjeneste",
                                 detail: "\(Tuning.leaveReturnStreak) dage i træk med indsats. Readiness mindst \(Int(Tuning.readinessAfterLeave))."))
            }
            return events
        }

        // Manuelt fritaget dag.
        if s.excusedDays.contains(key) { return events }

        let ratio = Double(min(day.done, day.total)) / Double(day.total)

        // Mission complete.
        if day.done >= day.total {
            s.missionStreak += 1
            s.bestMissionStreak = max(s.bestMissionStreak, s.missionStreak)
            s.missionsCompleted += 1
            s.lostStreak = 0
            s.missedStreak = 0
            s.warningActive = false
            if let back = s.demotedFrom {
                s.comebackStreak += 1
                if s.comebackStreak >= P.comebackDays {
                    s.rank = back
                    s.demotedFrom = nil
                    s.comebackStreak = 0
                    s.comebacks += 1
                    s.rankSinceDayKey = key
                    log(ServiceEvent(dayKey: key, kind: .comeback, title: "Comeback! Rank genvundet",
                                     detail: "\(P.comebackDays) missioner i træk. Du er \(s.rankValue.displayName) igen."))
                    if let e = checkPromotion(&s, dayKey: key) { events.append(e) }
                } else {
                    let left = P.comebackDays - s.comebackStreak
                    log(ServiceEvent(dayKey: key, kind: .comebackProgress, title: "Comeback \(s.comebackStreak)/\(P.comebackDays)",
                                     detail: "\(left) mission\(left == 1 ? "" : "er") mere i træk giver din rank tilbage."))
                }
            }
            return events
        }

        // Ikke alt klaret: streak og comeback brydes.
        s.missionStreak = 0
        s.comebackStreak = 0
        let lost = ratio < P.lostDayBelowRatio

        if !lost {
            // Delvist løst dag (mindst halvdelen): lille fald, ingen straf ellers.
            s.lostStreak = 0
            s.missedStreak = 0
            let drop = min(P.readinessPartialDayMax * (1 - ratio), P.readinessMaxDailyDrop)
            applyDrop(&s, drop)
            if drop >= 0.5 {
                log(ServiceEvent(dayKey: key, kind: .partialDay, title: "Delvis mission\(when)",
                                 detail: "\(day.done) af \(day.total) opgaver løst. Readiness −\(fmt(drop)).",
                                 readinessDelta: -drop))
            }
            return suspensionCheck(&s, key: key, events: events)
        }

        // Tabt dag. Orlovskort beskytter automatisk, hvis ugens kort er ubrugt.
        if s.autoLeaveCard && leaveCardAvailable(s, weekKey: day.weekKey) {
            s.leaveCardWeekKey = day.weekKey
            log(ServiceEvent(dayKey: key, kind: .cardUsed, title: "Orlovskort brugt automatisk\(when)",
                             detail: "\(day.done) af \(day.total) opgaver løst, men ugens orlovskort dækkede dagen. Ingen straf."))
            return events
        }

        s.missedStreak = day.anyDone ? 0 : s.missedStreak + 1
        s.lostStreak += 1
        let grace = inGrace(s, dayKey: key)

        // 1) Readiness.
        let base: Double = day.anyDone ? max(P.readinessPartialDayMax, P.readinessMissedDay * (1 - ratio)) : P.readinessMissedDay
        let drop = min(base, P.readinessMaxDailyDrop)
        applyDrop(&s, drop)
        let why = day.anyDone ? "kun \(day.done) af \(day.total) opgaver blev løst" : "ingen af \(day.total) opgaver blev løst"
        log(ServiceEvent(dayKey: key, kind: .lostDay, title: "Tabt dag\(when)",
                         detail: "Du mistede \(fmt(drop)) readiness, fordi \(why).", readinessDelta: -drop))

        // 2) Bøde (ikke i nådeperiode).
        if !grace {
            let fine = min(P.fineMax, Int((Double(s.credits) * P.fineRatio).rounded()))
            if fine > 0 {
                s.credits = max(0, s.credits - fine)
                log(ServiceEvent(dayKey: key, kind: .fine, title: "Bøde: −\(fine) credits",
                                 detail: "\(Int(P.fineRatio * 100)) % af beholdningen (max \(P.fineMax)) for en tabt dag.",
                                 creditsDelta: -fine))
            }
        }

        // 3) Slid på påtaget udstyr (forsvinder aldrig).
        var worn = 0
        for id in s.equipped {
            let before = s.conditionOf(id)
            let after = max(P.minCondition, before - P.wearPerLostDay)
            if after < before {
                s.condition[id] = after
                worn += 1
            }
        }
        if worn > 0 {
            log(ServiceEvent(dayKey: key, kind: .wear, title: "Udstyr slidt",
                             detail: "\(worn) stk. udstyr tabte \(fmt(P.wearPerLostDay)) % stand. Reparér i Loadout."))
        }

        // 4) Disciplinærsag.
        if s.lostStreak == P.warningAfterLostDays {
            s.warningActive = true
            let left = P.demoteAfterLostDays - s.lostStreak
            log(ServiceEvent(dayKey: key, kind: .warning, title: "Disciplinærsag: advarsel",
                             detail: "\(s.lostStreak) tabte dage i træk. \(left) mere, og du rykkes ét trin ned."))
        }
        if s.lostStreak >= P.demoteAfterLostDays && (s.lostStreak - P.demoteAfterLostDays) % P.demoteEvery == 0 {
            if grace {
                log(ServiceEvent(dayKey: key, kind: .grace, title: "Nådeperiode",
                                 detail: "Ny rank for nylig – ingen nedrykning denne gang."))
            } else if s.rank > 0 {
                if s.demotedFrom == nil { s.demotedFrom = s.rank }
                s.rank -= 1
                s.comebackStreak = 0
                log(ServiceEvent(dayKey: key, kind: .demotion, title: "Rykket ned til \(s.rankValue.displayName)",
                                 detail: "\(s.lostStreak) tabte dage i træk. Klar \(P.comebackDays) missioner i træk for at få din rank tilbage."))
            } else {
                log(ServiceEvent(dayKey: key, kind: .demotionBlocked, title: "Nedrykningsbund",
                                 detail: "Du er Rekrut – lavere kan man ikke komme. Kom igen i morgen."))
            }
        }

        // 5) Orlov efter mange dage helt uden indsats.
        if s.missedStreak >= Tuning.leaveAfterMissedDays {
            s.onLeave = true
            s.leaveReturnStreak = 0
            log(ServiceEvent(dayKey: key, kind: .leaveStart, title: "Sendt på orlov",
                             detail: "\(s.missedStreak) planlagte dage uden indsats. Ingen straf under orlov – løs én opgave \(Tuning.leaveReturnStreak) dage i træk for at vende tilbage."))
        }

        return suspensionCheck(&s, key: key, events: events)
    }

    static func endLeave(_ s: inout ServiceState) {
        s.onLeave = false
        s.missedStreak = 0
        s.lostStreak = 0
        s.leaveReturnStreak = 0
        s.daysAtZero = 0
        s.warningActive = false
        s.readiness = max(s.readiness, Tuning.readinessAfterLeave)
    }

    // MARK: Reparation

    static func repairCost(price: Int, condition: Double) -> Int {
        let missing = max(0, 100 - condition) / 100
        guard missing > 0 else { return 0 }
        return max(1, Int((Double(max(price, 20)) * missing * P.repairFactor).rounded()))
    }

    // MARK: Hjælpere

    private static func suspensionCheck(_ s: inout ServiceState, key: String, events: [ServiceEvent]) -> [ServiceEvent] {
        var out = events
        if s.daysAtZero == Tuning.suspendedAfterDaysAtZero {
            let e = ServiceEvent(dayKey: key, kind: .suspended, title: "Suspenderet",
                                 detail: "Readiness har været 0 i \(s.daysAtZero) dage. Én løst opgave ophæver suspensionen.")
            ServiceLog.append(e, to: &s)
            out.append(e)
        }
        return out
    }

    private static func applyDrop(_ s: inout ServiceState, _ drop: Double) {
        s.readiness = clamp(s.readiness - drop)
        s.daysAtZero = s.readiness <= 0 ? s.daysAtZero + 1 : 0
    }

    static func clamp(_ v: Double) -> Double { min(Tuning.readinessMax, max(0, v)) }

    static func fmt(_ v: Double) -> String {
        v.rounded() == v ? String(Int(v)) : String(format: "%.1f", v)
    }
}

// MARK: - Meritter

struct Merit: Identifiable, Hashable {
    let id: String
    let name: String
    let detail: String
    let symbol: String
}

/// Det meritterne måles på (udregnes af appen).
struct MeritInput {
    var ownedCount: Int = 0
    var weaponCount: Int = 0
    var ownsLegendary: Bool = false
}

enum Merits {
    static let all: [Merit] = [
        Merit(id: "first_mission", name: "Første mission", detail: "Løs alle dagens opgaver for første gang.", symbol: "flag.fill"),
        Merit(id: "streak_7", name: "7 dage i træk", detail: "Mission complete 7 planlagte dage i træk.", symbol: "7.circle.fill"),
        Merit(id: "streak_30", name: "30 dage i træk", detail: "Mission complete 30 planlagte dage i træk.", symbol: "30.circle.fill"),
        Merit(id: "streak_100", name: "100 dage i træk", detail: "Mission complete 100 planlagte dage i træk.", symbol: "rosette"),
        Merit(id: "missions_50", name: "50 missioner", detail: "50 dage med mission complete i alt.", symbol: "star.circle.fill"),
        Merit(id: "missions_250", name: "250 missioner", detail: "250 dage med mission complete i alt.", symbol: "star.square.on.square.fill"),
        Merit(id: "rank_sergeant", name: "Underofficer", detail: "Nå Sergent.", symbol: "chevron.up.2"),
        Merit(id: "rank_captain", name: "Kaptajn", detail: "Nå Kaptajn.", symbol: "star.fill"),
        Merit(id: "comeback", name: "Comeback", detail: "Vind en mistet rank tilbage.", symbol: "arrow.uturn.up.circle.fill"),
        Merit(id: "balance", name: "All-round", detail: "Løs opgaver i alle fire kategorier samme dag.", symbol: "circle.grid.2x2.fill"),
        Merit(id: "checkin_30", name: "Rapport afgivet", detail: "30 dagsrapporter (check-ins).", symbol: "text.bubble.fill"),
        Merit(id: "backup", name: "Data sikret", detail: "Tag din første backup.", symbol: "externaldrive.fill.badge.checkmark"),
        Merit(id: "credits_1000", name: "Lønseddel", detail: "Tjen 1.000 credits i alt.", symbol: "creditcard.fill"),
        Merit(id: "collector_10", name: "Samler", detail: "Ej 10 stykker udstyr eller våben.", symbol: "shippingbox.fill"),
        Merit(id: "armory_5", name: "Våbenmester", detail: "Ej 5 våben-skins.", symbol: "lock.shield.fill"),
        Merit(id: "legendary", name: "Legendarisk", detail: "Ej en legendarisk ting.", symbol: "crown.fill"),
    ]

    static func merit(_ id: String) -> Merit? { all.first { $0.id == id } }

    private static func earned(_ id: String, _ s: ServiceState, _ i: MeritInput) -> Bool {
        switch id {
        case "first_mission": return s.missionsCompleted >= 1
        case "streak_7": return s.bestMissionStreak >= 7
        case "streak_30": return s.bestMissionStreak >= 30
        case "streak_100": return s.bestMissionStreak >= 100
        case "missions_50": return s.missionsCompleted >= 50
        case "missions_250": return s.missionsCompleted >= 250
        case "rank_sergeant": return s.maxRank >= Rank.sergeant.rawValue
        case "rank_captain": return s.maxRank >= Rank.captain.rawValue
        case "comeback": return s.comebacks >= 1
        case "balance": return s.balanceDays >= 1
        case "checkin_30": return s.checkIns >= 30
        case "backup": return s.backups >= 1
        case "credits_1000": return s.lifetimeCredits >= 1000
        case "collector_10": return i.ownedCount >= 10
        case "armory_5": return i.weaponCount >= 5
        case "legendary": return i.ownsLegendary
        default: return false
        }
    }

    /// Tildeler nye meritter og returnerer dem.
    @discardableResult
    static func award(_ s: inout ServiceState, input: MeritInput, dayKey: String) -> [Merit] {
        var new: [Merit] = []
        for m in all where s.merits[m.id] == nil && earned(m.id, s, input) {
            s.merits[m.id] = dayKey
            new.append(m)
            ServiceLog.append(ServiceEvent(dayKey: dayKey, kind: .merit, title: "Merit: \(m.name)", detail: m.detail), to: &s)
        }
        return new
    }
}

// MARK: - Loadout-score

enum LoadoutScore {
    /// Balance 0–1 ud fra løsningsgrad pr. kategori (kun kategorier med opgaver tæller).
    static func balance(rates: [Double]) -> Double {
        let r = rates.filter { $0 >= 0 }
        guard r.count >= 2 else { return r.isEmpty ? 0 : r[0] }
        let lo = r.min() ?? 0
        let hi = r.max() ?? 0
        guard hi > 0 else { return 0 }
        let mean = r.reduce(0, +) / Double(r.count)
        // Både jævnhed og niveau tæller.
        return (lo / hi) * 0.5 + mean * 0.5
    }

    /// Udstyrsdel: summen af rating × stand.
    static func gear(ratings: [(rating: Int, condition: Double)]) -> Double {
        ratings.reduce(0) { $0 + Double($1.rating) * ($1.condition / 100) }
    }

    static func total(gear: Double, balance: Double, readiness: Double) -> Int {
        let w = Tuning.Loadout.balanceWeight
        let factor = (1 - w) + w * balance
        let v = gear * factor * 2 + readiness * Tuning.Loadout.readinessFactor
        return Int(v.rounded())
    }
}
