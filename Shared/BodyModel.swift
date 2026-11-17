import SwiftUI

/// Mål på en kropsmodel (andele af figurens størrelse s). Udstyr flyttes og skaleres ud fra disse,
/// så samme hjelm/vest passer på alle modeller.
struct BodyGeometry {
    /// Hovedets centrum og størrelse (ellipse).
    var headCenter: CGPoint
    var headSize: CGSize
    /// Øjnenes højde og vandrette afstand fra midten.
    var eyeY: CGFloat
    var eyeDX: CGFloat
    /// Torso (trøje) som rektangel: x, y, bredde, højde.
    var torso: CGRect
    /// Højre hånd (set forfra: billedets højre side) og højre hofte.
    var rightHand: CGPoint
    var rightHip: CGPoint

    /// Den oprindelige figur (Docs/DRAWING_CONTRACT.md) – udstyret er tegnet til disse mål.
    static let reference = BodyGeometry(
        headCenter: CGPoint(x: 0.50, y: 0.265), headSize: CGSize(width: 0.25, height: 0.27),
        eyeY: 0.28, eyeDX: 0.045,
        torso: CGRect(x: 0.32, y: 0.42, width: 0.36, height: 0.29),
        rightHand: CGPoint(x: 0.73, y: 0.70), rightHip: CGPoint(x: 0.69, y: 0.73))
}

/// Hvilken figur brugeren har valgt.
enum BodyModel: String, Codable, CaseIterable, Identifiable {
    case athletic, soft, icon, classic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .athletic: return "Atlet"
        case .soft: return "Blød"
        case .icon: return "Ikon"
        case .classic: return "Klassisk"
        }
    }

    var subtitle: String {
        switch self {
        case .athletic: return "Slank, voksne proportioner"
        case .soft: return "Enkel og rund – som Sælliv"
        case .icon: return "Minimalistisk piktogram"
        case .classic: return "Første udkast"
        }
    }

    var geometry: BodyGeometry {
        switch self {
        case .athletic: return OperatorBodyAthletic.geometry
        case .soft: return OperatorBodySoft.geometry
        case .icon: return OperatorBodyIcon.geometry
        case .classic: return .reference
        }
    }

    static let storageKey = "bodyModel"

    /// Gemmes i App Group, så widget og Live Activity viser samme figur.
    static var current: BodyModel {
        get { AppGroup.defaults.string(forKey: storageKey).flatMap(BodyModel.init(rawValue:)) ?? .soft }
        set { AppGroup.defaults.set(newValue.rawValue, forKey: storageKey) }
    }
}

/// Tegner den valgte kropsmodel.
struct OperatorBodyView: View {
    let model: BodyModel
    let camo: Camo
    let skin: SkinTone
    let state: ReadinessState
    let s: CGFloat
    let t: Double
    let animated: Bool

    var body: some View {
        switch model {
        case .athletic: OperatorBodyAthletic(camo: camo, skin: skin, state: state, s: s, t: t, animated: animated)
        case .soft: OperatorBodySoft(camo: camo, skin: skin, state: state, s: s, t: t, animated: animated)
        case .icon: OperatorBodyIcon(camo: camo, skin: skin, state: state, s: s, t: t, animated: animated)
        case .classic: OperatorBody(camo: camo, skin: skin, state: state, s: s, t: t, animated: animated)
        }
    }
}

extension GearCategory {
    /// Er udstyret placeret efter hovedet (ellers efter torso/hofte)?
    var followsHead: Bool { self == .helmet || self == .eyewear || self == .nvg || self == .face }
}

extension BodyGeometry {
    /// Placering og skalering af en ting på denne model, ud fra hvor den sidder på referencefiguren.
    func place(_ category: GearCategory) -> (point: CGPoint, sx: CGFloat, sy: CGFloat) {
        let ref = BodyGeometry.reference
        let a = category.anchor
        let ax = CGFloat(a.x)
        let ay = CGFloat(a.y)
        if category.followsHead {
            let k: CGFloat = headSize.width / ref.headSize.width
            let ky: CGFloat = headSize.height / ref.headSize.height
            let x: CGFloat = headCenter.x + (ax - ref.headCenter.x) * k
            let y: CGFloat = headCenter.y + (ay - ref.headCenter.y) * ky
            return (CGPoint(x: x, y: y), k, ky)
        }
        if category == .pistol {
            let k: CGFloat = torso.width / ref.torso.width
            let x: CGFloat = rightHip.x + (ax - ref.rightHip.x) * k
            let y: CGFloat = rightHip.y + (ay - ref.rightHip.y) * k
            return (CGPoint(x: x, y: y), k, k)
        }
        let sx: CGFloat = torso.width / ref.torso.width
        let sy: CGFloat = torso.height / ref.torso.height
        let x: CGFloat = torso.midX + (ax - ref.torso.midX) * sx
        let y: CGFloat = torso.midY + (ay - ref.torso.midY) * sy
        if category.isWeapon {
            // Lange våben skal ikke forvrænges – brug ens skalering.
            let k: CGFloat = (sx + sy) / 2
            return (CGPoint(x: x, y: y), k, k)
        }
        return (CGPoint(x: x, y: y), sx, sy)
    }
}

// MARK: - Environment (så hele appen tegner om, når modellen skiftes)

private struct OperatorModelKey: EnvironmentKey {
    static let defaultValue: BodyModel? = nil
}

extension EnvironmentValues {
    var operatorModel: BodyModel? {
        get { self[OperatorModelKey.self] }
        set { self[OperatorModelKey.self] = newValue }
    }
}
