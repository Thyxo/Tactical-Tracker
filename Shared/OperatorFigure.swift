import SwiftUI
import UIKit

/// Operatøren med udstyr. Bruger billeder fra Assets/Incoming hvis de findes (op_<camo>_<state>.png
/// eller op_<state>.png), ellers tegnes figuren i kode. Udstyr lægges på i rækkefølgen `equipped`
/// (første nederst), så flere ting – også fra samme kategori – kan stables.
struct OperatorFigure: View {
    var camo: Camo
    var skin: SkinTone
    var state: ReadinessState
    var equipped: [String] = []
    var animated: Bool = true
    /// Bruges af tilpas-editoren til live-visning; ellers læses de gemte justeringer.
    var fits: [String: ItemFit]? = nil
    /// Stand pr. ting (0–100). Slidt udstyr tegnes en anelse falmet.
    var condition: [String: Double] = [:]
    /// Fremhæv en ting (tilpas-editoren).
    var highlight: String? = nil

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            Group {
                if animated {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
                        canvas(s: s, t: ctx.date.timeIntervalSinceReferenceDate)
                    }
                } else {
                    canvas(s: s, t: 0)
                }
            }
            .frame(width: s, height: s)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func canvas(s: CGFloat, t: Double) -> some View {
        OperatorCanvas(camo: camo, skin: skin, state: state, equipped: equipped, s: s, t: t,
                       animated: animated, fits: fits, condition: condition, highlight: highlight)
    }
}

struct OperatorCanvas: View {
    let camo: Camo
    let skin: SkinTone
    let state: ReadinessState
    let equipped: [String]
    let s: CGFloat
    let t: Double
    let animated: Bool
    var fits: [String: ItemFit]? = nil
    var condition: [String: Double] = [:]
    var highlight: String? = nil

    private typealias M = Tuning.Motion

    private var breathe: CGFloat {
        guard animated else { return 0 }
        let speed: Double = state == .resting ? M.breatheSpeedSleeping : M.breatheSpeed
        return CGFloat(sin(t * speed))
    }

    private var bounce: CGFloat {
        guard animated, state == .ready else { return 0 }
        let v: Double = max(0, sin(t * M.readyBounceSpeed))
        return -CGFloat(v * v) * s * CGFloat(M.readyBounceHeight)
    }

    private var sway: Double {
        guard animated else { return 0 }
        switch state {
        case .exhausted, .suspended, .resting: return sin(t * M.swaySpeed * 0.7) * M.swayDegrees * 1.4
        default: return sin(t * M.swaySpeed) * M.swayDegrees
        }
    }

    /// På orlov og under hvil bæres hverken hjelm, nattesyn eller våben.
    private var visibleGear: [String] {
        guard state == .leave || state == .resting else { return equipped }
        return equipped.filter { id in
            guard let c = GearCatalog.item(id)?.category else { return false }
            return !(c.isWeapon || c == .helmet || c == .nvg)
        }
    }

    private var bodyImage: UIImage? {
        if let img = incomingImage("op_\(camo.rawValue)_\(state.rawValue)") { return img }
        return incomingImage("op_\(state.rawValue)")
    }

    var body: some View {
        let shadowW: CGFloat = s * 0.5
        let shadowH: CGFloat = s * 0.05
        let breatheX: CGFloat = 1 + CGFloat(M.breatheAmount) * breathe
        let breatheY: CGFloat = 1 - CGFloat(M.breatheAmount) * 1.4 * breathe
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.28))
                .frame(width: shadowW, height: shadowH)
                .position(x: s * 0.5, y: s * 0.955)

            ZStack {
                if let img = bodyImage {
                    Image(uiImage: img).resizable().scaledToFit().frame(width: s, height: s)
                } else {
                    OperatorBody(camo: camo, skin: skin, state: state, s: s, t: t, animated: animated)
                }
                gearLayer
            }
            .frame(width: s, height: s)
            .scaleEffect(x: breatheX, y: breatheY, anchor: .bottom)
            .rotationEffect(.degrees(sway), anchor: .bottom)
            .offset(y: bounce)

            OperatorExtras(camo: camo, skin: skin, state: state, s: s, t: t, animated: animated)
                .frame(width: s, height: s)
        }
        .frame(width: s, height: s)
    }

    private var gearLayer: some View {
        ZStack {
            ForEach(Array(visibleGear.enumerated()), id: \.element) { _, id in
                if let item = GearCatalog.item(id), item.category != .background {
                    GearOnFigure(item: item, s: s, fit: fits?[id] ?? FitStore.shared.fit(id),
                                 condition: condition[id] ?? 100, highlighted: highlight == id)
                }
            }
        }
        .frame(width: s, height: s)
    }
}

/// Én ting placeret på figuren (anker + kategoriens standard + brugerens justering).
struct GearOnFigure: View {
    let item: GearItem
    let s: CGFloat
    let fit: ItemFit
    var condition: Double = 100
    var highlighted: Bool = false

    var body: some View {
        let a = item.category.anchor
        let x: CGFloat = s * CGFloat(a.x)
        let y: CGFloat = s * CGFloat(a.y)
        let worn: Double = max(0, (100 - condition) / 100)
        GearArt(item: item, s: s)
            .saturation(1 - worn * 0.6)
            .opacity(1 - worn * 0.15)
            .shadow(color: highlighted ? Theme.amber.opacity(0.9) : .clear, radius: highlighted ? s * 0.012 : 0)
            .fitted(fit, s: s)
            .position(x: x, y: y)
    }
}

/// Tegningen af en ting (billede fra Assets/Incoming eller kodet), inkl. våbnets bære-rotation.
struct GearArt: View {
    let item: GearItem
    let s: CGFloat

    var body: some View {
        if item.category.isWeapon {
            weapon
                .scaleEffect(CGFloat(item.category.carriedScale))
                .rotationEffect(.degrees(item.category.carriedRotation))
        } else if let img = incomingImage("gear_\(item.id)") {
            Image(uiImage: img).resizable().scaledToFit().frame(width: s * imageWidth)
        } else if let v = GearDesigns.view(item.id, s: s) {
            v
        } else {
            Image(systemName: item.category.symbol)
                .font(.system(size: s * 0.08, weight: .bold))
                .foregroundStyle(item.rarity.color)
        }
    }

    @ViewBuilder private var weapon: some View {
        if let img = incomingImage("wpn_\(item.id)") {
            Image(uiImage: img).resizable().scaledToFit()
                .frame(width: s * WeaponGeometry.length(item.category))
        } else if let v = WeaponDesigns.view(item.id, s: s) {
            v
        } else {
            Image(systemName: "scope").font(.system(size: s * 0.08))
        }
    }

    /// Bredde (andel af s) for billeder fra Assets/Incoming pr. kategori.
    private var imageWidth: CGFloat {
        switch item.category {
        case .helmet: return 0.34
        case .eyewear: return 0.26
        case .nvg: return 0.22
        case .face: return 0.34
        case .vest: return 0.42
        case .pouch: return 0.26
        case .patch: return 0.09
        default: return 0.3
        }
    }
}

/// Lille ikon af en ting til lister og butik.
struct ItemThumb: View {
    let item: GearItem
    var size: CGFloat = 80

    var body: some View {
        Group {
            if item.category == .background {
                ScenePreview(id: item.id)
            } else if item.category.isWeapon {
                WeaponDisplayView(id: item.id, size: size)
            } else if let img = incomingImage("gear_\(item.id)") {
                Image(uiImage: img).resizable().scaledToFit().padding(size * 0.1)
            } else {
                GearIconView(id: item.id, size: size)
            }
        }
        .frame(width: size, height: size)
    }
}
