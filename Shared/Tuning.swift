import Foundation

/// Alle justerbare tal i appen samlet ét sted.
/// Ret frit – appen bruger kun disse værdier.
enum Tuning {

    // MARK: - Readiness (0–100)

    static let readinessMax: Double = 100
    /// Readiness ved start (ny operatør).
    static let startReadiness: Double = 70
    /// Stigning pr. udført afkrydsning.
    static let readinessPerCompletion: Double = 5
    /// Ekstra stigning når alle dagens opgaver er klaret ("mission complete").
    static let readinessAllDoneBonus: Double = 6

    // MARK: - Tilstande

    static let readyThreshold: Double = 80     // Klar: 80+
    static let steadyThreshold: Double = 50    // Stabil: 50–79
    static let tiredThreshold: Double = 25     // Træt: 25–49
    // Udmattet: 1–24
    /// Antal dage på 0, før operatøren bliver "Suspenderet".
    static let suspendedAfterDaysAtZero = 2

    // MARK: - Orlov (svarer til Sællivs ferie)

    /// Planlagte dage i træk helt uden afkrydsning, før operatøren sendes på orlov.
    static let leaveAfterMissedDays = 7
    /// Dage i træk med mindst én afkrydsning, før operatøren er tilbage i tjeneste.
    static let leaveReturnStreak = 3
    /// Readiness ved retur fra orlov (mindst).
    static let readinessAfterLeave: Double = 55

    // MARK: - Credits (valuta – samme indtjening som fisk i Sælliv)

    static let startCredits = 20
    static let creditsPerCompletion = 3
    static let creditsAllDoneBonus = 5
    static let creditsCheckIn = 1
    static let creditsBackup = 2

    // MARK: - Tjenestepoint (XP) og rank

    /// Point pr. afkrydsning og ekstra for mission complete.
    static let xpPerCompletion = 10
    static let xpAllDoneBonus = 15
    /// Point der skal til hver rank (samme rækkefølge som `Rank`).
    static let rankThresholds: [Int] = [0, 300, 1000, 2500, 5000]

    // MARK: - Straf og nedrykning

    enum Penalty {
        /// En "tabt dag" = planlagt dag, hvor under denne andel af opgaverne blev løst.
        static let lostDayBelowRatio: Double = 0.5
        /// Readiness-fald for en dag helt uden afkrydsning (Sælliv: -9).
        static let readinessMissedDay: Double = 15
        /// Maks. fald for en delvist løst dag (skaleres efter hvor meget der manglede).
        static let readinessPartialDayMax: Double = 6
        /// Loft: readiness falder aldrig mere end dette på én dag (inkl. alt).
        static let readinessMaxDailyDrop: Double = 18

        /// Bøde i credits ved tabt dag (andel af beholdningen) og loft. Aldrig under 0.
        static let fineRatio: Double = 0.10
        static let fineMax = 25

        /// Tabte dage i træk → advarsel (disciplinærsag).
        static let warningAfterLostDays = 3
        /// Tabte dage i træk → nedrykning ét trin. Derefter igen for hver yderligere `demoteEvery` dage.
        static let demoteAfterLostDays = 5
        static let demoteEvery = 5

        /// Slid: hvert påtaget stykke udstyr taber så mange procent stand pr. tabt dag.
        static let wearPerLostDay: Double = 8
        /// Stand går aldrig under dette (udstyret forsvinder aldrig).
        static let minCondition: Double = 20
        /// Reparation: pris = varens pris × manglende stand × denne faktor (mindst 1 credit).
        static let repairFactor: Double = 0.3

        /// Beskyttelse: orlovskort pr. uge, nådeperiode efter ny rank (dage).
        static let leaveCardsPerWeek = 1
        static let graceDaysAfterNewRank = 3

        /// Comeback: dage i træk med mission complete, der giver den mistede rank tilbage.
        static let comebackDays = 3
    }

    // MARK: - Loadout-score

    enum Loadout {
        /// Point pr. stykke påtaget udstyr efter sjældenhed.
        static let ratingCommon = 5
        static let ratingRare = 10
        static let ratingEpic = 18
        static let ratingLegendary = 30
        /// Antal dage tilbage, balancen mellem vane-kategorier måles over.
        static let balanceDays = 7
        /// Balancen vægter så meget af scoren (0–1). Resten er udstyr.
        static let balanceWeight: Double = 0.5
        /// Readiness lægges oven i scoren med denne faktor.
        static let readinessFactor: Double = 0.5
    }

    // MARK: - Notifikationer

    /// Standard: maks. samlede påmindelser pr. dag (kan ændres til 1 i appen).
    static let maxRemindersPerDay = 2
    /// Hvor mange dage frem påmindelser planlægges.
    static let reminderDaysAhead = 7
    /// Ugentlig backup-påmindelse (1 = søndag … 7 = lørdag).
    static let backupReminderWeekday = 1
    static let backupReminderHour = 11
    /// Vis backup-kort, når sidste backup er ældre end dette (dage).
    static let backupNudgeAfterDays = 6

    // MARK: - Dagsrytme

    /// Morgen-briefing vises indtil dette klokkeslæt; derefter "dagens mission".
    static let briefingUntilHour = 11
    /// Aftens-debrief fra dette klokkeslæt.
    static let debriefFromHour = 19
    /// Fra dette klokkeslæt hviler operatøren (visning).
    static let sleepHour = 22
    /// Til dette klokkeslæt hviler operatøren (visning).
    static let wakeHour = 6

    // MARK: - Bevægelse (figurens idle – lavere = roligere)

    enum Motion {
        static let breatheSpeed: Double = 1.1
        static let breatheSpeedSleeping: Double = 0.7
        static let breatheAmount: Double = 0.010
        /// Lille vippen på tæerne når operatøren er Klar.
        static let readyBounceHeight: Double = 0.010
        static let readyBounceSpeed: Double = 1.4
        static let swayDegrees: Double = 0.8
        static let swaySpeed: Double = 0.6
        static let blinkEvery: Double = 5.0
        static let ambientSpeed: Double = 0.55
    }

    // MARK: - Udstyr på figuren (ankerpunkter, andel af figurens størrelse)

    enum Anchor {
        static let helmet = (x: 0.50, y: 0.17)
        static let eyewear = (x: 0.50, y: 0.28)
        static let nvg = (x: 0.50, y: 0.15)
        static let face = (x: 0.50, y: 0.31)
        static let vest = (x: 0.50, y: 0.56)
        static let pouch = (x: 0.50, y: 0.64)
        static let patch = (x: 0.33, y: 0.49)
        static let holster = (x: 0.69, y: 0.73)
        static let longgun = (x: 0.50, y: 0.60)
        /// Grænser i tilpas-editoren.
        static let maxOffset: Double = 0.4
        static let minScale: Double = 0.3
        static let maxScale: Double = 2.2
    }

    // MARK: - Priser (credits) efter sjældenhed

    enum Price {
        static let common = 30
        static let rare = 70
        static let epic = 140
        static let legendary = 280
        /// Våben koster lidt mere end tøj.
        static let weaponFactor: Double = 1.25
        /// Baggrunde.
        static let background = 90
    }
}
