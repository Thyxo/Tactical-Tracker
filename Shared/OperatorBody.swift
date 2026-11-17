import SwiftUI

// Operatøren tegnet med SwiftUI-former. Koordinater følger Docs/DRAWING_CONTRACT.md
// (alle mål er andele af s; (0,0) øverst til venstre). Kun selve figuren –
// hjelm, vest og våben lægges ovenpå af anden kode. Skyggen tegnes af wrapperen.

// MARK: - Geometri

enum OperatorGeometry {
    static func point(_ x: CGFloat, _ y: CGFloat, s: CGFloat) -> CGPoint {
        CGPoint(x: s * x, y: s * y)
    }
}

// MARK: - Små former

/// ∪ – smil / lukkede, sovende øjne.
struct OpCupShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY),
                       control: CGPoint(x: r.midX, y: r.minY + h * 2))
        return p
    }
}

/// ∩ – surmule-mund / glade lukkede øjne.
struct OpHumpShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY),
                       control: CGPoint(x: r.midX, y: r.maxY - h * 2))
        return p
    }
}

/// Kort hår-kalot med blød pandelok.
struct OpHairShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY),
                   control1: CGPoint(x: r.minX, y: r.minY + h * 0.30),
                   control2: CGPoint(x: r.minX + w * 0.22, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.maxY),
                   control1: CGPoint(x: r.maxX - w * 0.22, y: r.minY),
                   control2: CGPoint(x: r.maxX, y: r.minY + h * 0.30))
        p.addQuadCurve(to: CGPoint(x: r.midX + w * 0.10, y: r.maxY - h * 0.28),
                       control: CGPoint(x: r.maxX - w * 0.14, y: r.maxY - h * 0.48))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY),
                       control: CGPoint(x: r.minX + w * 0.24, y: r.maxY - h * 0.52))
        p.closeSubpath()
        return p
    }
}

/// Dråbe med spidsen opad.
struct OpDropShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addCurve(to: CGPoint(x: r.midX, y: r.maxY),
                   control1: CGPoint(x: r.maxX + w * 0.10, y: r.minY + h * 0.55),
                   control2: CGPoint(x: r.maxX, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY),
                   control1: CGPoint(x: r.minX, y: r.maxY),
                   control2: CGPoint(x: r.minX - w * 0.10, y: r.minY + h * 0.55))
        p.closeSubpath()
        return p
    }
}

/// Lem (arm) som en blød kurve i enheds-koordinater (0–1) i hele rammen.
struct OpLimbShape: Shape {
    let a: CGPoint
    let c: CGPoint
    let b: CGPoint

    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX + a.x * w, y: r.minY + a.y * h))
        p.addQuadCurve(to: CGPoint(x: r.minX + b.x * w, y: r.minY + b.y * h),
                       control: CGPoint(x: r.minX + c.x * w, y: r.minY + c.y * h))
        return p
    }
}

/// V-formet krave.
struct OpCollarShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.minX + w * 0.24, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY - h * 0.40))
        p.addLine(to: CGPoint(x: r.maxX - w * 0.24, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Trekant med spidsen nedad (hud i halsudskæringen).
struct OpVShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Takeaway-kop: bredest foroven.
struct OpCoffeeCupShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - w * 0.12, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + w * 0.12, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Lodret, bølgende damp-streg.
struct OpSteamShape: Shape {
    let phase: CGFloat

    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        let steps: Int = 16
        for i in 0...steps {
            let f: CGFloat = CGFloat(i) / CGFloat(steps)
            let angle: Double = Double(f) * Double.pi * 2.4 + Double(phase)
            let wave: CGFloat = CGFloat(sin(angle))
            let x: CGFloat = r.midX + w * 0.35 * wave
            let y: CGFloat = r.maxY - h * f
            if i == 0 {
                p.move(to: CGPoint(x: x, y: y))
            } else {
                p.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return p
    }
}

/// Camo-plet på trøjen.
struct OpCamoSpot {
    let x: CGFloat
    let y: CGFloat
    let w: CGFloat
    let h: CGFloat
    let r: Double
}

// MARK: - Figuren

struct OperatorBody: View {
    let camo: Camo
    let skin: SkinTone
    let state: ReadinessState
    let s: CGFloat
    let t: Double
    let animated: Bool

    private typealias M = Tuning.Motion

    private static let hairColor = Color(hex: 0x2B2420)
    private static let mouthColor = Color(hex: 0x4A2A24)
    private static let cheekColor = Color(hex: 0xE88A7A)

    private static let spots: [OpCamoSpot] = [
        OpCamoSpot(x: 0.39, y: 0.49, w: 0.06, h: 0.035, r: -18),
        OpCamoSpot(x: 0.58, y: 0.47, w: 0.05, h: 0.03, r: 22),
        OpCamoSpot(x: 0.62, y: 0.60, w: 0.065, h: 0.035, r: -10),
        OpCamoSpot(x: 0.42, y: 0.63, w: 0.055, h: 0.03, r: 14),
        OpCamoSpot(x: 0.52, y: 0.55, w: 0.04, h: 0.025, r: -30),
        OpCamoSpot(x: 0.36, y: 0.57, w: 0.03, h: 0.022, r: 8),
    ]

    private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        OperatorGeometry.point(x, y, s: s)
    }

    var body: some View {
        ZStack {
            legsLayer
            armsLayer
            torsoLayer
            beltLayer
            handsLayer
            neckLayer
            headLayer
            faceLayer
            suspendedTint
            sweatLayer
        }
        .frame(width: s, height: s)
        .saturation(state == .suspended ? 0.7 : 1)
    }

    // MARK: Bevægelse

    private var blink: CGFloat {
        guard animated else { return 1 }
        let p: Double = t.truncatingRemainder(dividingBy: M.blinkEvery)
        return p < 0.14 ? 0.12 : 1
    }

    // MARK: Ben og støvler

    private var legsLayer: some View {
        ZStack {
            leg(cx: 0.4325)
            leg(cx: 0.5675)
            boot(cx: 0.43)
            boot(cx: 0.57)
        }
    }

    private func leg(cx: CGFloat) -> some View {
        let w: CGFloat = s * 0.115
        let h: CGFloat = s * 0.205
        let pocketW: CGFloat = s * 0.05
        let pocketH: CGFloat = s * 0.045
        return ZStack {
            RoundedRectangle(cornerRadius: s * 0.02, style: .continuous)
                .fill(LinearGradient(colors: [camo.main, camo.dark],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: w, height: h)
            RoundedRectangle(cornerRadius: s * 0.008, style: .continuous)
                .stroke(camo.dark.opacity(0.7), lineWidth: max(0.5, s * 0.004))
                .frame(width: pocketW, height: pocketH)
                .offset(y: -s * 0.01)
        }
        .position(pt(cx, 0.80))
    }

    private func boot(cx: CGFloat) -> some View {
        let w: CGFloat = s * 0.12
        let h: CGFloat = s * 0.06
        return ZStack {
            RoundedRectangle(cornerRadius: s * 0.025, style: .continuous)
                .fill(Theme.polymer)
                .frame(width: w, height: h)
            Rectangle()
                .fill(Color.black.opacity(0.45))
                .frame(width: w * 0.96, height: s * 0.012)
                .offset(y: s * 0.022)
            Capsule()
                .fill(Theme.metal)
                .frame(width: s * 0.04, height: s * 0.006)
                .offset(y: -s * 0.012)
        }
        .position(pt(cx, 0.92))
    }

    // MARK: Arme

    private var shoulderY: CGFloat { state == .suspended ? 0.468 : 0.455 }
    private var handInset: CGFloat { state == .suspended ? 0.028 : 0 }
    private var handY: CGFloat { state == .suspended ? 0.705 : 0.70 }

    private var leftHand: CGPoint { CGPoint(x: 0.27 + handInset, y: handY) }
    private var rightHand: CGPoint { CGPoint(x: 0.73 - handInset, y: handY) }

    private var armsLayer: some View {
        let lh: CGPoint = leftHand
        let rh: CGPoint = rightHand
        let elbowY: CGFloat = 0.58
        let leftShoulder = CGPoint(x: 0.335, y: shoulderY)
        let rightShoulder = CGPoint(x: 0.665, y: shoulderY)
        let leftElbow = CGPoint(x: lh.x - 0.008, y: elbowY)
        let rightElbow = CGPoint(x: rh.x + 0.008, y: elbowY)
        return ZStack {
            arm(shoulder: leftShoulder, elbow: leftElbow, hand: lh)
            arm(shoulder: rightShoulder, elbow: rightElbow, hand: rh)
        }
    }

    private func arm(shoulder: CGPoint, elbow: CGPoint, hand: CGPoint) -> some View {
        let shape = OpLimbShape(a: shoulder, c: elbow, b: hand)
        let outer: CGFloat = s * 0.092
        let inner: CGFloat = s * 0.076
        let shine: CGFloat = s * 0.018
        return ZStack {
            shape.stroke(camo.dark, style: StrokeStyle(lineWidth: outer, lineCap: .round, lineJoin: .round))
            shape.stroke(camo.main, style: StrokeStyle(lineWidth: inner, lineCap: .round, lineJoin: .round))
            shape.stroke(camo.light.opacity(0.45), style: StrokeStyle(lineWidth: shine, lineCap: .round))
                .offset(x: -s * 0.008)
        }
        .frame(width: s, height: s)
    }

    // MARK: Torso

    private var torsoLayer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.06, style: .continuous)
                .fill(LinearGradient(colors: [camo.light, camo.main, camo.dark],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: s * 0.36, height: s * 0.29)
                .position(pt(0.5, 0.565))
            ForEach(0..<Self.spots.count, id: \.self) { i in
                spotView(Self.spots[i])
            }
            Rectangle()
                .fill(camo.dark.opacity(0.55))
                .frame(width: max(0.5, s * 0.005), height: s * 0.22)
                .position(pt(0.5, 0.575))
            OpVShape()
                .fill(skin.shade)
                .frame(width: s * 0.075, height: s * 0.045)
                .position(pt(0.5, 0.44))
            OpCollarShape()
                .fill(camo.dark)
                .frame(width: s * 0.15, height: s * 0.06)
                .position(pt(0.5, 0.448))
        }
    }

    private func spotView(_ sp: OpCamoSpot) -> some View {
        Ellipse()
            .fill(camo.spot.opacity(0.85))
            .frame(width: s * sp.w, height: s * sp.h)
            .rotationEffect(.degrees(sp.r))
            .position(pt(sp.x, sp.y))
    }

    // MARK: Bælte

    private var beltLayer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.006, style: .continuous)
                .fill(Theme.polymer)
                .frame(width: s * 0.34, height: s * 0.03)
                .position(pt(0.5, 0.71))
            Rectangle()
                .fill(camo.dark)
                .frame(width: s * 0.012, height: s * 0.036)
                .position(pt(0.40, 0.71))
            Rectangle()
                .fill(camo.dark)
                .frame(width: s * 0.012, height: s * 0.036)
                .position(pt(0.60, 0.71))
            RoundedRectangle(cornerRadius: s * 0.005, style: .continuous)
                .fill(Theme.metal)
                .frame(width: s * 0.05, height: s * 0.026)
                .overlay(
                    RoundedRectangle(cornerRadius: s * 0.005, style: .continuous)
                        .stroke(Theme.metalLight, lineWidth: max(0.5, s * 0.004))
                )
                .position(pt(0.5, 0.71))
            Rectangle()
                .fill(Theme.metalLight)
                .frame(width: s * 0.022, height: max(0.5, s * 0.004))
                .position(pt(0.5, 0.71))
        }
    }

    // MARK: Hænder

    private var handsLayer: some View {
        ZStack {
            hand(at: leftHand)
            hand(at: rightHand)
        }
    }

    private func hand(at p: CGPoint) -> some View {
        let d: CGFloat = s * 0.07
        let cuffY: CGFloat = p.y - 0.036
        return ZStack {
            Capsule()
                .fill(camo.dark)
                .frame(width: s * 0.084, height: s * 0.02)
                .position(pt(p.x, cuffY))
            Circle()
                .fill(Theme.polymer)
                .frame(width: d, height: d)
                .position(pt(p.x, p.y))
            Circle()
                .fill(Theme.metal.opacity(0.8))
                .frame(width: s * 0.022, height: s * 0.022)
                .position(pt(p.x - 0.009, p.y - 0.01))
        }
    }

    // MARK: Hals og hoved

    private var neckLayer: some View {
        Rectangle()
            .fill(skin.shade)
            .frame(width: s * 0.09, height: s * 0.055)
            .position(pt(0.5, 0.405))
    }

    private var headLayer: some View {
        ZStack {
            ear(x: 0.372)
            ear(x: 0.628)
            Ellipse()
                .fill(LinearGradient(colors: [skin.main, skin.main, skin.shade],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: s * 0.25, height: s * 0.27)
                .position(pt(0.5, 0.265))
            OpHairShape()
                .fill(Self.hairColor)
                .frame(width: s * 0.262, height: s * 0.112)
                .position(pt(0.5, 0.178))
            RoundedRectangle(cornerRadius: s * 0.005, style: .continuous)
                .fill(Self.hairColor)
                .frame(width: s * 0.013, height: s * 0.03)
                .position(pt(0.385, 0.243))
            RoundedRectangle(cornerRadius: s * 0.005, style: .continuous)
                .fill(Self.hairColor)
                .frame(width: s * 0.013, height: s * 0.03)
                .position(pt(0.615, 0.243))
            cheeks
        }
    }

    private func ear(x: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(skin.main)
                .frame(width: s * 0.035, height: s * 0.05)
            Ellipse()
                .fill(skin.shade)
                .frame(width: s * 0.016, height: s * 0.028)
        }
        .position(pt(x, 0.28))
    }

    @ViewBuilder private var cheeks: some View {
        if state == .ready || state == .leave || state == .steady {
            ZStack {
                Ellipse()
                    .fill(Self.cheekColor.opacity(0.28))
                    .frame(width: s * 0.034, height: s * 0.018)
                    .position(pt(0.425, 0.312))
                Ellipse()
                    .fill(Self.cheekColor.opacity(0.28))
                    .frame(width: s * 0.034, height: s * 0.018)
                    .position(pt(0.575, 0.312))
            }
        }
    }

    // MARK: Ansigt

    private var faceLayer: some View {
        ZStack {
            browsView
            eyesView
            noseView
            mouthView
        }
    }

    private var browTilt: Double {
        switch state {
        case .exhausted: return 14
        case .suspended: return 9
        case .tired: return 4
        default: return 0
        }
    }

    private var browY: CGFloat {
        switch state {
        case .exhausted: return 0.250
        case .leave, .resting: return 0.257
        default: return 0.255
        }
    }

    private var browsView: some View {
        let w: CGFloat = s * 0.042
        let h: CGFloat = s * 0.009
        let tilt: Double = browTilt
        let y: CGFloat = browY
        return ZStack {
            Capsule()
                .fill(Self.hairColor)
                .frame(width: w, height: h)
                .rotationEffect(.degrees(-tilt))
                .position(pt(0.455, y))
            Capsule()
                .fill(Self.hairColor)
                .frame(width: w, height: h)
                .rotationEffect(.degrees(tilt))
                .position(pt(0.545, y))
        }
    }

    @ViewBuilder private var eyesView: some View {
        switch state {
        case .ready, .steady:
            ZStack {
                openEye(x: 0.455)
                openEye(x: 0.545)
            }
        case .tired:
            ZStack {
                underEye(x: 0.455)
                underEye(x: 0.545)
                lidEye(x: 0.455, y: 0.282, cover: 0.5, tilt: 0)
                lidEye(x: 0.545, y: 0.282, cover: 0.5, tilt: 0)
            }
        case .exhausted:
            ZStack {
                underEye(x: 0.455)
                underEye(x: 0.545)
                lidEye(x: 0.455, y: 0.284, cover: 0.55, tilt: -10)
                lidEye(x: 0.545, y: 0.284, cover: 0.55, tilt: 10)
            }
        case .suspended:
            ZStack {
                lidEye(x: 0.455, y: 0.288, cover: 0.42, tilt: 0)
                lidEye(x: 0.545, y: 0.288, cover: 0.42, tilt: 0)
            }
        case .leave:
            ZStack {
                arcEye(x: 0.455, up: true)
                arcEye(x: 0.545, up: true)
            }
        case .resting:
            ZStack {
                arcEye(x: 0.455, up: false)
                arcEye(x: 0.545, up: false)
            }
        }
    }

    private func openEye(x: CGFloat) -> some View {
        let w: CGFloat = s * 0.028
        let h: CGFloat = s * 0.034 * blink
        let hl: CGFloat = s * 0.009
        let showHighlight: Bool = blink > 0.5
        return ZStack {
            Ellipse()
                .fill(Theme.eye)
                .frame(width: w, height: h)
            if showHighlight {
                Circle()
                    .fill(Color.white)
                    .frame(width: hl, height: hl)
                    .offset(x: s * 0.005, y: -s * 0.006)
            }
        }
        .position(pt(x, 0.28))
    }

    /// Øje med øjenlåg, der dækker den øverste del (`cover` = andel).
    private func lidEye(x: CGFloat, y: CGFloat, cover: CGFloat, tilt: Double) -> some View {
        let w: CGFloat = s * 0.03
        let h: CGFloat = s * 0.032
        let lidH: CGFloat = h * cover
        let lineH: CGFloat = max(0.6, s * 0.0045)
        return ZStack(alignment: .top) {
            Ellipse()
                .fill(Theme.eye)
                .frame(width: w, height: h)
            Rectangle()
                .fill(skin.main)
                .frame(width: w, height: lidH)
        }
        .frame(width: w, height: h)
        .clipShape(Ellipse())
        .overlay(alignment: .top) {
            Capsule()
                .fill(Theme.eye)
                .frame(width: w * 1.12, height: lineH)
                .offset(y: lidH - lineH * 0.5)
        }
        .rotationEffect(.degrees(tilt))
        .position(pt(x, y))
    }

    private func underEye(x: CGFloat) -> some View {
        Ellipse()
            .fill(skin.shade.opacity(0.85))
            .frame(width: s * 0.034, height: s * 0.012)
            .position(pt(x, 0.301))
    }

    private func arcEye(x: CGFloat, up: Bool) -> some View {
        let lw: CGFloat = max(0.8, s * 0.006)
        let style = StrokeStyle(lineWidth: lw, lineCap: .round)
        return Group {
            if up {
                OpHumpShape()
                    .stroke(Theme.eye, style: style)
                    .frame(width: s * 0.034, height: s * 0.011)
            } else {
                OpCupShape()
                    .stroke(Theme.eye, style: style)
                    .frame(width: s * 0.032, height: s * 0.009)
            }
        }
        .position(pt(x, 0.283))
    }

    private var noseView: some View {
        ZStack {
            Ellipse()
                .fill(skin.shade)
                .frame(width: s * 0.024, height: s * 0.015)
            Ellipse()
                .fill(Color.white.opacity(0.18))
                .frame(width: s * 0.008, height: s * 0.005)
                .offset(x: -s * 0.004, y: -s * 0.003)
        }
        .position(pt(0.5, 0.315))
    }

    @ViewBuilder private var mouthView: some View {
        switch state {
        case .ready:
            smile(w: 0.05, h: 0.013)
        case .steady:
            smile(w: 0.04, h: 0.008)
        case .leave:
            smile(w: 0.056, h: 0.016)
        case .resting:
            smile(w: 0.028, h: 0.005)
        case .tired:
            Capsule()
                .fill(Self.mouthColor)
                .frame(width: s * 0.034, height: max(0.8, s * 0.006))
                .position(pt(0.5, 0.348))
        case .exhausted:
            frown(w: 0.032, h: 0.008)
        case .suspended:
            frown(w: 0.04, h: 0.01)
        }
    }

    private func smile(w: CGFloat, h: CGFloat) -> some View {
        let lw: CGFloat = max(0.8, s * 0.0065)
        return OpCupShape()
            .stroke(Self.mouthColor, style: StrokeStyle(lineWidth: lw, lineCap: .round))
            .frame(width: s * w, height: s * h)
            .position(pt(0.5, 0.344))
    }

    private func frown(w: CGFloat, h: CGFloat) -> some View {
        let lw: CGFloat = max(0.8, s * 0.0065)
        return OpHumpShape()
            .stroke(Self.mouthColor, style: StrokeStyle(lineWidth: lw, lineCap: .round))
            .frame(width: s * w, height: s * h)
            .position(pt(0.5, 0.350))
    }

    // MARK: Tilstands-lag

    @ViewBuilder private var suspendedTint: some View {
        if state == .suspended {
            ZStack {
                Ellipse()
                    .fill(Color.gray.opacity(0.16))
                    .frame(width: s * 0.25, height: s * 0.27)
                    .position(pt(0.5, 0.265))
                RoundedRectangle(cornerRadius: s * 0.06, style: .continuous)
                    .fill(Color.gray.opacity(0.14))
                    .frame(width: s * 0.36, height: s * 0.29)
                    .position(pt(0.5, 0.565))
            }
        }
    }

    @ViewBuilder private var sweatLayer: some View {
        if state == .exhausted {
            sweatDrop
        }
    }

    private var sweatDrop: some View {
        let raw: Double = animated ? (t * 0.22).truncatingRemainder(dividingBy: 1) : 0.3
        let phase: CGFloat = CGFloat(raw)
        let y: CGFloat = 0.215 + 0.06 * phase
        let fade: Double = 1 - raw * 0.8
        return OpDropShape()
            .fill(LinearGradient(colors: [Color.white.opacity(0.9), Color(hex: 0x8CCBEB)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: s * 0.022, height: s * 0.032)
            .opacity(fade)
            .position(pt(0.607, y))
    }
}

// MARK: - Ekstra lag (Zzz, stempel, orlov)

struct OperatorExtras: View {
    let camo: Camo
    let skin: SkinTone
    let state: ReadinessState
    let s: CGFloat
    let t: Double
    let animated: Bool
    /// Kropsmodellens mål – tilbehør flyttes fra referencefiguren til denne model.
    var geometry: BodyGeometry = .reference

    /// Flyt et lag tegnet til referencefiguren hen til samme sted på den valgte model.
    private func mapped<V: View>(_ v: V, from a: CGPoint, to b: CGPoint, kx: CGFloat, ky: CGFloat) -> some View {
        let dx: CGFloat = (b.x - a.x) * s
        let dy: CGFloat = (b.y - a.y) * s
        return v
            .frame(width: s, height: s)
            .scaleEffect(x: kx, y: ky, anchor: UnitPoint(x: a.x, y: a.y))
            .offset(x: dx, y: dy)
    }

    private var headK: (CGFloat, CGFloat) {
        let r = BodyGeometry.reference
        return (geometry.headSize.width / r.headSize.width, geometry.headSize.height / r.headSize.height)
    }

    private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        OperatorGeometry.point(x, y, s: s)
    }

    var body: some View {
        content
            .frame(width: s, height: s)
    }

    @ViewBuilder private var content: some View {
        switch state {
        case .resting:
            mapped(zzz, from: BodyGeometry.reference.headCenter, to: geometry.headCenter, kx: headK.0, ky: headK.1)
        case .suspended:
            stamp
        case .leave:
            let r = BodyGeometry.reference
            let k: CGFloat = geometry.torso.width / r.torso.width
            ZStack {
                mapped(sunglasses, from: r.headCenter, to: geometry.headCenter, kx: headK.0, ky: headK.1)
                mapped(coffee, from: r.rightHand, to: geometry.rightHand, kx: k, ky: k)
            }
        default:
            EmptyView()
        }
    }

    // MARK: Zzz

    private var zzz: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                zLetter(i)
            }
        }
        .frame(width: s, height: s)
    }

    private func zLetter(_ i: Int) -> some View {
        let base: Double = Double(i) / 3.0
        let phase: Double = animated ? (t * 0.25 + base).truncatingRemainder(dividingBy: 1) : base
        let p: CGFloat = CGFloat(phase)
        let size: CGFloat = s * (0.055 + 0.035 * p)
        let x: CGFloat = 0.66 + 0.14 * p
        let y: CGFloat = 0.19 - 0.15 * p
        return Text("z")
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .foregroundStyle(Theme.violet)
            .opacity(1 - phase)
            .position(pt(x, y))
    }

    // MARK: Suspenderet-stempel

    private var stamp: some View {
        let fs: CGFloat = s * 0.045
        let corner: CGFloat = s * 0.014
        let border: CGFloat = max(1, s * 0.006)
        return Text("SUSPENDERET")
            .font(.system(size: fs, weight: .heavy, design: .monospaced))
            .foregroundStyle(Theme.alert)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, s * 0.016)
            .padding(.vertical, s * 0.008)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Theme.alert.opacity(0.14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Theme.alert, lineWidth: border)
            )
            .rotationEffect(.degrees(-12))
            .position(pt(0.78, 0.12))
    }

    // MARK: Orlov

    private var sunglasses: some View {
        ZStack {
            Capsule()
                .fill(Theme.polymer)
                .frame(width: s * 0.25, height: max(0.8, s * 0.008))
                .position(pt(0.5, 0.272))
            lens(x: 0.452)
            lens(x: 0.548)
        }
    }

    private func lens(x: CGFloat) -> some View {
        let w: CGFloat = s * 0.072
        let h: CGFloat = s * 0.048
        let corner: CGFloat = s * 0.016
        return ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0x2E3A44), Color(hex: 0x0E1216)],
                                     startPoint: .top, endPoint: .bottom))
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(Theme.polymer, lineWidth: max(0.8, s * 0.005))
            Capsule()
                .fill(Color.white.opacity(0.22))
                .frame(width: w * 0.35, height: h * 0.12)
                .rotationEffect(.degrees(-20))
                .offset(x: -w * 0.15, y: -h * 0.22)
        }
        .frame(width: w, height: h)
        .position(pt(x, 0.282))
    }

    private var coffee: some View {
        let steamRaw: Double = animated ? (t * 1.6).truncatingRemainder(dividingBy: Double.pi * 2) : 0
        let steamPhase: CGFloat = CGFloat(steamRaw)
        let steamFade: Double = animated ? 0.45 + 0.2 * sin(t * 0.9) : 0.55
        let lw: CGFloat = max(0.8, s * 0.006)
        return ZStack {
            OpSteamShape(phase: steamPhase)
                .stroke(Color.white.opacity(steamFade), style: StrokeStyle(lineWidth: lw, lineCap: .round))
                .frame(width: s * 0.03, height: s * 0.06)
                .position(pt(0.735, 0.555))
            OpCoffeeCupShape()
                .fill(Color(hex: 0xF2EEE6))
                .frame(width: s * 0.055, height: s * 0.08)
                .position(pt(0.73, 0.645))
            RoundedRectangle(cornerRadius: s * 0.003, style: .continuous)
                .fill(Theme.coyote)
                .frame(width: s * 0.049, height: s * 0.022)
                .position(pt(0.73, 0.648))
            RoundedRectangle(cornerRadius: s * 0.006, style: .continuous)
                .fill(Color(hex: 0x3A3F45))
                .frame(width: s * 0.062, height: s * 0.014)
                .position(pt(0.73, 0.603))
            Capsule()
                .fill(Color(hex: 0x3A3F45))
                .frame(width: s * 0.03, height: s * 0.008)
                .position(pt(0.73, 0.594))
            Circle()
                .fill(Theme.polymer)
                .frame(width: s * 0.032, height: s * 0.032)
                .position(pt(0.706, 0.672))
        }
    }
}
