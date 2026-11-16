# Tactical Tracker 🎖️

Vane-tracker med en taktisk operatør i stedet for et kæledyr. Dine vaner bliver til **daglige missioner**:
løs dem, og operatøren stiger i readiness, credits og rank. Spring dem over, og der er konsekvenser
(bøde, slid, advarsel, nedrykning). Alt ligger lokalt på telefonen – ingen konto, ingen server, ingen iCloud.

Søster-app til [Sælliv](https://github.com/thyxo/seal-life): samme arkitektur og byggeopsætning, nyt tema.

## Hent appen

Hver gang der pushes til `main`, bygger GitHub Actions en usigneret `.ipa` og lægger den i releasen **latest**:

**https://github.com/thyxo/Tactical-Tracker/releases/tag/latest** → `TacticalTracker.ipa`

### Som source i SideStore / AltStore (anbefalet)

1. SideStore → **Sources** → **+**
2. Indsæt: `https://github.com/thyxo/Tactical-Tracker/releases/download/latest/source.json`
3. Åbn sourcen **Tactical Tracker** → **Get**. Nye builds kommer under **Updates**.

Manuelt: hent `TacticalTracker.ipa` i Safari på iPhonen → SideStore → **My Apps** → **+**.
Gratis Apple ID = appen udløber efter 7 dage. Tag backup: **⚙️ (Mission) → Eksportér backup**.

## Sådan virker det

| Sælliv | Tactical Tracker |
|---|---|
| Sæl | Operatør (SWAT-figur, uniform + hudfarve) |
| Humør 0–100 | Readiness 0–100: Klar 80+, Stabil 50–79, Træt 25–49, Udmattet 1–24, Suspenderet (2 dage på 0) |
| Ferie | Orlov: 7 planlagte dage uden indsats → orlov; 3 dage med indsats → tilbage (min. 55) |
| Fisk | Credits (3 pr. opgave, +5 mission complete, +1 dagsrapport, +2 backup) |
| Butik | Depot (udstyr, våben-skins, baser) + Våbenskab (galleri) |
| Eventyr | Dagens operation (kodenavne fra København) med briefing og debrief |
| – | Rank (Rekrut → Kaptajn), meritter, loadout-score, straf og comeback |

Alle regler og tal: [`Shared/Tuning.swift`](Shared/Tuning.swift). Fuld designbeskrivelse inkl. straffetabel: [`Docs/DESIGN.md`](Docs/DESIGN.md).
Reglerne kan også ses i appen: **Rank → Regler & straf**.

## Udvikling

- Swift + SwiftUI + SwiftData, iOS 17+, ingen tredjepartsbiblioteker.
- Xcode-projektet genereres med XcodeGen ud fra `project.yml` (`xcodegen generate`).
- `App/` – hovedappen · `Widget/` – widget + Live Activity · `Shared/` – kode der deles.
- Regelmotoren (`Shared/Discipline.swift`) er ren Swift og testes uden Xcode: `./Tests/run.sh`.
- App Group-ID'et læses ved runtime (AltStore/SideStore omskriver det).
- Billeder: se [`ASSETS.md`](ASSETS.md). Uden billeder tegnes alt i kode.
- CI bygger også `claude/**`-grene, men laver kun release fra `main`.
