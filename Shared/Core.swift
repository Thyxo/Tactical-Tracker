import Foundation
import SwiftUI
import UIKit

// MARK: - App Group (læses ved runtime – AltStore/SideStore kan omskrive ID'et)

enum AppGroup {
    static let identifier: String? = resolve()

    static var containerURL: URL {
        if let id = identifier,
           let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) {
            return url
        }
        let fallback = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
        return fallback
    }

    static var isShared: Bool {
        guard let id = identifier else { return false }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) != nil
    }

    static var defaults: UserDefaults {
        identifier.flatMap { UserDefaults(suiteName: $0) } ?? .standard
    }

    private static func candidates() -> [String] {
        var list: [String] = []
        let info = Bundle.main.infoDictionary ?? [:]
        if let alt = info["ALTAppGroups"] as? [String] { list.append(contentsOf: alt) }
        if let own = info["TacticalAppGroup"] as? String { list.append(own) }
        if var bid = Bundle.main.bundleIdentifier {
            if Bundle.main.bundleURL.pathExtension == "appex" {
                var parts = bid.split(separator: ".").map(String.init)
                if parts.count > 1 { parts.removeLast() }
                bid = parts.joined(separator: ".")
            }
            list.append("group." + bid)
        }
        return list
    }

    private static func resolve() -> String? {
        let list = candidates()
        for id in list where FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) != nil {
            return id
        }
        return list.first
    }
}

// MARK: - Farver

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

/// Udseende: mørkt (standard, den oprindelige taktiske palet) eller lyst (Sælliv-agtigt).
enum ThemeMode: String, CaseIterable, Identifiable {
    case dark, light
    var id: String { rawValue }
    var displayName: String { self == .dark ? "Mørk" : "Lys" }
    static let storageKey = "themeMode"
    /// Gemmes i App Group, så widget og Live Activity følger med.
    static var stored: ThemeMode {
        get { AppGroup.defaults.string(forKey: storageKey).flatMap(ThemeMode.init(rawValue:)) ?? .dark }
        set { AppGroup.defaults.set(newValue.rawValue, forKey: storageKey) }
    }
}

@Observable final class ThemeState {
    static let shared = ThemeState()
    var mode: ThemeMode = ThemeMode.stored
}

/// Farver. Samme navne i begge temaer: `night` = sidens baggrund, `panel` = kort, `tan` = accent.
enum Theme {
    /// Aktivt tema. Læses gennem et @Observable objekt, så alle skærme tegnes om, når det skiftes.
    static var mode: ThemeMode {
        get { ThemeState.shared.mode }
        set { ThemeState.shared.mode = newValue }
    }
    static var isDark: Bool { mode == .dark }
    private static func pick(_ dark: UInt32, _ light: UInt32) -> Color { Color(hex: isDark ? dark : light) }

    /// Baggrund og flader.
    static var night: Color { pick(0x0F1418, 0xF2F1EC) }
    static var panel: Color { pick(0x1A2128, 0xFFFFFF) }
    static var panelHigh: Color { pick(0x242D36, 0xECEBE4) }
    static var line: Color { pick(0x33404C, 0xD8D6CC) }
    /// Små piller/knapper oven på scenen og kort.
    static var surface: Color { pick(0x1A2128, 0xFFFFFF) }
    /// Tekst.
    static var text: Color { pick(0xE8EDF0, 0x2F3832) }
    static var textSoft: Color { pick(0x93A1AD, 0x858C84) }
    /// Accent og tekst oven på accent.
    static var tan: Color { pick(0xC8A86B, 0x5F7356) }
    static var tanLight: Color { pick(0x2E2C24, 0xDDE5D5) }
    static var onAccent: Color { pick(0x0F1418, 0xFFFFFF) }
    static var olive: Color { Color(hex: 0x6E7B4F) }
    static var ready: Color { pick(0x5FD08A, 0x5AA572) }
    static var steady: Color { pick(0x58A6E8, 0x6A93B8) }
    static var amber: Color { pick(0xF2B134, 0xD9A441) }
    static var alert: Color { pick(0xE5534B, 0xD0645A) }
    static var violet: Color { pick(0x9C8CF0, 0x9A90C8) }
    /// Mørk "skærm"-baggrund (scener, widget).
    static let ink = Color(hex: 0x1C2420)
    /// Lys accent til Dynamic Island (altid sort baggrund).
    static let islandAccent = Color(hex: 0xDDE5D5)
    /// Skygge under kort (kun synlig i lyst tema).
    static var shadow: Color { Color.black.opacity(isDark ? 0 : 1) }
    /// Figur.
    static let eye = Color(hex: 0x1E2328)
    static let metal = Color(hex: 0x3A4148)
    static let metalLight = Color(hex: 0x5A636C)
    static let polymer = Color(hex: 0x23272B)
    static let coyote = Color(hex: 0xA8875A)
    static let gold = Color(hex: 0xE2B451)
    static let goldDark = Color(hex: 0xB0862E)
}

extension Font {
    /// Rund, rolig skrift (som Sælliv).
    static func tac(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Tal og korte koder – også runde, men lidt tungere.
    static func stencil(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Uniform og hudfarve

enum Camo: String, Codable, CaseIterable, Identifiable {
    case black, navy, olive, coyote, urban

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .black: return "Sort (SWAT)"
        case .navy: return "Marineblå"
        case .olive: return "Oliven"
        case .coyote: return "Coyote"
        case .urban: return "Urban grå"
        }
    }

    /// Hovedfarve på trøje og bukser.
    var main: Color {
        switch self {
        case .black: return Color(hex: 0x2A2F35)
        case .navy: return Color(hex: 0x24324A)
        case .olive: return Color(hex: 0x56603F)
        case .coyote: return Color(hex: 0x9A7E58)
        case .urban: return Color(hex: 0x6C737A)
        }
    }

    /// Lysere nuance (lys fra oven, folder).
    var light: Color {
        switch self {
        case .black: return Color(hex: 0x3B424A)
        case .navy: return Color(hex: 0x33466A)
        case .olive: return Color(hex: 0x6E7A52)
        case .coyote: return Color(hex: 0xB49870)
        case .urban: return Color(hex: 0x878F96)
        }
    }

    /// Mørk nuance (skygger, bukser, støvler).
    var dark: Color {
        switch self {
        case .black: return Color(hex: 0x1B1F23)
        case .navy: return Color(hex: 0x182236)
        case .olive: return Color(hex: 0x3E4530)
        case .coyote: return Color(hex: 0x6F5A3E)
        case .urban: return Color(hex: 0x4C5257)
        }
    }

    /// Lille camo-plet til mønster (bruges sparsomt).
    var spot: Color {
        switch self {
        case .black: return Color(hex: 0x343A40)
        case .navy: return Color(hex: 0x2C3C58)
        case .olive: return Color(hex: 0x4A5236)
        case .coyote: return Color(hex: 0x86704D)
        case .urban: return Color(hex: 0x5D646A)
        }
    }
}

enum SkinTone: String, Codable, CaseIterable, Identifiable {
    case light, medium, tan, deep

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Lys"
        case .medium: return "Mellem"
        case .tan: return "Gylden"
        case .deep: return "Mørk"
        }
    }

    var main: Color {
        switch self {
        case .light: return Color(hex: 0xF1C9A5)
        case .medium: return Color(hex: 0xD9A47A)
        case .tan: return Color(hex: 0xB57E52)
        case .deep: return Color(hex: 0x7A5034)
        }
    }

    var shade: Color {
        switch self {
        case .light: return Color(hex: 0xDDAE88)
        case .medium: return Color(hex: 0xC08660)
        case .tan: return Color(hex: 0x98643E)
        case .deep: return Color(hex: 0x5E3C26)
        }
    }
}

// MARK: - Readiness-tilstande

enum ReadinessState: String, Codable, CaseIterable {
    case ready, steady, tired, exhausted, suspended, leave, resting

    var displayName: String {
        switch self {
        case .ready: return "Klar"
        case .steady: return "Stabil"
        case .tired: return "Træt"
        case .exhausted: return "Udmattet"
        case .suspended: return "Suspenderet"
        case .leave: return "Orlov"
        case .resting: return "Hviler"
        }
    }

    var symbol: String {
        switch self {
        case .ready: return "bolt.fill"
        case .steady: return "checkmark.shield.fill"
        case .tired: return "battery.25"
        case .exhausted: return "battery.0"
        case .suspended: return "exclamationmark.octagon.fill"
        case .leave: return "airplane"
        case .resting: return "moon.zzz.fill"
        }
    }

    var tint: Color {
        switch self {
        case .ready: return Theme.ready
        case .steady: return Theme.steady
        case .tired: return Theme.amber
        case .exhausted: return Color(hex: 0xF07F45)
        case .suspended: return Theme.alert
        case .leave: return Theme.tan
        case .resting: return Theme.violet
        }
    }

    static func from(readiness: Double, daysAtZero: Int, onLeave: Bool) -> ReadinessState {
        if onLeave { return .leave }
        if readiness >= Tuning.readyThreshold { return .ready }
        if readiness >= Tuning.steadyThreshold { return .steady }
        if readiness >= Tuning.tiredThreshold { return .tired }
        if readiness >= 1 { return .exhausted }
        return daysAtZero >= Tuning.suspendedAfterDaysAtZero ? .suspended : .exhausted
    }
}

/// Valgfrit billede fra Assets/Incoming (ellers nil → kodet placeholder).
func incomingImage(_ name: String) -> UIImage? {
    UIImage(named: name)
}
