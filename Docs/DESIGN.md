# Design: fra Sælliv til Tactical Tracker

## Trin 0 – Gennemgang af referencen (Sælliv)

**Modeller (SwiftData):** `Habit` (navn, ikon, ugedage, gange/dag, påmindelse), `HabitLog` (vane × dag × antal),
`MoodEntry` (dagligt humør-check-in), `SealProfile` (navn, farve, humør, fisk, ejet tøj, ferie, streaks, dag-flag).

**Store/services:** `GameStore` (@Observable) holder alt: afkrydsning, dagsbehandling (`processElapsedDays` kører
alle dage siden sidst), butik, backup og synk. `Services.swift`: `NotificationScheduler` (max 2/dag, 7 dage frem,
ugentlig backup-påmindelse), `LiveActivityManager`, `BackupManager` (JSON eksport/import) og `AutoBackup`
(stille kopi i 3 mapper, så data overlever en tom database).

**Sammenhæng:** afkrydsning → humør + fisk → `syncOutside()` skriver `snapshot.json` i App Group → widget og
Live Activity læser den. Widget/ø-knapper skriver i `pending.json`, som appen afvikler ved næste åbning.
Dagsbehandling: tom dag −9, delvis op til −4, 7 tomme dage → ferie, 3 dage med indsats → hjem (min. 55).

**Sæl-specifikt:** `SealFigure`, `HatDesigns`, `FaceNeckDesigns`, `Scenes`, `Adventures`, alle tekster, `MoodState`, farver.

**Genbrugt næsten uændret:** project.yml, CI-workflow, make_source.py, App Group-opslag ved runtime, DayKey,
FitStore/tilpas-editor, PendingQueue, notifikations-planlægning, backup/autobackup, BurstView m.m.

## Trin 1 – Mapning

| Sælliv | Tactical Tracker |
|---|---|
| Sæl (3 farver) | Operatør (5 uniformer × 4 hudfarver) |
| Humør → glad/tilfreds/sulten/trist/syg | Readiness → Klar 80+ / Stabil 50–79 / Træt 25–49 / Udmattet 1–24 / Suspenderet (2 dage på 0) |
| Ferie | Orlov (7 planlagte dage uden afkrydsning ind, 3 dage med afkrydsning ud, min. 55) |
| Fisk | Credits – samme indtjening (3 / +5 / +1 / +2) |
| Butik: hatte, briller, hals, steder | Depot: hjelme, briller, nattesyn, ansigt, veste, tasker, patches, pistoler, MP'er, rifler, baser |
| 1 ting pr. slot | **Ubegrænset stabling** – flere fra samme kategori, egen lagrækkefølge |
| Eventyr-sted | Dagens operation (Kastellet, Nordhavn, Refshaleøen …) |
| Historie ved alt klaret | Mission complete-skærm |

**Nye lag:** morgen-briefing (før 11), dagens mission, aftens-debrief (efter 19) · Rank: Rekrut 0 → Konstabel 300
→ Sergent 1.000 → Løjtnant 2.500 → Kaptajn 5.000 xp (10 xp pr. opgave, +15 mission complete) · 16 meritter ·
Loadout-score = udstyr (sjældenhed × stand) × balance (søvn/motion/læring/familie, 7 dage) + readiness/2 ·
Sjældenhed låses op med rank (sjælden: Konstabel, episk: Sergent, legendarisk: Løjtnant).

## Straf og nedrykning

| Hændelse | Konsekvens | Tuning-navn |
|---|---|---|
| Tabt dag (< 50 % løst) | Readiness −15 (loft −18/dag) | `Penalty.readinessMissedDay`, `readinessMaxDailyDrop` |
| | Bøde 10 % af credits, max 25, aldrig under 0 | `fineRatio`, `fineMax` |
| | Påtaget udstyr −8 % stand (min. 20 %, fjernes aldrig) | `wearPerLostDay`, `minCondition` |
| Delvis dag (50–99 %) | Readiness op til −6, streak nulstilles | `readinessPartialDayMax` |
| 3 tabte dage i træk | Disciplinærsag: advarsel | `warningAfterLostDays` |
| 5 tabte dage i træk (og hver 5. derefter) | Rykket ét trin ned | `demoteAfterLostDays`, `demoteEvery` |
| 7 dage helt uden indsats | Orlov – ingen straf mens den varer | `Tuning.leaveAfterMissedDays` |
| Readiness 0 i 2 dage | Suspenderet | `suspendedAfterDaysAtZero` |
| Slidt udstyr | Lavere score; reparation = pris × manglende stand × 0,3 | `repairFactor` |

**Beskyttelse:** 1 orlovskort pr. uge (automatisk på første tabte dag eller manuelt for i dag) · 3 dages nådeperiode
efter forfremmelse (ingen bøde/nedrykning) · bund ved Rekrut · fridage og orlov straffes aldrig · ejede ting fjernes aldrig.

**Comeback:** efter nedrykning blokeres forfremmelse; 3 dage i træk med mission complete giver den mistede rank tilbage
(+ merit "Comeback"). Alle straffe vises i debrief som "Du mistede X readiness, fordi Y".

Reglerne er testet i `Tests/main.swift` (kør `./Tests/run.sh`; kører også i CI).

## Valgfrit senere

- "Holdet": 4 profiler (familien) med fælles holdscore og fælles mission.
- Ugentlig "operation" med en større belønning.
- Egne billeder pr. uniform (`op_<camo>_<state>.png`).
