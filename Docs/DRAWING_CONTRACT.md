# Tegnekontrakt (figur, udstyr, våben, baser)

Alt i appen kan tegnes i kode (placeholders), indtil der ligger billeder i `Assets/Incoming/`.
Denne fil beskriver koordinaterne, så figur, udstyr og våben passer sammen.

## Koordinater

Figuren tegnes i et kvadrat på `s × s` punkter. Alle mål er andele af `s`; (0,0) er øverst til venstre.
Figuren ses forfra, let "chibi" (stort hoved), rolig og venlig – ingen vold, ingen blod.

| Del | Placering (andel af s) |
|---|---|
| Skygge på gulvet | ellipse centrum (0.50, 0.955), 0.50 × 0.05 |
| Støvler | centre (0.43, 0.92) og (0.57, 0.92), hver 0.12 × 0.06 |
| Ben (bukser) | y 0.70–0.90; venstre x 0.375–0.49, højre x 0.51–0.625 |
| Bælte | y 0.695–0.725, x 0.33–0.67 |
| Torso (trøje) | afrundet rektangel x 0.32–0.68, y 0.42–0.71 |
| Skuldre | (0.32, 0.455) og (0.68, 0.455) |
| Arme | fra skuldre ned til hænder i (0.27, 0.70) og (0.73, 0.70); armbredde ca. 0.085 |
| Hænder/handsker | cirkler r = 0.035 i (0.27, 0.70) og (0.73, 0.70) |
| Hals | x 0.455–0.545, y 0.38–0.43 |
| Hoved | ellipse centrum (0.50, 0.265), bredde 0.25, højde 0.27 (top y 0.13, bund y 0.40) |
| Ører | (0.372, 0.28) og (0.628, 0.28), 0.035 × 0.05 |
| Øjne | (0.455, 0.28) og (0.545, 0.28), ca. 0.028 |
| Bryn | y 0.255 |
| Næse / mund | y 0.315 / y 0.348 |

## Udstyr (`GearDesigns.view(id, s:)`)

Hver ting tegnes centreret i sit **eget** koordinatsystem: visningens midtpunkt lægges på ankerpunktet.
Brug `.frame(width:height:)` + `.offset(...)` inde i en `ZStack`; returnér aldrig noget med uendelig størrelse.

| Kategori | Anker (x, y) | Hvad skal dækkes |
|---|---|---|
| helmet | (0.50, 0.17) | Kuppel over hovedet: top y≈0.115, kant y≈0.225 (= +0.055), bredde ≈0.29 |
| eyewear | (0.50, 0.28) | Glas over øjnene (±0.045), samlet bredde ≈0.22–0.25 |
| nvg | (0.50, 0.15) | Nattesyn foldet op foran på hjelmen, ca. 0.10–0.20 bred, 0.08 høj |
| face | (0.50, 0.31) | Balaklava: hele hovedet undtagen øjenspalte y 0.265–0.30. Headset: ørekopper i x ±0.13, y −0.03 relativt. Shemagh: nedre ansigt + hals |
| vest | (0.50, 0.56) | Torso x 0.33–0.67, y 0.44–0.69, med skulderstropper |
| pouch | (0.50, 0.64) | Lille ting foran på vesten, ca. 0.22 × 0.07 |
| patch | (0.33, 0.49) | Lille mærke på venstre overarm (set forfra), ca. 0.07 × 0.05 |

## Våben (`WeaponDesigns.view(id, s:)`)

Kosmetiske skins til galleriet. Tegnes **vandret, mundingen mod højre, greb nedad**, centreret i bounding box.
Længde (andel af s): pistol 0.20, MP 0.40, riffel 0.60 (SR-25 må være 0.66).
Når de bæres, roterer figuren dem selv (pistol 90° i hylster på højre hofte, lange våben −38° i rem over brystet).
Ingen mundingsflammer, ingen projektiler, ingen blod.

## Baser (`SceneBackground(id:)`)

Fylder hele den frame den får. Nederste midterste tredjedel holdes rolig (der står figuren),
toppen simpel (der ligger navn, credits og taleboble). Mørk taktisk palet.
id'er: `hq`, `range`, `vehicle`, `city`.

## Billeder i stedet for kode

Findes `op_<state>.png`, `gear_<id>.png`, `wpn_<id>.png` eller `bg_<id>.png` i `Assets/Incoming/`, bruges billedet. Se `ASSETS.md`.
