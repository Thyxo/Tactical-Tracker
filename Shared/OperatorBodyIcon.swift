import SwiftUI

// "Ikon" – minimalistisk piktogram-krop. Flade flader, ingen konturer, få detaljer.
// Alle mål er andele af s; (0,0) øverst til venstre. Kun selve kroppen – udstyr lægges ovenpå.

// MARK: - Former

/// Smal torso: trapez (bredest ved skuldrene) med bløde hjørner.
struct IcnTorsoShape: Shape {
    /// Hvor meget bunden er trukket ind i hver side (andel af bredden).
    var bottomInset: CGFloat = 0.10

    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        let inset: CGFloat = w * bottomInset
        let rad: CGFloat = w * 0.22
        let lowRad: CGFloat = w * 0.08
        let blX: CGFloat = r.minX + inset
        let brX: CGFloat = r.maxX - inset
        p.move(to: CGPoint(x: r.minX + rad, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - rad, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + rad),
                       control: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: brX, y: r.maxY - lowRad))
        p.addQuadCurve(to: CGPoint(x: brX - lowRad, y: r.maxY),
                       control: CGPoint(x: brX, y: r.maxY))
        p.addLine(to: CGPoint(x: blX + lowRad, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: blX, y: r.maxY - lowRad),
                       control: CGPoint(x: blX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + rad))
        p.addQuadCurve(to: CGPoint(x: r.minX + rad, y: r.minY),
                       control: CGPoint(x: r.minX, y: r.minY))
        p.closeSubpath()
        return p
    }
}

/// Kort hår-kalot: øverste del af hovedcirklen med let buet pandekant.
struct IcnHairShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let rad: CGFloat = min(r.width, r.height) / 2
        let c = CGPoint(x: r.midX, y: r.midY)
        let startDeg: Double = 196
        let deltaDeg: Double = 148
        p.addRelativeArc(center: c, radius: rad,
                         startAngle: .degrees(startDeg), delta: .degrees(deltaDeg))
        let a0: Double = startDeg * Double.pi / 180
        let x0: CGFloat = c.x + rad * CGFloat(cos(a0))
        let y0: CGFloat = c.y + rad * CGFloat(sin(a0))
        let ctrlY: CGFloat = c.y - rad * 0.12
        p.addQuadCurve(to: CGPoint(x: x0, y: y0), control: CGPoint(x: c.x, y: ctrlY))
        p.closeSubpath()
        return p
    }
}

/// ∪ – smil / lukkede, hvilende øjne.
struct IcnCupShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY),
                       control: CGPoint(x: r.midX, y: r.minY + h * 2))
        return p
    }
}

/// ∩ – nedadvendt mund / glade øjne.
struct IcnArcShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY),
                       control: CGPoint(x: r.midX, y: r.maxY - h * 2))
        return p
    }
}

// MARK: - Figur

struct OperatorBodyIcon: View {
    static let geometry = BodyGeometry(
        headCenter: CGPoint(x: 0.50, y: 0.22), headSize: CGSize(width: 0.20, height: 0.20),
        eyeY: 0.225, eyeDX: 0.038,
        torso: CGRect(x: 0.38, y: 0.345, width: 0.24, height: 0.255),
        rightHand: CGPoint(x: 0.635, y: 0.60), rightHip: CGPoint(x: 0.59, y: 0.61))

    let camo: Camo
    let skin: SkinTone
    let state: ReadinessState
    let s: CGFloat
    let t: Double
    let animated: Bool

    private static let hairColor = Color(hex: 0x2B2420)
    private static let faceInk = Color(hex: 0x3A2622)

    private var g: BodyGeometry { OperatorBodyIcon.geometry }

    private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: s * x, y: s * y)
    }

    var body: some View {
        ZStack {
            legsLayer
            armsLayer
            hipsLayer
            torsoLayer
            handsLayer
            neckLayer
            headLayer
            faceLayer
        }
        .frame(width: s, height: s)
        .saturation(state == .suspended ? 0.6 : 1)
    }

    // MARK: Bevægelse

    private var blink: CGFloat {
        guard animated, state == .ready else { return 1 }
        let p: Double = t.truncatingRemainder(dividingBy: Tuning.Motion.blinkEvery)
        return p < 0.14 ? 0.15 : 1
    }

    // MARK: Ben og støvler

    private var legW: CGFloat { 0.074 }
    private var legTop: CGFloat { 0.62 }
    private var legBottom: CGFloat { 0.91 }

    private var legsLayer: some View {
        ZStack {
            leg(cx: 0.457)
            leg(cx: 0.543)
            boot(cx: 0.452)
            boot(cx: 0.548)
        }
    }

    private func leg(cx: CGFloat) -> some View {
        let h: CGFloat = legBottom - legTop
        let cy: CGFloat = (legTop + legBottom) / 2
        return Capsule()
            .fill(camo.dark)
            .frame(width: s * legW, height: s * h)
            .position(pt(cx, cy))
    }

    private func boot(cx: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: s * 0.022, style: .continuous)
            .fill(Theme.polymer)
            .frame(width: s * 0.095, height: s * 0.05)
            .position(pt(cx, 0.925))
    }

    private var hipsLayer: some View {
        RoundedRectangle(cornerRadius: s * 0.025, style: .continuous)
            .fill(camo.dark)
            .frame(width: s * 0.19, height: s * 0.08)
            .position(pt(0.50, 0.625))
    }

    // MARK: Arme og hænder

    private var shoulderY: CGFloat { 0.37 }
    private var shoulderDX: CGFloat { 0.105 }
    private var armW: CGFloat { 0.056 }

    /// Hånd på billedets højre side.
    private var handRight: CGPoint {
        if state == .exhausted {
            return CGPoint(x: 0.615, y: 0.615)
        }
        return g.rightHand
    }

    private var handLeft: CGPoint {
        let h: CGPoint = handRight
        let x: CGFloat = 1 - h.x
        return CGPoint(x: x, y: h.y)
    }

    private var armsLayer: some View {
        let lx: CGFloat = 0.50 - shoulderDX
        let rx: CGFloat = 0.50 + shoulderDX
        return ZStack {
            arm(from: CGPoint(x: lx, y: shoulderY), to: handLeft)
                .brightness(-0.04)
            arm(from: CGPoint(x: rx, y: shoulderY), to: handRight)
        }
    }

    private func arm(from a: CGPoint, to b: CGPoint) -> some View {
        let dx: CGFloat = b.x - a.x
        let dy: CGFloat = b.y - a.y
        let len: CGFloat = sqrt(dx * dx + dy * dy)
        let mx: CGFloat = (a.x + b.x) / 2
        let my: CGFloat = (a.y + b.y) / 2
        let angle: Double = -atan2(Double(dx), Double(dy))
        let h: CGFloat = len + armW
        return Capsule()
            .fill(camo.main)
            .frame(width: s * armW, height: s * h)
            .rotationEffect(.radians(angle))
            .position(pt(mx, my))
    }

    private var handsLayer: some View {
        let d: CGFloat = s * 0.052
        return ZStack {
            Circle()
                .fill(Theme.polymer)
                .frame(width: d, height: d)
                .position(pt(handLeft.x, handLeft.y))
            Circle()
                .fill(Theme.polymer)
                .frame(width: d, height: d)
                .position(pt(handRight.x, handRight.y))
        }
    }

    // MARK: Torso, hals, hoved

    private var torsoLayer: some View {
        let r: CGRect = g.torso
        return IcnTorsoShape(bottomInset: 0.10)
            .fill(camo.main)
            .frame(width: s * r.width, height: s * r.height)
            .position(pt(r.midX, r.midY))
    }

    private var neckLayer: some View {
        Capsule()
            .fill(skin.shade)
            .frame(width: s * 0.05, height: s * 0.07)
            .position(pt(0.50, 0.325))
    }

    private var headLayer: some View {
        let w: CGFloat = s * g.headSize.width
        let h: CGFloat = s * g.headSize.height
        let c: CGPoint = g.headCenter
        return ZStack {
            Circle()
                .fill(skin.main)
                .frame(width: w, height: h)
            IcnHairShape()
                .fill(OperatorBodyIcon.hairColor)
                .frame(width: w, height: h)
        }
        .position(pt(c.x, c.y))
    }

    // MARK: Ansigt

    private var mouthY: CGFloat { 0.268 }
    private var line: CGFloat { s * 0.008 }

    private var faceLayer: some View {
        ZStack {
            eye(x: 0.50 - g.eyeDX)
            eye(x: 0.50 + g.eyeDX)
            mouth
        }
    }

    @ViewBuilder
    private func eye(x: CGFloat) -> some View {
        let ink: Color = OperatorBodyIcon.faceInk
        let y: CGFloat = g.eyeY
        switch state {
        case .ready, .steady:
            Circle()
                .fill(ink)
                .frame(width: s * 0.022, height: s * 0.022)
                .scaleEffect(x: 1, y: blink)
                .position(pt(x, y))
        case .tired:
            Capsule()
                .fill(ink)
                .frame(width: s * 0.026, height: s * 0.007)
                .position(pt(x, y + 0.003))
        case .exhausted:
            Circle()
                .fill(ink)
                .frame(width: s * 0.015, height: s * 0.015)
                .position(pt(x, y))
        case .suspended:
            Circle()
                .fill(ink)
                .frame(width: s * 0.019, height: s * 0.019)
                .position(pt(x, y + 0.007))
        case .leave:
            IcnArcShape()
                .stroke(ink, style: StrokeStyle(lineWidth: line, lineCap: .round))
                .frame(width: s * 0.026, height: s * 0.008)
                .position(pt(x, y))
        case .resting:
            IcnCupShape()
                .stroke(ink, style: StrokeStyle(lineWidth: line, lineCap: .round))
                .frame(width: s * 0.026, height: s * 0.008)
                .position(pt(x, y))
        }
    }

    @ViewBuilder
    private var mouth: some View {
        let ink: Color = OperatorBodyIcon.faceInk
        switch state {
        case .ready, .leave:
            IcnCupShape()
                .stroke(ink, style: StrokeStyle(lineWidth: line, lineCap: .round))
                .frame(width: s * 0.040, height: s * 0.009)
                .position(pt(0.50, mouthY))
        case .exhausted:
            IcnArcShape()
                .stroke(ink, style: StrokeStyle(lineWidth: line, lineCap: .round))
                .frame(width: s * 0.034, height: s * 0.007)
                .position(pt(0.50, mouthY + 0.004))
        case .steady, .tired, .suspended, .resting:
            Capsule()
                .fill(ink)
                .frame(width: s * 0.030, height: line)
                .position(pt(0.50, mouthY + 0.003))
        }
    }
}
