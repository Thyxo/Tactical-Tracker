import SwiftUI

// "Blød" kropsmodel – samme rolige formsprog som sælen i Sælliv:
// få, bløde former, gradient på trøjen, rosa kinder og prik-øjne med lille lys.
// Stort rundt hoved, slank krop, tynde kapsel-arme og -ben, små runde støvler.
// Ingen konturer, lommer, syninger eller camo-pletter.

// MARK: - Små former

/// ∪ – lukkede, sovende øjne / lille smil.
struct SoftCupShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY),
                       control: CGPoint(x: r.midX, y: r.minY + h * 2))
        return p
    }
}

/// ∩ – glade lukkede øjne / lille surmule-mund.
struct SoftHumpShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY),
                       control: CGPoint(x: r.midX, y: r.maxY - h * 2))
        return p
    }
}

/// ω – lille kattesmil.
struct SoftMouthWShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        let lowY: CGFloat = r.minY + h * 2
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY),
                       control: CGPoint(x: r.minX + w * 0.25, y: lowY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY),
                       control: CGPoint(x: r.minX + w * 0.75, y: lowY))
        return p
    }
}

/// Nederste halvdel af en ellipse – halvlukket øje.
struct SoftHalfDotShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY),
                       control: CGPoint(x: r.midX, y: r.minY + h * 2))
        p.closeSubpath()
        return p
    }
}

/// Kort hår som én blød kalot med en let bølget pandekant.
struct SoftHairShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY),
                   control1: CGPoint(x: r.minX, y: r.minY + h * 0.25),
                   control2: CGPoint(x: r.minX + w * 0.20, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.maxY),
                   control1: CGPoint(x: r.maxX - w * 0.20, y: r.minY),
                   control2: CGPoint(x: r.maxX, y: r.minY + h * 0.25))
        p.addQuadCurve(to: CGPoint(x: r.midX + w * 0.06, y: r.maxY - h * 0.30),
                       control: CGPoint(x: r.maxX - w * 0.18, y: r.maxY - h * 0.40))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY),
                       control: CGPoint(x: r.minX + w * 0.22, y: r.maxY - h * 0.55))
        p.closeSubpath()
        return p
    }
}

/// Dråbe med spidsen opad.
struct SoftDropShape: Shape {
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

/// Lige linje mellem to punkter (enheds-koordinater 0–1 i hele rammen) – streges som kapsel-lem.
struct SoftCapsuleLimb: Shape {
    let a: CGPoint
    let b: CGPoint

    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX + a.x * w, y: r.minY + a.y * h))
        p.addLine(to: CGPoint(x: r.minX + b.x * w, y: r.minY + b.y * h))
        return p
    }
}

// MARK: - Figuren

struct OperatorBodySoft: View {
    static let geometry = BodyGeometry(
        headCenter: CGPoint(x: 0.50, y: 0.27), headSize: CGSize(width: 0.23, height: 0.22),
        eyeY: 0.29, eyeDX: 0.045,
        torso: CGRect(x: 0.375, y: 0.40, width: 0.25, height: 0.24),
        rightHand: CGPoint(x: 0.665, y: 0.625), rightHip: CGPoint(x: 0.615, y: 0.645))

    let camo: Camo
    let skin: SkinTone
    let state: ReadinessState
    let s: CGFloat
    let t: Double
    let animated: Bool

    private typealias M = Tuning.Motion
    private typealias G = SoftLayout

    private static let hairColor = Color(hex: 0x3A2E28)
    private static let mouthColor = Color(hex: 0x4A2A24)
    private static let cheekColor = Color(hex: 0xF0A08C)
    private static let sweatColor = Color(hex: 0x9FD3F0)

    private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: s * x, y: s * y)
    }

    var body: some View {
        ZStack {
            legsLayer
            armsLayer
            torsoLayer
            handsLayer
            neckLayer
            headLayer
            faceLayer
            sweatLayer
        }
        .frame(width: s, height: s)
        .saturation(state == .suspended ? 0.75 : 1)
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
            UnevenRoundedRectangle(topLeadingRadius: s * 0.02,
                                   bottomLeadingRadius: s * 0.035,
                                   bottomTrailingRadius: s * 0.035,
                                   topTrailingRadius: s * 0.02,
                                   style: .continuous)
                .fill(camo.dark)
                .frame(width: s * 0.23, height: s * 0.09)
                .position(pt(0.5, 0.665))
            leg(cx: G.legLeftX)
            leg(cx: G.legRightX)
            boot(cx: G.bootLeftX)
            boot(cx: G.bootRightX)
        }
    }

    private func leg(cx: CGFloat) -> some View {
        let w: CGFloat = s * G.legWidth
        let h: CGFloat = s * 0.27
        return Capsule()
            .fill(camo.dark)
            .frame(width: w, height: h)
            .position(pt(cx, 0.785))
    }

    private func boot(cx: CGFloat) -> some View {
        let w: CGFloat = s * 0.09
        let h: CGFloat = s * 0.045
        return Capsule()
            .fill(Theme.polymer)
            .frame(width: w, height: h)
            .position(pt(cx, G.bootY))
    }

    // MARK: Arme

    private var shoulderY: CGFloat { state == .suspended ? 0.45 : 0.44 }
    private var handInset: CGFloat { state == .suspended ? 0.02 : 0 }
    private var handY: CGFloat { state == .suspended ? 0.63 : 0.625 }

    private var leftHand: CGPoint {
        let x: CGFloat = 0.335 + handInset
        return CGPoint(x: x, y: handY)
    }

    private var rightHand: CGPoint {
        let x: CGFloat = 0.665 - handInset
        return CGPoint(x: x, y: handY)
    }

    private var armsLayer: some View {
        let leftShoulder = CGPoint(x: 0.40, y: shoulderY)
        let rightShoulder = CGPoint(x: 0.60, y: shoulderY)
        return ZStack {
            arm(from: leftShoulder, to: leftHand)
            arm(from: rightShoulder, to: rightHand)
        }
    }

    private func arm(from a: CGPoint, to b: CGPoint) -> some View {
        let width: CGFloat = s * G.armWidth
        return SoftCapsuleLimb(a: a, b: b)
            .stroke(camo.main, style: StrokeStyle(lineWidth: width, lineCap: .round))
            .frame(width: s, height: s)
            .position(pt(0.5, 0.5))
    }

    private var handsLayer: some View {
        let d: CGFloat = s * 0.055
        return ZStack {
            Circle().fill(Theme.polymer)
                .frame(width: d, height: d)
                .position(pt(leftHand.x, leftHand.y))
            Circle().fill(Theme.polymer)
                .frame(width: d, height: d)
                .position(pt(rightHand.x, rightHand.y))
        }
    }

    // MARK: Torso

    private var torsoLayer: some View {
        let rect: CGRect = Self.geometry.torso
        let w: CGFloat = s * rect.width
        let h: CGFloat = s * rect.height
        let top: CGFloat = s * 0.08
        let bottom: CGFloat = s * 0.03
        return UnevenRoundedRectangle(topLeadingRadius: top,
                                      bottomLeadingRadius: bottom,
                                      bottomTrailingRadius: bottom,
                                      topTrailingRadius: top,
                                      style: .continuous)
            .fill(LinearGradient(colors: [camo.light, camo.main],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: w, height: h)
            .position(pt(rect.midX, rect.midY))
    }

    // MARK: Hals og hoved

    private var neckLayer: some View {
        Capsule()
            .fill(skin.shade)
            .frame(width: s * 0.055, height: s * 0.06)
            .position(pt(0.5, 0.385))
    }

    private var headLayer: some View {
        let hc: CGPoint = Self.geometry.headCenter
        let hs: CGSize = Self.geometry.headSize
        let earD: CGFloat = s * 0.04
        let earDX: CGFloat = hs.width * 0.5
        let earY: CGFloat = hc.y + 0.018
        return ZStack {
            Circle().fill(skin.shade)
                .frame(width: earD, height: earD)
                .position(pt(hc.x - earDX, earY))
            Circle().fill(skin.shade)
                .frame(width: earD, height: earD)
                .position(pt(hc.x + earDX, earY))
            Ellipse()
                .fill(LinearGradient(colors: [skin.main, skin.main, skin.shade.opacity(0.9)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: s * hs.width, height: s * hs.height)
                .position(pt(hc.x, hc.y))
            SoftHairShape()
                .fill(Self.hairColor)
                .frame(width: s * 0.24, height: s * 0.11)
                .position(pt(0.5, 0.205))
        }
    }

    // MARK: Ansigt

    private var eyeLeftX: CGFloat { 0.5 - Self.geometry.eyeDX }
    private var eyeRightX: CGFloat { 0.5 + Self.geometry.eyeDX }

    private var cheekOpacity: Double {
        switch state {
        case .ready, .leave: return 0.55
        case .suspended, .exhausted: return 0.25
        default: return 0.42
        }
    }

    private var faceLayer: some View {
        let cheekW: CGFloat = s * 0.042
        let cheekH: CGFloat = s * 0.022
        return ZStack {
            Ellipse().fill(Self.cheekColor.opacity(cheekOpacity))
                .frame(width: cheekW, height: cheekH)
                .position(pt(0.425, 0.318))
            Ellipse().fill(Self.cheekColor.opacity(cheekOpacity))
                .frame(width: cheekW, height: cheekH)
                .position(pt(0.575, 0.318))
            eye(x: eyeLeftX)
            eye(x: eyeRightX)
            browsLayer
            mouth
        }
    }

    private var eyeLineWidth: CGFloat { s * 0.009 }

    private func eye(x: CGFloat) -> some View {
        let y: CGFloat = Self.geometry.eyeY
        return eyeShape.position(pt(x, y))
    }

    @ViewBuilder private var eyeShape: some View {
        switch state {
        case .leave:
            SoftHumpShape()
                .stroke(Theme.eye, style: StrokeStyle(lineWidth: eyeLineWidth, lineCap: .round))
                .frame(width: s * 0.034, height: s * 0.012)
        case .resting:
            SoftCupShape()
                .stroke(Theme.eye, style: StrokeStyle(lineWidth: eyeLineWidth, lineCap: .round))
                .frame(width: s * 0.034, height: s * 0.011)
        case .tired:
            tiredEye
        case .suspended:
            dotEye(size: 0.026, highlightDY: 0.004)
                .offset(y: s * 0.004)
        case .exhausted:
            dotEye(size: 0.026, highlightDY: -0.004)
        case .ready:
            dotEye(size: 0.032, highlightDY: -0.005)
        case .steady:
            dotEye(size: 0.03, highlightDY: -0.005)
        }
    }

    private func dotEye(size: CGFloat, highlightDY: CGFloat) -> some View {
        let d: CGFloat = s * size
        let hd: CGFloat = d * 0.36
        let hx: CGFloat = -d * 0.18
        let hy: CGFloat = s * highlightDY
        return ZStack {
            Circle().fill(Theme.eye)
                .frame(width: d, height: d)
            Circle().fill(Color.white.opacity(0.95))
                .frame(width: hd, height: hd)
                .offset(x: hx, y: hy)
        }
        .frame(width: d, height: d)
        .scaleEffect(x: 1, y: blink)
    }

    private var tiredEye: some View {
        let w: CGFloat = s * 0.03
        let h: CGFloat = s * 0.008
        let lidW: CGFloat = s * 0.036
        let lidH: CGFloat = s * 0.006
        return ZStack {
            SoftHalfDotShape()
                .fill(Theme.eye)
                .frame(width: w, height: h)
                .offset(y: s * 0.002)
            Capsule()
                .fill(Theme.eye.opacity(0.85))
                .frame(width: lidW, height: lidH)
        }
    }

    @ViewBuilder private var browsLayer: some View {
        if state == .exhausted {
            let w: CGFloat = s * 0.03
            let h: CGFloat = s * 0.007
            let y: CGFloat = Self.geometry.eyeY - 0.03
            Capsule().fill(Self.hairColor.opacity(0.75))
                .frame(width: w, height: h)
                .rotationEffect(.degrees(-16))
                .position(pt(eyeLeftX, y))
            Capsule().fill(Self.hairColor.opacity(0.75))
                .frame(width: w, height: h)
                .rotationEffect(.degrees(16))
                .position(pt(eyeRightX, y))
        }
    }

    private var mouthLineWidth: CGFloat { s * 0.0075 }

    @ViewBuilder private var mouth: some View {
        switch state {
        case .ready, .leave:
            SoftMouthWShape()
                .stroke(Self.mouthColor, style: StrokeStyle(lineWidth: mouthLineWidth, lineCap: .round))
                .frame(width: s * 0.036, height: s * 0.009)
                .position(pt(0.5, G.mouthY))
        case .steady:
            SoftCupShape()
                .stroke(Self.mouthColor, style: StrokeStyle(lineWidth: mouthLineWidth, lineCap: .round))
                .frame(width: s * 0.03, height: s * 0.007)
                .position(pt(0.5, G.mouthY))
        case .tired, .resting:
            SoftCupShape()
                .stroke(Self.mouthColor, style: StrokeStyle(lineWidth: mouthLineWidth, lineCap: .round))
                .frame(width: s * 0.018, height: s * 0.004)
                .position(pt(0.5, G.mouthY))
        case .exhausted, .suspended:
            SoftHumpShape()
                .stroke(Self.mouthColor, style: StrokeStyle(lineWidth: mouthLineWidth, lineCap: .round))
                .frame(width: s * 0.026, height: s * 0.006)
                .position(pt(0.5, 0.338))
        }
    }

    // MARK: Svedperle (kun Udmattet)

    @ViewBuilder private var sweatLayer: some View {
        if state == .exhausted {
            let w: CGFloat = s * 0.022
            let h: CGFloat = s * 0.032
            let drift: CGFloat = animated ? CGFloat(sin(t * 1.2)) * s * 0.003 : 0
            SoftDropShape()
                .fill(Self.sweatColor.opacity(0.85))
                .frame(width: w, height: h)
                .position(pt(0.595, 0.245))
                .offset(y: drift)
        }
    }
}

/// Faste mål for den bløde model (andele af s).
enum SoftLayout {
    static let legWidth: CGFloat = 0.08
    static let legLeftX: CGFloat = 0.455
    static let legRightX: CGFloat = 0.545
    static let bootLeftX: CGFloat = 0.448
    static let bootRightX: CGFloat = 0.552
    static let bootY: CGFloat = 0.9275
    static let armWidth: CGFloat = 0.06
    static let mouthY: CGFloat = 0.33
}
