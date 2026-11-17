import Foundation
import SwiftData
import SwiftUI
import WidgetKit

@Observable
final class GameStore {
    @ObservationIgnored private(set) var container: ModelContainer
    @ObservationIgnored private(set) var context: ModelContext
    /// true = databasen på disken kunne ikke åbnes, og vi kører midlertidigt i hukommelsen.
    @ObservationIgnored private(set) var isTemporary = false

    var profile: OperatorProfile
    /// Readiness, credits, rank, udstyr og journal. Skrives tilbage i profilen ved save().
    var service: ServiceState
    var habits: [Habit] = []
    var todayCounts: [UUID: Int] = [:]
    var todayKey: String = DayKey.key()
    var todayReport: MoodEntry?

    /// UI-signaler
    var showMissionComplete = false
    var showDebrief = false
    var showBackOnDuty = false
    var rewardPulse = 0
    var dataVersion = 0
    var toast: String?
    /// Valgt figur-model (gemmes i App Group, så widgetten følger med).
    var bodyModel: BodyModel = BodyModel.current {
        didSet {
            BodyModel.current = bodyModel
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    /// Mørkt (standard) eller lyst tema – gemmes i App Group, så widgetten følger med.
    var themeMode: ThemeMode = ThemeMode.stored {
        didSet {
            ThemeMode.stored = themeMode
            Theme.mode = themeMode
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    /// Udviklermenu: tving en bestemt tilstand i visningen (nil = normal).
    var debugStateOverride: ReadinessState?

    init() {
        let opened = GameStore.openContainer()
        let ctx = ModelContext(opened.container)
        container = opened.container
        context = ctx
        isTemporary = opened.temporary
        let p = GameStore.pickProfile(in: ctx) ?? OperatorProfile()
        if p.modelContext == nil { ctx.insert(p) }
        profile = p
        service = p.loadService()
        recoverIfNeeded()
        reloadHabits()
        refreshToday()
    }

    private static var storeURL: URL { AppGroup.containerURL.appendingPathComponent("TacticalTracker.store") }

    private static var schema: Schema { Schema([Habit.self, HabitLog.self, MoodEntry.self, OperatorProfile.self]) }

    private static func openContainer() -> (container: ModelContainer, temporary: Bool) {
        let config = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
        for _ in 0..<3 {
            if let c = try? ModelContainer(for: schema, configurations: [config]) { return (c, false) }
            Thread.sleep(forTimeInterval: 0.15)
        }
        let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return (try! ModelContainer(for: schema, configurations: [mem]), true)
    }

    private static func pickProfile(in ctx: ModelContext) -> OperatorProfile? {
        guard let all = try? ctx.fetch(FetchDescriptor<OperatorProfile>()), !all.isEmpty else { return nil }
        let onboarded = all.filter(\.onboarded)
        if !onboarded.isEmpty {
            return onboarded.max { ($0.lastBackup ?? $0.createdAt) < ($1.lastBackup ?? $1.createdAt) }
        }
        return all.min { $0.createdAt < $1.createdAt }
    }

    /// Sørger for, at operatøren ikke forsvinder (database i hukommelsen → prøv disken; tom profil → autobackup).
    @discardableResult
    func recoverIfNeeded() -> Bool {
        var changed = false
        if isTemporary {
            let opened = GameStore.openContainer()
            if !opened.temporary {
                let ctx = ModelContext(opened.container)
                container = opened.container
                context = ctx
                isTemporary = false
                let p = GameStore.pickProfile(in: ctx) ?? OperatorProfile()
                if p.modelContext == nil { ctx.insert(p) }
                profile = p
                service = p.loadService()
                changed = true
            }
        }
        if !isTemporary && !profile.onboarded {
            if let p = GameStore.pickProfile(in: context), p.onboarded {
                profile = p
                service = p.loadService()
                changed = true
            } else if let data = AutoBackup.latest() {
                if (try? BackupManager.restore(data: data, store: self, refresh: false)) != nil {
                    changed = true
                }
            }
        }
        if changed {
            try? context.save()
            reloadHabits()
            refreshToday()
            dataVersion += 1
        }
        return changed
    }

    // MARK: - Livscyklus

    func onForeground() {
        recoverIfNeeded()
        todayKey = DayKey.key()
        guard profile.onboarded else { return }
        writeAutoBackup()
        applyPendingToggles()
        processElapsedDays()
        refreshToday()
        awardMerits()
        if !ServiceLog.unseen(service).isEmpty {
            showDebrief = true
        } else if allDoneToday && service.debriefSeenDayKey != todayKey && !service.onLeave {
            showMissionComplete = true
        }
        syncOutside()
    }

    func save() {
        profile.storeService(service)
        try? context.save()
        dataVersion += 1
        writeAutoBackup()
    }

    func writeAutoBackup() {
        guard profile.onboarded, !isTemporary else { return }
        if let data = try? BackupManager.encode(store: self) { AutoBackup.write(data) }
    }

    func reloadHabits() {
        let all = (try? context.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? []
        habits = all.filter { !$0.archived }
    }

    func refreshToday() {
        todayCounts = counts(for: todayKey)
        let k = todayKey
        todayReport = try? context.fetch(FetchDescriptor<MoodEntry>(predicate: #Predicate { $0.dayKey == k })).first
    }

    // MARK: - Opslag

    func counts(for key: String) -> [UUID: Int] {
        let k = key
        let logs = (try? context.fetch(FetchDescriptor<HabitLog>(predicate: #Predicate { $0.dayKey == k }))) ?? []
        var dict: [UUID: Int] = [:]
        for l in logs { dict[l.habitID, default: 0] += l.count }
        return dict
    }

    func allLogs() -> [String: [UUID: Int]] {
        let logs = (try? context.fetch(FetchDescriptor<HabitLog>())) ?? []
        var dict: [String: [UUID: Int]] = [:]
        for l in logs { dict[l.dayKey, default: [:]][l.habitID, default: 0] += l.count }
        return dict
    }

    func allReports() -> [MoodEntry] {
        (try? context.fetch(FetchDescriptor<MoodEntry>(sortBy: [SortDescriptor(\.dayKey)]))) ?? []
    }

    func scheduled(on date: Date) -> [Habit] {
        let wd = DayKey.weekday(date)
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        return habits.filter { $0.weekdays.contains(wd) && cal.startOfDay(for: $0.createdAt) <= start }
    }

    var todayHabits: [Habit] { scheduled(on: Date()) }
    var otherHabits: [Habit] {
        let ids = Set(todayHabits.map(\.id))
        return habits.filter { !ids.contains($0.id) }
    }
    var todayTotal: Int { todayHabits.reduce(0) { $0 + $1.timesPerDay } }
    var todayDone: Int { todayHabits.reduce(0) { $0 + min(todayCounts[$1.id] ?? 0, $1.timesPerDay) } }
    var allDoneToday: Bool { todayTotal > 0 && todayDone >= todayTotal }
    var remainingToday: Int { max(0, todayTotal - todayDone) }
    var isTodayExcused: Bool { service.excusedDays.contains(todayKey) }

    func count(_ h: Habit) -> Int { todayCounts[h.id] ?? 0 }

    var rank: Rank { service.rankValue }

    var readinessState: ReadinessState {
        ReadinessState.from(readiness: service.readiness, daysAtZero: service.daysAtZero, onLeave: service.onLeave)
    }

    var isNight: Bool {
        let h = Calendar.current.component(.hour, from: Date())
        return h >= Tuning.sleepHour || h < Tuning.wakeHour
    }

    /// Det figuren viser lige nu (hviler om natten).
    var displayState: ReadinessState {
        if let o = debugStateOverride { return o }
        if service.onLeave { return .leave }
        if isNight && (allDoneToday || todayTotal == 0) { return .resting }
        return readinessState
    }

    var operation: String { Operations.name(for: todayKey) }

    enum Phase { case briefing, mission, debrief, night }

    var phase: Phase {
        let h = Calendar.current.component(.hour, from: Date())
        if isNight { return .night }
        if h < Tuning.briefingUntilHour && todayDone == 0 { return .briefing }
        if h >= Tuning.debriefFromHour || allDoneToday { return .debrief }
        return .mission
    }

    var leaveCardAvailable: Bool { Discipline.leaveCardAvailable(service, weekKey: DayKey.weekKey()) }

    /// Radiobesked fra operatøren.
    var radioLine: String {
        let name = profile.callsign
        if service.onLeave {
            return "\(name) på orlov. Løs én opgave \(Tuning.leaveReturnStreak) dage i træk, så melder jeg mig tilbage."
        }
        if displayState == .resting { return "Vagten er slut. \(name) hviler. Ny briefing i morgen." }
        if todayTotal == 0 { return "Fridag. Ingen opgaver – genopfyld depoterne." }
        if isTodayExcused { return "Orlovskort aktivt i dag. Dagen tæller ikke." }
        if allDoneToday { return "Mission complete. Godt arbejde, \(name)." }
        if service.warningActive { return "Disciplinærsag åben. Løs dagens opgaver for at lukke den." }
        if let d = service.demotedFrom, let r = Rank(rawValue: d) {
            return "Comeback \(service.comebackStreak)/\(Tuning.Penalty.comebackDays) – vind \(r.displayName) tilbage."
        }
        switch readinessState {
        case .suspended: return "Suspenderet. Én løst opgave, og jeg er tilbage i felten."
        case .exhausted: return "Udmattet. Tag den mindste opgave først."
        case .tired: return "Lidt træt. To opgaver mere, og vi er på sporet."
        default:
            if todayDone == 0 { return "\(operation) begynder. \(todayTotal) opgaver på listen." }
            return "\(remainingToday) opgave\(remainingToday == 1 ? "" : "r") tilbage i \(operation)."
        }
    }

    // MARK: - Onboarding

    func finishOnboarding(callsign: String, camo: Camo, skin: SkinTone) {
        let trimmed = callsign.trimmingCharacters(in: .whitespaces)
        profile.callsign = trimmed.isEmpty ? "Ulv" : trimmed
        profile.camo = camo
        profile.skin = skin
        profile.onboarded = true
        profile.createdAt = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        profile.lastProcessedDayKey = DayKey.key(for: yesterday)
        if !service.owned.contains(GearCatalog.defaultBackground) { service.owned.append(GearCatalog.defaultBackground) }
        // Startudstyr: kasket og POLITI-vest er gratis til en ny rekrut.
        for id in ["cap_swat", "vest_police"] where !service.owned.contains(id) {
            service.owned.append(id)
            service.equipped.append(id)
        }
        service.equipped = sortedByLayer(service.equipped)
        service.rankSinceDayKey = todayKey
        if habits.isEmpty {
            addHabit(name: "8 timers søvn", icon: "🛏️", category: .sleep, weekdays: Array(1...7), times: 1, reminder: false, minutes: 1350)
            addHabit(name: "20 min. træning", icon: "🏃", category: .exercise, weekdays: [2, 3, 4, 5, 6], times: 1, reminder: true, minutes: 1020)
            addHabit(name: "Læs 15 min.", icon: "📚", category: .learning, weekdays: Array(1...7), times: 1, reminder: false, minutes: 1200)
            addHabit(name: "Aftensmad sammen", icon: "🍽️", category: .family, weekdays: Array(1...7), times: 1, reminder: false, minutes: 1080)
        }
        save()
        refreshToday()
        syncOutside()
    }

    // MARK: - Vaner

    func addHabit(name: String, icon: String, category: HabitCategory, weekdays: [Int], times: Int, reminder: Bool, minutes: Int) {
        let order = (habits.map(\.sortOrder).max() ?? 0) + 1
        let h = Habit(name: name, icon: icon, category: category, weekdays: weekdays, timesPerDay: max(1, times),
                      reminderEnabled: reminder, reminderMinutes: minutes, sortOrder: order)
        context.insert(h)
        save()
        reloadHabits()
        syncOutside()
    }

    func updated(_ h: Habit) {
        save()
        reloadHabits()
        syncOutside()
    }

    func archive(_ h: Habit) {
        h.archived = true
        save()
        reloadHabits()
        syncOutside()
    }

    private func log(for id: UUID, dayKey: String) -> HabitLog {
        let k = dayKey
        let hid = id
        if let l = try? context.fetch(FetchDescriptor<HabitLog>(predicate: #Predicate { $0.dayKey == k && $0.habitID == hid })).first {
            return l
        }
        let l = HabitLog(habitID: id, dayKey: dayKey, count: 0)
        context.insert(l)
        return l
    }

    /// Tryk på afkrydsning: +1, eller fortryd én hvis opgaven allerede er fuld.
    @discardableResult
    func tap(_ h: Habit) -> Bool {
        if count(h) >= h.timesPerDay {
            undo(h)
            return false
        }
        complete(h)
        return true
    }

    func complete(_ h: Habit, dayKey: String? = nil, sync: Bool = true) {
        let key = dayKey ?? todayKey
        let l = log(for: h.id, dayKey: key)
        guard l.count < h.timesPerDay else { return }
        let wasAllDone = allDoneToday
        l.count += 1
        if key == todayKey { todayCounts[h.id] = l.count }

        Discipline.reward(&service, delta: 1)
        rewardPulse += 1

        if service.onLeave, key == todayKey, service.leaveReturnStreak + 1 >= Tuning.leaveReturnStreak {
            Discipline.endLeave(&service)
            ServiceLog.append(ServiceEvent(dayKey: key, kind: .leaveEnd, title: "Tilbage i tjeneste",
                                           detail: "Orloven er slut. Velkommen tilbage."), to: &service)
            service.seenLogCount = service.log.count
            showBackOnDuty = true
        }

        if key == todayKey, !wasAllDone, allDoneToday, service.bonusDayKey != todayKey {
            service.bonusDayKey = todayKey
            Discipline.allDoneBonus(&service, sign: 1)
            if service.debriefSeenDayKey != todayKey && !service.onLeave {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { self.showMissionComplete = true }
            }
        }
        if let e = Discipline.checkPromotion(&service, dayKey: key) {
            flash("🎖️ \(e.title)!")
            service.seenLogCount = service.log.count
        }
        awardMerits()
        save()
        if sync { syncOutside() }
    }

    func undo(_ h: Habit, dayKey: String? = nil, sync: Bool = true) {
        let key = dayKey ?? todayKey
        let l = log(for: h.id, dayKey: key)
        guard l.count > 0 else { return }
        l.count -= 1
        if key == todayKey { todayCounts[h.id] = l.count }
        Discipline.reward(&service, delta: -1)
        if key == todayKey, service.bonusDayKey == todayKey, !allDoneToday {
            service.bonusDayKey = ""
            Discipline.allDoneBonus(&service, sign: -1)
        }
        save()
        if sync { syncOutside() }
    }

    private func applyPendingToggles() {
        let pending = PendingQueue.drain()
        guard !pending.isEmpty else { return }
        for p in pending {
            guard let h = habits.first(where: { $0.id.uuidString == p.habitID }) else { continue }
            if p.delta > 0 { complete(h, dayKey: p.dayKey, sync: false) } else { undo(h, dayKey: p.dayKey, sync: false) }
        }
    }

    // MARK: - Dagsbehandling (straf og belønning via Discipline)

    private static let dayNameFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "da_DK")
        f.dateFormat = "EEEE d/M"
        return f
    }()

    func processElapsedDays() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today) ?? today
        guard let last = DayKey.date(from: profile.lastProcessedDayKey) else {
            profile.lastProcessedDayKey = DayKey.key(for: yesterday)
            save()
            return
        }
        var day = cal.date(byAdding: .day, value: 1, to: last) ?? today
        var n = 0
        while day < today && n < 120 {
            processDay(day)
            day = cal.date(byAdding: .day, value: 1, to: day) ?? today
            n += 1
        }
        profile.lastProcessedDayKey = DayKey.key(for: yesterday)
        save()
    }

    func processDay(_ date: Date) {
        let list = scheduled(on: date)
        let key = DayKey.key(for: date)
        let c = counts(for: key)
        let total = list.reduce(0) { $0 + $1.timesPerDay }
        let done = list.reduce(0) { $0 + min(c[$1.id] ?? 0, $1.timesPerDay) }
        let anyDone = c.values.contains { $0 > 0 }

        // All-round: mindst én løst opgave i hver af de fire kategorier.
        let doneCats = Set(habits.filter { (c[$0.id] ?? 0) > 0 }.map(\.category))
        if HabitCategory.balanced.allSatisfy({ doneCats.contains($0) }) { service.balanceDays += 1 }

        let input = DayInput(dayKey: key, weekKey: DayKey.weekKey(for: date), total: total, done: done,
                             anyDone: anyDone, dayName: GameStore.dayNameFormatter.string(from: date))
        Discipline.processDay(&service, input)
    }

    // MARK: - Dagsrapport (check-in)

    func saveReport(_ choice: ReportChoice, note: String) {
        if let m = todayReport {
            m.mood = choice.rawValue
            m.note = note
        } else {
            let m = MoodEntry(dayKey: todayKey, mood: choice.rawValue, note: note)
            context.insert(m)
            todayReport = m
        }
        if service.checkInDayKey != todayKey {
            service.checkInDayKey = todayKey
            service.checkIns += 1
            Discipline.earn(&service, credits: Tuning.creditsCheckIn)
            rewardPulse += 1
        }
        awardMerits()
        save()
        syncOutside()
    }

    // MARK: - Orlovskort

    func useLeaveCardToday() -> Bool {
        let ok = Discipline.useLeaveCard(&service, dayKey: todayKey, weekKey: DayKey.weekKey())
        if ok {
            service.seenLogCount = service.log.count
            save()
            syncOutside()
        }
        return ok
    }

    // MARK: - Debrief / journal

    var unseenEvents: [ServiceEvent] { ServiceLog.unseen(service) }

    func markLogSeen() {
        service.seenLogCount = service.log.count
        save()
    }

    func markMissionCompleteSeen() {
        service.debriefSeenDayKey = todayKey
        save()
    }

    func flash(_ text: String) {
        toast = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            if self.toast == text { self.toast = nil }
        }
    }

    // MARK: - Meritter

    func awardMerits() {
        let ownedItems = service.owned.compactMap { GearCatalog.item($0) }.filter { $0.price > 0 }
        let input = MeritInput(ownedCount: ownedItems.count,
                               weaponCount: ownedItems.filter { $0.category.isWeapon }.count,
                               ownsLegendary: ownedItems.contains { $0.rarity == .legendary })
        let new = Merits.award(&service, input: input, dayKey: todayKey)
        if let m = new.last {
            service.seenLogCount = service.log.count
            flash("🏅 Merit: \(m.name)")
        }
    }

    // MARK: - Butik og udstyr

    func owns(_ item: GearItem) -> Bool { item.price == 0 || service.owned.contains(item.id) }

    func isEquipped(_ item: GearItem) -> Bool {
        item.category == .background ? service.background == item.id : service.equipped.contains(item.id)
    }

    func rankAllows(_ item: GearItem) -> Bool { service.rank >= item.rarity.minRank }

    enum BuyResult { case bought, notEnough(Int), rankLocked(Rank), outOfSeason, alreadyOwned }

    func buy(_ item: GearItem) -> BuyResult {
        if owns(item) { return .alreadyOwned }
        if !item.isInSeason { return .outOfSeason }
        if !rankAllows(item) { return .rankLocked(Rank(rawValue: item.rarity.minRank) ?? .recruit) }
        guard service.credits >= item.price else { return .notEnough(item.price - service.credits) }
        service.credits -= item.price
        service.owned.append(item.id)
        equip(item, force: true)
        awardMerits()
        save()
        return .bought
    }

    /// Tag på / af. Flere ting fra samme kategori kan bæres samtidig (stables).
    func equip(_ item: GearItem, force: Bool = false) {
        guard owns(item) else { return }
        if item.category == .background {
            service.background = (force || service.background != item.id) ? item.id : GearCatalog.defaultBackground
        } else if let i = service.equipped.firstIndex(of: item.id) {
            if !force { service.equipped.remove(at: i) }
        } else {
            service.equipped.append(item.id)
            service.equipped = sortedByLayer(service.equipped, newest: item.id)
        }
        save()
        syncOutside()
    }

    /// Sorterer efter kategoriens standardlag; inden for samme lag bevares brugerens rækkefølge.
    private func sortedByLayer(_ ids: [String], newest: String? = nil) -> [String] {
        guard let newest, let item = GearCatalog.item(newest) else {
            return ids.enumerated().sorted { a, b in
                let la = GearCatalog.item(a.element)?.category.baseLayer ?? 0
                let lb = GearCatalog.item(b.element)?.category.baseLayer ?? 0
                return la == lb ? a.offset < b.offset : la < lb
            }.map(\.element)
        }
        // Indsæt den nye ting øverst i sit lag uden at flytte på resten.
        var rest = ids.filter { $0 != newest }
        let layer = item.category.baseLayer
        let idx = rest.firstIndex { (GearCatalog.item($0)?.category.baseLayer ?? 0) > layer } ?? rest.count
        rest.insert(newest, at: idx)
        return rest
    }

    /// Flyt en påtaget ting et lag frem (+1) eller tilbage (−1).
    func moveLayer(_ id: String, by delta: Int) {
        guard let i = service.equipped.firstIndex(of: id) else { return }
        let j = i + delta
        guard j >= 0, j < service.equipped.count else { return }
        service.equipped.swapAt(i, j)
        save()
        syncOutside()
    }

    func unequipAll() {
        service.equipped = []
        save()
        syncOutside()
    }

    // MARK: - Slid og reparation

    func condition(_ id: String) -> Double { service.conditionOf(id) }

    func repairCost(_ id: String) -> Int {
        guard let item = GearCatalog.item(id) else { return 0 }
        return Discipline.repairCost(price: item.price, condition: condition(id))
    }

    var totalRepairCost: Int { service.equipped.reduce(0) { $0 + repairCost($1) } }

    @discardableResult
    func repair(_ id: String) -> Bool {
        let cost = repairCost(id)
        guard cost > 0, service.credits >= cost else { return false }
        service.credits -= cost
        service.condition[id] = nil
        ServiceLog.append(ServiceEvent(dayKey: todayKey, kind: .repair, title: "Repareret: \(GearCatalog.item(id)?.name ?? id)",
                                       detail: "Stand 100 %.", creditsDelta: -cost), to: &service)
        service.seenLogCount = service.log.count
        save()
        syncOutside()
        return true
    }

    // MARK: - Loadout-score

    /// Løsningsgrad pr. balance-kategori de sidste dage (−1 = ingen opgaver i kategorien).
    func categoryRates() -> [HabitCategory: Double] {
        let cal = Calendar.current
        let logs = allLogs()
        var planned: [HabitCategory: Int] = [:]
        var done: [HabitCategory: Int] = [:]
        for back in 0..<Tuning.Loadout.balanceDays {
            guard let date = cal.date(byAdding: .day, value: -back, to: Date()) else { continue }
            let c = logs[DayKey.key(for: date)] ?? [:]
            for h in scheduled(on: date) {
                planned[h.category, default: 0] += h.timesPerDay
                done[h.category, default: 0] += min(c[h.id] ?? 0, h.timesPerDay)
            }
        }
        var out: [HabitCategory: Double] = [:]
        for cat in HabitCategory.balanced {
            let p = planned[cat] ?? 0
            out[cat] = p > 0 ? Double(done[cat] ?? 0) / Double(p) : -1
        }
        return out
    }

    var balance: Double {
        let r = categoryRates()
        return LoadoutScore.balance(rates: HabitCategory.balanced.map { r[$0] ?? -1 })
    }

    var gearScore: Double {
        let list = service.equipped.compactMap { id -> (rating: Int, condition: Double)? in
            guard let item = GearCatalog.item(id) else { return nil }
            return (item.rarity.rating, condition(id))
        }
        return LoadoutScore.gear(ratings: list)
    }

    var loadoutScore: Int {
        LoadoutScore.total(gear: gearScore, balance: balance, readiness: service.readiness)
    }

    // MARK: - Synk til widget, notifikationer og Live Activity

    func syncOutside() {
        writeSnapshot()
        WidgetCenter.shared.reloadAllTimelines()
        NotificationScheduler.reschedule(store: self)
        LiveActivityManager.sync(store: self)
    }

    func writeSnapshot() {
        let wh = habits.map { h in
            WidgetHabit(id: h.id.uuidString, name: h.name, icon: h.icon, weekdays: h.weekdays,
                        target: h.timesPerDay, done: todayCounts[h.id] ?? 0)
        }
        let snap = OperatorSnapshot(callsign: profile.callsign, camoRaw: profile.camoRaw, skinRaw: profile.skinRaw,
                                    readiness: service.readiness, daysAtZero: service.daysAtZero,
                                    onLeave: service.onLeave, dayKey: todayKey, credits: service.credits,
                                    rank: service.rank, operation: operation, equipped: service.equipped,
                                    warning: service.warningActive, habits: wh)
        snap.save()
    }

    // MARK: - Backup

    var needsBackupNudge: Bool {
        guard profile.onboarded else { return false }
        let ref = profile.lastBackup ?? profile.createdAt
        let days = Calendar.current.dateComponents([.day], from: ref, to: Date()).day ?? 0
        return days >= Tuning.backupNudgeAfterDays
    }

    func didExportBackup() {
        let first = profile.lastBackup.map { !Calendar.current.isDateInToday($0) } ?? true
        profile.lastBackup = Date()
        if first {
            Discipline.earn(&service, credits: Tuning.creditsBackup)
            service.backups += 1
        }
        awardMerits()
        save()
    }

    // MARK: - Udviklermenu

    /// Behandler en kunstig dag i fremtiden med en given andel løst.
    func debugSimulateDay(ratio: Double) {
        let cal = Calendar.current
        let base = 400 + service.log.count % 300
        for k in base..<(base + 7) {
            guard let d = cal.date(byAdding: .day, value: k, to: Date()) else { continue }
            let list = scheduled(on: d)
            guard !list.isEmpty else { continue }
            let total = list.reduce(0) { $0 + $1.timesPerDay }
            let done = Int((Double(total) * ratio).rounded(.down))
            let input = DayInput(dayKey: DayKey.key(for: d), weekKey: DayKey.weekKey(for: d), total: total,
                                 done: done, anyDone: done > 0, dayName: "testdag")
            Discipline.processDay(&service, input)
            break
        }
        save()
        syncOutside()
        if !unseenEvents.isEmpty { showDebrief = true }
    }

    func debugStartLeave() {
        service.onLeave = true
        service.leaveReturnStreak = 0
        save()
        syncOutside()
    }

    func debugEndLeave() {
        Discipline.endLeave(&service)
        save()
        syncOutside()
    }

    func debugSetReadiness(_ v: Double) {
        service.readiness = Discipline.clamp(v)
        service.daysAtZero = 0
        save()
        syncOutside()
    }

    func debugSetDaysAtZero(_ n: Int) {
        service.daysAtZero = n
        if n > 0 { service.readiness = 0 }
        save()
        syncOutside()
    }

    func debugAddCredits(_ n: Int) {
        Discipline.earn(&service, credits: n)
        service.credits = max(0, service.credits)
        rewardPulse += 1
        save()
        syncOutside()
    }

    func debugAddXP(_ n: Int) {
        service.xp = max(0, service.xp + n)
        Discipline.checkPromotion(&service, dayKey: todayKey)
        service.seenLogCount = service.log.count
        awardMerits()
        save()
        syncOutside()
    }

    func debugResetLeaveCard() {
        service.leaveCardWeekKey = ""
        save()
    }

    func debugResetOnboarding() {
        AutoBackup.clear()
        profile.onboarded = false
        save()
    }
}

// MARK: - Dagens operation (kodenavn)

enum Operations {
    static let names: [String] = [
        "Operation Kastellet", "Operation Nordhavn", "Operation Søerne", "Operation Refshaleøen",
        "Operation Fælledparken", "Operation Valby Bakke", "Operation Islands Brygge", "Operation Christianshavn",
        "Operation Sydhavnen", "Operation Langelinie", "Operation Bispebjerg", "Operation Frederiksberg Have",
        "Operation Kalvebod", "Operation Amagerbro", "Operation Nørrebro", "Operation Holmen",
        "Operation Trekroner", "Operation Ørestad", "Operation Assistens", "Operation Dragør",
    ]

    static func name(for dayKey: String) -> String {
        names[DayKey.stableHash(dayKey) % names.count]
    }
}
