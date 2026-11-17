# Billeder til Tactical Tracker

Appen virker uden billeder: operatør, udstyr, våben og baser er tegnet i kode (se `Docs/DRAWING_CONTRACT.md`).
Læg PNG-filer i `Assets/Incoming/` med **præcis de filnavne, der står herunder**, så bruger appen dem automatisk.
Animationer (vejrtrækning, vippen, blink) laves stadig i kode ovenpå.

## Rækkefølge

1. **Master:** `op_steady.png` – operatøren forfra, neutral. Reference for alt andet.
2. De 6 andre tilstande.
3. Udstyr (hjelme først – de ses mest).
4. Våben-skins (galleri).
5. Baser.
6. App-ikon.

## Fælles stil

> Clean stylized 3D-toy / vector illustration, chibi proportions (big head), friendly and calm, muted tactical palette (black, olive, coyote, slate), soft studio lighting, no blood, no violence, no text, no watermark.

## 1. Operatøren – 1024 × 1024, gennemsigtig PNG

Figuren skal stå midt i billedet og følge koordinaterne i `Docs/DRAWING_CONTRACT.md` (hoved-top ca. 13 % fra toppen, øjne ca. 28 % nede, støvler ved ca. 95 %), så udstyret passer. **Intet udstyr på** (ingen hjelm/vest/våben) og ingen skygge – det lægges på i appen.
**Pr. figur-model:** Der er 4 modeller (`athletic`, `soft`, `icon`, `classic`). Billeder til en ny model hedder
`op_<model>_<tilstand>.png`, fx `op_soft_steady.png` – og valgfrit pr. uniform `op_<model>_<camo>_<tilstand>.png`.
Filnavnene i tabellen herunder (`op_<tilstand>.png`) gælder kun den klassiske model. Lav billeder til den model, du vælger i appen.

| Filnavn | Tilstand | Udtryk |
|---|---|---|
| `op_ready.png` | Klar (80+) | Selvsikker, lille smil, rank holdning |
| `op_steady.png` | Stabil (50–79) | **Master.** Neutral, rolig |
| `op_tired.png` | Træt (25–49) | Halvt lukkede øjne |
| `op_exhausted.png` | Udmattet (1–24) | Hængende skuldre, svedperle |
| `op_suspended.png` | Suspenderet | Ser ned, lidt grå/afmattet |
| `op_leave.png` | Orlov | Afslappet, lukkede glade øjne (kaffekop må gerne være med) |
| `op_resting.png` | Hviler (nat) | Øjne lukket, rolig |

**Prompt til master (`op_steady.png`):**
```
Front view full-body character sheet of ONE friendly chibi-proportioned tactical police operator (SWAT), standing straight, arms relaxed at the sides, neutral calm expression, short dark hair, black long-sleeve tactical shirt, black cargo pants, black gloves and boots, belt with buckle. No helmet, no vest, no weapons, no accessories. Clean stylized 3D-toy look, soft lighting, muted palette. Centered in 1024x1024: top of head about 13% from the top, eyes about 28% down, boots ending about 5% above the bottom. Transparent background, no shadow, no text.
```
Andre tilstande: *"Same character as the attached master image (identical proportions, colors and position). Expression: …"*

## 2. Udstyr – 512 × 512, gennemsigtig PNG

Kun selve tingen, set forfra, i den størrelse den ville have på master-figuren. Centrum af billedet = ankerpunktet (se kontrakten).
Finjustér bagefter i appen: **Loadout → Tilpas**.

| Filnavn | Ting | Model | Kategori | Sjældenhed |
|---|---|---|---|---|
| `gear_helmet_fast.png` | FAST-hjelm | Ops-Core FAST SF | Hjelm | Sjælden |
| `gear_helmet_ach.png` | ACH-hjelm | ACH / MICH 2000 | Hjelm | Almindelig |
| `gear_helmet_pasgt.png` | PASGT-hjelm | PASGT | Hjelm | Almindelig |
| `gear_cap_swat.png` | SWAT-kasket | Sort feltkasket | Hjelm | Almindelig |
| `gear_beanie_watch.png` | Strikhue | Watch cap | Hjelm | Almindelig |
| `gear_boonie.png` | Boonie-hat | Boonie hat, coyote | Hjelm | Almindelig |
| `gear_helmet_exfil.png` | EXFIL-hjelm | Team Wendy EXFIL LTP | Hjelm | Episk |
| `gear_helmet_gold.png` | Ceremonihjelm | Paradehjelm i guld | Hjelm | Legendarisk |
| `gear_helmet_nisse.png` | Nisse-overtræk | Julevagt-overtræk | Hjelm | Almindelig |
| `gear_glasses_mframe.png` | Skydebriller | Oakley SI M-Frame | Briller | Almindelig |
| `gear_glasses_crossbow.png` | Crossbow-briller | ESS Crossbow | Briller | Sjælden |
| `gear_goggles_locust.png` | Ørkenbriller | Revision Desert Locust | Briller | Sjælden |
| `gear_glasses_aviator.png` | Pilotbriller | Randolph Aviator | Briller | Episk |
| `gear_nvg_pvs14.png` | Monokular | AN/PVS-14 | Nattesyn | Sjælden |
| `gear_nvg_pvs31.png` | Binokular | AN/PVS-31A | Nattesyn | Episk |
| `gear_nvg_gpnvg.png` | Quad-nattesyn | L3Harris GPNVG-18 | Nattesyn | Legendarisk |
| `gear_face_balaclava.png` | Balaklava | Sort balaklava | Ansigt | Almindelig |
| `gear_face_shemagh.png` | Shemagh | Shemagh, oliven | Ansigt | Almindelig |
| `gear_face_headset.png` | Headset | Peltor ComTac VI | Ansigt | Sjælden |
| `gear_face_skull.png` | Kraniemaske | Halvmaske med kranie | Ansigt | Episk |
| `gear_vest_police.png` | POLITI-vest | Skjult beskyttelsesvest | Vest | Almindelig |
| `gear_vest_swat.png` | SWAT-vest | Plate carrier, sort | Vest | Almindelig |
| `gear_vest_chestrig.png` | Chest rig | Chest rig, oliven | Vest | Almindelig |
| `gear_vest_jpc.png` | JPC 2.0 | Crye Precision JPC 2.0 | Vest | Sjælden |
| `gear_vest_avs.png` | AVS | Crye Precision AVS | Vest | Episk |
| `gear_vest_gold.png` | Guldvest | Plate carrier, guldkant | Vest | Legendarisk |
| `gear_pouch_mags.png` | Magasintasker | 3× M4-magasintaske | Taske | Almindelig |
| `gear_pouch_ifak.png` | IFAK | Førstehjælpstaske | Taske | Almindelig |
| `gear_pouch_light.png` | Lygte | SureFire-lygte | Taske | Almindelig |
| `gear_pouch_admin.png` | Admin-panel | Admin pouch | Taske | Almindelig |
| `gear_pouch_radio.png` | Radio | L3Harris AN/PRC-152 | Taske | Sjælden |
| `gear_patch_dk.png` | Dannebrog | Flag-patch | Patch | Almindelig |
| `gear_patch_swat.png` | SWAT-patch | Tekst-patch | Patch | Almindelig |
| `gear_patch_blood.png` | Blodtype | O POS | Patch | Almindelig |
| `gear_patch_ir.png` | IR-flag | Infrarødt flag | Patch | Sjælden |
| `gear_patch_seal.png` | Sæl-patch | Moral-patch | Patch | Sjælden |
| `gear_patch_kbh.png` | København | Byvåben | Patch | Episk |
| `gear_patch_star.png` | Guldstjerne | Officersstjerne | Patch | Legendarisk |

Prompt (skift `[ITEM]` ud): `Using the attached operator master image only as a style and scale reference, draw ONLY a single [ITEM], front view, centered, no person. Clean stylized 3D-toy look, muted tactical colors. 512x512, transparent background, no shadow, no text.`

## 3. Våben-skins – 1024 × 512, gennemsigtig PNG

Set fra siden, **mundingen mod højre**, greb nedad, hele våbnet i billedet. Kun til galleriet – ingen mundingsflamme, ingen personer.

| Filnavn | Ting | Model | Kategori | Sjældenhed |
|---|---|---|---|---|
| `wpn_pistol_glock17.png` | Glock 17 | Glock 17 Gen5 | Pistol | Almindelig |
| `wpn_pistol_p226.png` | P226 | SIG Sauer P226 | Pistol | Sjælden |
| `wpn_pistol_usp.png` | USP | Heckler & Koch USP | Pistol | Sjælden |
| `wpn_pistol_1911.png` | M1911 | Colt M1911A1 | Pistol | Episk |
| `wpn_pistol_deagle.png` | Desert Eagle | Magnum Research Desert Eagle (guld) | Pistol | Legendarisk |
| `wpn_smg_mp5.png` | MP5 | Heckler & Koch MP5A3 | MP | Sjælden |
| `wpn_smg_ump.png` | UMP | Heckler & Koch UMP45 | MP | Sjælden |
| `wpn_smg_mp7.png` | MP7 | Heckler & Koch MP7A2 | MP | Episk |
| `wpn_smg_vector.png` | Vector | KRISS Vector | MP | Legendarisk |
| `wpn_rifle_m4.png` | M4A1 | Colt M4A1 | Riffel | Almindelig |
| `wpn_rifle_m10.png` | Gevær M/10 | Colt Canada C8 IUR | Riffel | Sjælden |
| `wpn_rifle_ak.png` | AK-74 | Kalashnikov AK-74 | Riffel | Sjælden |
| `wpn_rifle_hk416.png` | HK416 | Heckler & Koch HK416 | Riffel | Episk |
| `wpn_rifle_scar.png` | SCAR-H | FN SCAR-H | Riffel | Episk |
| `wpn_rifle_sr25.png` | SR-25 | Knight's Armament SR-25 | Riffel | Legendarisk |

Prompt: `Side view product illustration of a [MODEL], muzzle pointing right, clean stylized 3D-toy look, soft studio lighting, centered, 1024x512, transparent background, no hands, no muzzle flash, no text.`

## 4. Baser – 1170 × 1400, ikke gennemsigtig

Hold den nederste midterste tredjedel rolig (der står figuren) og toppen enkel.

| Filnavn | Sted |
|---|---|
| `bg_hq.png` | Hovedkvarter – Operationsrum |
| `bg_range.png` | Træningsbane – Udendørs bane |
| `bg_vehicle.png` | Køretøj – Pansret mandskabsvogn |
| `bg_city.png` | Byen om natten – København by night |

## 5. App-ikon

| Filnavn | Størrelse | Bruges |
|---|---|---|
| `App/Assets.xcassets/AppIcon.appiconset/AppIcon.png` | 1024×1024, **ikke** gennemsigtig | Hjemmeskærm (erstat placeholder-skjoldet) |

## Tjekliste – i alt
- [ ] 7 × `op_<model>_*.png` til den valgte model (+ valgfrit uniform-varianter)
- [ ] 38 × `gear_*.png`
- [ ] 15 × `wpn_*.png`
- [ ] 4 × `bg_*.png`
- [ ] 1 × AppIcon
