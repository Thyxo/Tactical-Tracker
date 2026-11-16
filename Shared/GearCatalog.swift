import Foundation
import SwiftUI

// MARK: - Sjældenhed

enum Rarity: Int, Codable, CaseIterable, Identifiable, Comparable {
    case common = 0, rare, epic, legendary

    var id: Int { rawValue }

    static func < (a: Rarity, b: Rarity) -> Bool { a.rawValue < b.rawValue }

    var displayName: String {
        switch self {
        case .common: return "Almindelig"
        case .rare: return "Sjælden"
        case .epic: return "Episk"
        case .legendary: return "Legendarisk"
        }
    }

    var color: Color {
        switch self {
        case .common: return Color(hex: 0x9AA5B1)
        case .rare: return Color(hex: 0x4FA3F7)
        case .epic: return Color(hex: 0xB26BF0)
        case .legendary: return Color(hex: 0xF2B134)
        }
    }

    var rating: Int {
        switch self {
        case .common: return Tuning.Loadout.ratingCommon
        case .rare: return Tuning.Loadout.ratingRare
        case .epic: return Tuning.Loadout.ratingEpic
        case .legendary: return Tuning.Loadout.ratingLegendary
        }
    }

    var basePrice: Int {
        switch self {
        case .common: return Tuning.Price.common
        case .rare: return Tuning.Price.rare
        case .epic: return Tuning.Price.epic
        case .legendary: return Tuning.Price.legendary
        }
    }

    /// Laveste rank (Rank.rawValue), der må købe denne sjældenhed.
    var minRank: Int {
        switch self {
        case .common: return 0
        case .rare: return 1
        case .epic: return 2
        case .legendary: return 3
        }
    }
}

// MARK: - Kategorier

enum GearCategory: String, Codable, CaseIterable, Identifiable {
    case helmet, eyewear, nvg, face, vest, pouch, patch, pistol, smg, rifle, background

    var id: String { rawValue }

    var title: String {
        switch self {
        case .helmet: return "Hjelme"
        case .eyewear: return "Briller"
        case .nvg: return "Nattesyn"
        case .face: return "Ansigt"
        case .vest: return "Veste"
        case .pouch: return "Tasker"
        case .patch: return "Patches"
        case .pistol: return "Pistoler"
        case .smg: return "MP'er"
        case .rifle: return "Rifler"
        case .background: return "Baser"
        }
    }

    var symbol: String {
        switch self {
        case .helmet: return "shield.lefthalf.filled"
        case .eyewear: return "eyeglasses"
        case .nvg: return "binoculars.fill"
        case .face: return "headphones"
        case .vest: return "tshirt.fill"
        case .pouch: return "bag.fill"
        case .patch: return "seal.fill"
        case .pistol, .smg, .rifle: return "scope"
        case .background: return "building.2.fill"
        }
    }

    var isWeapon: Bool { self == .pistol || self == .smg || self == .rifle }

    /// Kategorier i butikkens "Udstyr"-fane.
    static let gear: [GearCategory] = [.helmet, .eyewear, .nvg, .face, .vest, .pouch, .patch]
    /// Kategorier i Våbenskabet.
    static let weapons: [GearCategory] = [.pistol, .smg, .rifle]

    /// Ankerpunkt på figuren (andel af figurens størrelse).
    var anchor: (x: Double, y: Double) {
        typealias A = Tuning.Anchor
        switch self {
        case .helmet: return A.helmet
        case .eyewear: return A.eyewear
        case .nvg: return A.nvg
        case .face: return A.face
        case .vest: return A.vest
        case .pouch: return A.pouch
        case .patch: return A.patch
        case .pistol: return A.holster
        case .smg, .rifle: return A.longgun
        case .background: return (0.5, 0.5)
        }
    }

    /// Standard-lag (højere = tegnes ovenpå). Rækkefølgen kan ændres i "Tilpas".
    var baseLayer: Int {
        switch self {
        case .rifle, .smg: return 10
        case .vest: return 20
        case .pouch: return 30
        case .patch: return 35
        case .pistol: return 40
        case .face: return 50
        case .eyewear: return 60
        case .helmet: return 70
        case .nvg: return 80
        case .background: return 0
        }
    }

    /// Hvordan et våben bæres på figuren (rotation i grader). Våben tegnes vandret med mundingen mod højre.
    var carriedRotation: Double {
        switch self {
        case .pistol: return 90
        case .smg: return -38
        case .rifle: return -38
        default: return 0
        }
    }

    /// Hvor stort et våben tegnes, når det bæres (1 = som i galleriet relativt til figuren).
    var carriedScale: Double {
        switch self {
        case .pistol: return 0.8
        case .smg: return 0.9
        case .rifle: return 0.9
        default: return 1
        }
    }
}

// MARK: - Varer

struct GearItem: Identifiable, Hashable {
    let id: String
    let name: String
    let category: GearCategory
    let rarity: Rarity
    /// Rigtig model som tekst (kun visning).
    let model: String
    let blurb: String
    /// Hvis sat: kan kun købes i denne måned (1–12).
    let seasonMonth: Int?
    let priceOverride: Int?

    init(_ id: String, _ name: String, _ category: GearCategory, _ rarity: Rarity,
         model: String = "", blurb: String = "", season: Int? = nil, price: Int? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.rarity = rarity
        self.model = model
        self.blurb = blurb
        self.seasonMonth = season
        self.priceOverride = price
    }

    var price: Int {
        if let p = priceOverride { return p }
        if category == .background { return Tuning.Price.background }
        let base = Double(rarity.basePrice)
        return Int((category.isWeapon ? base * Tuning.Price.weaponFactor : base).rounded())
    }

    var isSeasonal: Bool { seasonMonth != nil }

    var isInSeason: Bool {
        guard let m = seasonMonth else { return true }
        return Calendar.current.component(.month, from: Date()) == m
    }

    var seasonName: String {
        switch seasonMonth {
        case 12: return "December"
        case 10: return "Oktober"
        default: return "Sæson"
        }
    }
}

enum GearCatalog {
    static let defaultBackground = "hq"

    static let items: [GearItem] = [
        // Hjelme og hovedbeklædning
        GearItem("helmet_fast", "FAST-hjelm", .helmet, .rare, model: "Ops-Core FAST SF", blurb: "Let high-cut hjelm med skinner til lygte og kamera."),
        GearItem("helmet_ach", "ACH-hjelm", .helmet, .common, model: "ACH / MICH 2000", blurb: "Klassisk hjelm. Solid og ærlig."),
        GearItem("helmet_pasgt", "PASGT-hjelm", .helmet, .common, model: "PASGT", blurb: "Den gamle 'fritz'. Tung, men tro."),
        GearItem("cap_swat", "SWAT-kasket", .helmet, .common, model: "Sort feltkasket", blurb: "Til briefinger og lange dage."),
        GearItem("beanie_watch", "Strikhue", .helmet, .common, model: "Watch cap", blurb: "Til nattevagter på Langelinie."),
        GearItem("boonie", "Boonie-hat", .helmet, .common, model: "Boonie hat, coyote", blurb: "Skygge til træningsbanen."),
        GearItem("helmet_exfil", "EXFIL-hjelm", .helmet, .epic, model: "Team Wendy EXFIL LTP", blurb: "Ballistisk letvægt med rails."),
        GearItem("helmet_gold", "Ceremonihjelm", .helmet, .legendary, model: "Paradehjelm i guld", blurb: "Kun til de allerbedste."),
        GearItem("helmet_nisse", "Nisse-overtræk", .helmet, .common, model: "Julevagt-overtræk", blurb: "December-vagt med stil.", season: 12),

        // Briller
        GearItem("glasses_mframe", "Skydebriller", .eyewear, .common, model: "Oakley SI M-Frame", blurb: "Wraparound-briller med farvede glas."),
        GearItem("glasses_crossbow", "Crossbow-briller", .eyewear, .rare, model: "ESS Crossbow", blurb: "Ballistiske briller med skarp profil."),
        GearItem("goggles_locust", "Ørkenbriller", .eyewear, .rare, model: "Revision Desert Locust", blurb: "Goggles mod støv og sand."),
        GearItem("glasses_aviator", "Pilotbriller", .eyewear, .epic, model: "Randolph Aviator", blurb: "Guldstel. Ingen forklaring nødvendig."),

        // Nattesyn
        GearItem("nvg_pvs14", "Monokular", .nvg, .rare, model: "AN/PVS-14", blurb: "Ét rør, foldet op på hjelmen."),
        GearItem("nvg_pvs31", "Binokular", .nvg, .epic, model: "AN/PVS-31A", blurb: "To rør, let og kompakt."),
        GearItem("nvg_gpnvg", "Quad-nattesyn", .nvg, .legendary, model: "L3Harris GPNVG-18", blurb: "Fire rør. Det ikoniske look."),

        // Ansigt og kommunikation
        GearItem("face_balaclava", "Balaklava", .face, .common, model: "Sort balaklava", blurb: "Holder varmen og anonymiteten."),
        GearItem("face_shemagh", "Shemagh", .face, .common, model: "Shemagh, oliven", blurb: "Tørklæde om halsen og munden."),
        GearItem("face_headset", "Headset", .face, .rare, model: "Peltor ComTac VI", blurb: "Høreværn og radio i ét."),
        GearItem("face_skull", "Kraniemaske", .face, .epic, model: "Halvmaske med kranie", blurb: "Lidt for cool til morgenmødet."),

        // Veste
        GearItem("vest_police", "POLITI-vest", .vest, .common, model: "Skjult beskyttelsesvest", blurb: "Blå vest med POLITI på brystet."),
        GearItem("vest_swat", "SWAT-vest", .vest, .common, model: "Plate carrier, sort", blurb: "Sort vest med SWAT-panel."),
        GearItem("vest_chestrig", "Chest rig", .vest, .common, model: "Chest rig, oliven", blurb: "Let rig med magasinlommer."),
        GearItem("vest_jpc", "JPC 2.0", .vest, .rare, model: "Crye Precision JPC 2.0", blurb: "Minimalistisk plate carrier."),
        GearItem("vest_avs", "AVS", .vest, .epic, model: "Crye Precision AVS", blurb: "Fuld beskyttelse med cummerbund."),
        GearItem("vest_gold", "Guldvest", .vest, .legendary, model: "Plate carrier, guldkant", blurb: "Til den der har set det hele."),

        // Tasker (kan stables oven på vesten)
        GearItem("pouch_mags", "Magasintasker", .pouch, .common, model: "3× M4-magasintaske", blurb: "Tre lommer på række."),
        GearItem("pouch_ifak", "IFAK", .pouch, .common, model: "Førstehjælpstaske", blurb: "Rødt kors – altid med."),
        GearItem("pouch_light", "Lygte", .pouch, .common, model: "SureFire-lygte", blurb: "Lys i mørket."),
        GearItem("pouch_admin", "Admin-panel", .pouch, .common, model: "Admin pouch", blurb: "Kuglepen, notesbog og plan."),
        GearItem("pouch_radio", "Radio", .pouch, .rare, model: "L3Harris AN/PRC-152", blurb: "Radio med antenne."),

        // Patches
        GearItem("patch_dk", "Dannebrog", .patch, .common, model: "Flag-patch", blurb: "Rødt og hvidt på skulderen."),
        GearItem("patch_swat", "SWAT-patch", .patch, .common, model: "Tekst-patch", blurb: "Sort og hvid."),
        GearItem("patch_blood", "Blodtype", .patch, .common, model: "O POS", blurb: "Praktisk og personlig."),
        GearItem("patch_ir", "IR-flag", .patch, .rare, model: "Infrarødt flag", blurb: "Gråt flag, der lyser i nattesyn."),
        GearItem("patch_seal", "Sæl-patch", .patch, .rare, model: "Moral-patch", blurb: "En lille hilsen fra Sælliv."),
        GearItem("patch_kbh", "København", .patch, .epic, model: "Byvåben", blurb: "Tre tårne. Hjemmebane."),
        GearItem("patch_star", "Guldstjerne", .patch, .legendary, model: "Officersstjerne", blurb: "Glimter i solen."),

        // Pistoler
        GearItem("pistol_glock17", "Glock 17", .pistol, .common, model: "Glock 17 Gen5", blurb: "Standard-tjenestepistol i mange korps."),
        GearItem("pistol_p226", "P226", .pistol, .rare, model: "SIG Sauer P226", blurb: "Stålramme og klassisk linje."),
        GearItem("pistol_usp", "USP", .pistol, .rare, model: "Heckler & Koch USP", blurb: "Tysk præcision."),
        GearItem("pistol_1911", "M1911", .pistol, .epic, model: "Colt M1911A1", blurb: "Over hundrede år gammelt design."),
        GearItem("pistol_deagle", "Desert Eagle", .pistol, .legendary, model: "Magnum Research Desert Eagle (guld)", blurb: "Samlerobjekt. Tungt og skinnende."),

        // Maskinpistoler
        GearItem("smg_mp5", "MP5", .smg, .rare, model: "Heckler & Koch MP5A3", blurb: "Den klassiske SWAT-MP."),
        GearItem("smg_ump", "UMP", .smg, .rare, model: "Heckler & Koch UMP45", blurb: "Kantet polymer-design."),
        GearItem("smg_mp7", "MP7", .smg, .epic, model: "Heckler & Koch MP7A2", blurb: "Kompakt og fremtidsagtig."),
        GearItem("smg_vector", "Vector", .smg, .legendary, model: "KRISS Vector", blurb: "Sci-fi-silhuet."),

        // Rifler
        GearItem("rifle_m4", "M4A1", .rifle, .common, model: "Colt M4A1", blurb: "Grundmodellen alle kender."),
        GearItem("rifle_m10", "Gevær M/10", .rifle, .rare, model: "Colt Canada C8 IUR", blurb: "Forsvarets standardgevær."),
        GearItem("rifle_ak", "AK-74", .rifle, .rare, model: "Kalashnikov AK-74", blurb: "Den buede magasin-silhuet."),
        GearItem("rifle_hk416", "HK416", .rifle, .epic, model: "Heckler & Koch HK416", blurb: "Specialstyrkernes favorit."),
        GearItem("rifle_scar", "SCAR-H", .rifle, .epic, model: "FN SCAR-H", blurb: "Coyote-farvet og kantet."),
        GearItem("rifle_sr25", "SR-25", .rifle, .legendary, model: "Knight's Armament SR-25", blurb: "Præcisionsgevær med kikkert."),

        // Baser (baggrunde)
        GearItem("hq", "Hovedkvarter", .background, .common, model: "Operationsrum", blurb: "Kort, skærme og kaffe.", price: 0),
        GearItem("range", "Træningsbane", .background, .rare, model: "Udendørs bane", blurb: "Skiver, sandsække og himmel."),
        GearItem("vehicle", "Køretøj", .background, .epic, model: "Pansret mandskabsvogn", blurb: "Indvendigt i vognen på vej ud."),
        GearItem("city", "Byen om natten", .background, .legendary, model: "København by night", blurb: "Tårne og lys over havnen."),
    ]

    private static let byID: [String: GearItem] = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })

    static func item(_ id: String?) -> GearItem? {
        guard let id else { return nil }
        return byID[id]
    }

    static func items(in category: GearCategory) -> [GearItem] {
        items.filter { $0.category == category }
    }
}
