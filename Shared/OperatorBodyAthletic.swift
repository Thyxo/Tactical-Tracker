import SwiftUI

// "Atlet" – slank, atletisk operatør med voksne proportioner.
// Rolige, flade former uden konturer; højst to toner pr. materiale.
// Alle mål er andele af s; (0,0) øverst til venstre. Fødder ender ved y ≈ 0.95.

// MARK: - Former

/// Torso: runde skuldre, rund halsudskæring og en let V-form ind mod taljen.
struct AthTorsoShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        let shoulderDrop: CGFloat = h * 0.16
        let shoulderRound: CGFloat = w * 0.13
        let waistInset: CGFloat = w * 0.13
        let neckHalf: CGFloat = w * 0.14
        p.move(to: CGPoint(x: r.midX - neckHalf, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.midX + neckHalf, y: r.minY),
                       control: CGPoint(x: r.midX, y: r.minY + h * 0.16))
        p.addLine(to: CGPoint(x: r.maxX - shoulderRound, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + shoulderDrop),
                       control: CGPoint(x: r.maxX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX - waistInset, y: r.maxY),
                       control: CGPoint(x: r.maxX - w * 0.02, y: r.minY + h * 0.55))
        p.addLine(to: CGPoint(x: r.minX + waistInset, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + shoulderDrop),
                       control: CGPoint(x: r.minX + w * 0.02, y: r.minY + h * 0.55))
        p.addQuadCurve(to: CGPoint(x: r.minX + shoulderRound, y: r.minY),
                       control: CGPoint(x: r.minX, y: r.minY))
        p.closeSubpath()
        return p
    }
}

/// Bukser: hofte foroven, to lange ben der smalner ind mod anklen.
struct AthPantsShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        let ankleOuter: CGFloat = w * 0.17
        let ankleInner: CGFloat = w * 0.445
        let crotchY: CGFloat = r.minY + h * 0.24
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX - ankleOuter, y: r.maxY),
                       control: CGPoint(x: r.maxX + w * 0.01, y: r.minY + h * 0.45))
        p.addLine(to: CGPoint(x: r.minX + w - ankleInner, y: r.maxY))
        p.addLine(to: CGPoint(x: r.midX, y: crotchY))
        p.addLine(to: CGPoint(x: r.minX + ankleInner, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + ankleOuter, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY),
                       control: CGPoint(x: r.minX - w * 0.01, y: r.minY + h * 0.45))
        p.closeSubpath()
        return p
    }
}

/// Kort hår: kalot over issen med en blød hårgrænse.
struct AthHairShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        let sideY: CGFloat = r.minY + h * 0.46
        p.move(to: CGPoint(x: r.minX + w * 0.02, y: sideY))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY),
                   control1: CGPoint(x: r.minX, y: r.minY + h * 0.18),
                   control2: CGPoint(x: r.minX + w * 0.22, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX - w * 0.02, y: sideY),
                   control1: CGPoint(x: r.maxX - w * 0.22, y: r.minY),
                   control2: CGPoint(x: r.maxX, y: r.minY + h * 0.18))
        p.addCurve(to: CGPoint(x: r.minX + w * 0.02, y: sideY),
                   control1: CGPoint(x: r.maxX - w * 0.18, y: r.minY + h * 0.20),
                   control2: CGPoint(x: r.minX + w * 0.18, y: r.minY + h * 0.20))
        p.closeSubpath()
        return p
    }
}

/// Lem som en blød kurve i enheds-koordinater (0–1) i hele rammen.
struct AthLimbShape: Shape {
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

/// ∪ – smil / lukkede, sovende øjne.
struct AthCupShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY),
                       control: CGPoint(x: r.midX, y: r.minY + h * 2))
        return p
    }
}

/// ∩ – lille surmule-mund / glade lukkede øjne.
struct AthHumpShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY),
                       control: CGPoint(x: r.midX, y: r.maxY - h * 2))
        return p
    }
}

// MARK: - Figuren

struct OperatorBodyAthletic: View {
    static let geometry = BodyGeometry(
        headCenter: CGPoint(x: 0.50, y: 0.18), headSize: CGSize(width: 0.14, height: 0.17),
        eyeY: 0.19, eyeDX: 0.03,
        torso: CGRect(x: 0.385, y: 0.295, width: 0.23, height: 0.245),
        rightHand: CGPoint(x: 0.63, y: 0.57), rightHip: CGPoint(x: 0.585, y: 0.56))

    let camo: Camo
    let skin: SkinTone
    let state: ReadinessState
    let s: CGFloat
    let t: Double
    let animated: Bool

    private typealias M = Tuning.Motion
    private typealias G = OperatorBodyAthletic

    private static let hairColor = Color(hex: 0x2B2420)
    private static let mouthColor = Color(hex: 0x4A2A24)

    private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: s * x, y: s * y)
    }

    var body: some View {
        ZStack {
            armsLayer
            legsLayer
            torsoLayer
            beltLayer
            handsLayer
            neckLayer
            headLayer
            faceLayer
        }
        .frame(width: s, height: s)
        .saturation(state == .suspended ? 0.55 : 1)
    }

    // MARK: Tilstand

    private var slumped: Bool { state == .exhausted || state == .suspended }

    private var blink: CGFloat {
        guard animated, state == .ready else { return 1 }
        let p: Double = t.truncatingRemainder(dividingBy: M.blinkEvery)
        return p < 0.14 ? 0.12 : 1
    }

    // MARK: Ben

    private var legsLayer: some View {
        let w: CGFloat = s * 0.18
        let h: CGFloat = s * 0.37
        return ZStack {
            AthPantsShape()
                .fill(camo.dark)
                .frame(width: w, height: h)
                .position(pt(0.50, 0.72))
            boot(cx: 0.465)
            boot(cx: 0.535)
        }
    }

    private func boot(cx: CGFloat) -> some View {
        let w: CGFloat = s * 0.07
        let h: CGFloat = s * 0.045
        let r: CGFloat = s * 0.016
        return RoundedRectangle(cornerRadius: r, style: .continuous)
            .fill(Theme.polymer)
            .frame(width: w, height: h)
            .position(pt(cx, 0.9275))
    }

    // MARK: Arme

    private var shoulderY: CGFloat { slumped ? 0.333 : 0.325 }
    private var handY: CGFloat { slumped ? 0.58 : 0.57 }
    private var handDX: CGFloat { slumped ? 0.118 : 0.13 }

    private var leftHand: CGPoint { CGPoint(x: 0.50 - handDX, y: handY) }
    private var rightHand: CGPoint { CGPoint(x: 0.50 + handDX, y: handY) }

    private var armsLayer: some View {
        let lh: CGPoint = leftHand
        let rh: CGPoint = rightHand
        let elbowY: CGFloat = 0.45
        let leftShoulder = CGPoint(x: 0.405, y: shoulderY)
        let rightShoulder = CGPoint(x: 0.595, y: shoulderY)
        let leftElbow = CGPoint(x: lh.x - 0.012, y: elbowY)
        let rightElbow = CGPoint(x: rh.x + 0.012, y: elbowY)
        return ZStack {
            arm(shoulder: leftShoulder, elbow: leftElbow, hand: lh)
            arm(shoulder: rightShoulder, elbow: rightElbow, hand: rh)
        }
    }

    private func arm(shoulder: CGPoint, elbow: CGPoint, hand: CGPoint) -> some View {
        let shape = AthLimbShape(a: shoulder, c: elbow, b: hand)
        let width: CGFloat = s * 0.044
        return shape
            .stroke(camo.main, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
            .frame(width: s, height: s)
    }

    // MARK: Torso

    private var torsoLayer: some View {
        let rect: CGRect = G.geometry.torso
        let w: CGFloat = s * rect.width
        let h: CGFloat = s * rect.height
        return ZStack {
            AthTorsoShape()
                .fill(camo.main)
            camoSpots(w: w, h: h)
                .clipShape(AthTorsoShape())
        }
        .frame(width: w, height: h)
        .position(pt(rect.midX, rect.midY))
    }

    /// Tre store, rolige pletter – kun en antydning af camo.
    private func camoSpots(w: CGFloat, h: CGFloat) -> some View {
        let tint: Color = camo.light.opacity(0.28)
        return ZStack {
            Ellipse()
                .fill(tint)
                .frame(width: w * 0.42, height: h * 0.20)
                .rotationEffect(.degrees(-14))
                .offset(x: -w * 0.18, y: -h * 0.12)
            Ellipse()
                .fill(tint)
                .frame(width: w * 0.36, height: h * 0.16)
                .rotationEffect(.degrees(12))
                .offset(x: w * 0.20, y: h * 0.08)
            Ellipse()
                .fill(tint)
                .frame(width: w * 0.30, height: h * 0.14)
                .rotationEffect(.degrees(-8))
                .offset(x: -w * 0.08, y: h * 0.32)
        }
        .frame(width: w, height: h)
    }

    // MARK: Bælte

    private var beltLayer: some View {
        let w: CGFloat = s * 0.178
        let h: CGFloat = s * 0.018
        return RoundedRectangle(cornerRadius: s * 0.004, style: .continuous)
            .fill(Theme.polymer)
            .frame(width: w, height: h)
            .position(pt(0.50, 0.54))
    }

    // MARK: Hænder

    private var handsLayer: some View {
        ZStack {
            glove(at: leftHand)
            glove(at: rightHand)
        }
    }

    private func glove(at p: CGPoint) -> some View {
        let w: CGFloat = s * 0.042
        let h: CGFloat = s * 0.05
        return Ellipse()
            .fill(Theme.polymer)
            .frame(width: w, height: h)
            .position(pt(p.x, p.y))
    }

    // MARK: Hals og hoved

    private var neckLayer: some View {
        let w: CGFloat = s * 0.042
        let h: CGFloat = s * 0.06
        return Rectangle()
            .fill(skin.shade)
            .frame(width: w, height: h)
            .position(pt(0.50, 0.28))
    }

    private var headLayer: some View {
        let g: BodyGeometry = G.geometry
        let headW: CGFloat = s * g.headSize.width
        let headH: CGFloat = s * g.headSize.height
        let hairW: CGFloat = headW * 1.06
        let hairH: CGFloat = headH * 1.04
        let hairY: CGFloat = g.headCenter.y - 0.004
        let earDX: CGFloat = g.headSize.width * 0.5
        return ZStack {
            ear(x: 0.50 - earDX)
            ear(x: 0.50 + earDX)
            Ellipse()
                .fill(skin.main)
                .frame(width: headW, height: headH)
                .position(pt(g.headCenter.x, g.headCenter.y))
            AthHairShape()
                .fill(G.hairColor)
                .frame(width: hairW, height: hairH)
                .position(pt(g.headCenter.x, hairY))
        }
    }

    private func ear(x: CGFloat) -> some View {
        let w: CGFloat = s * 0.024
        let h: CGFloat = s * 0.038
        return Ellipse()
            .fill(skin.shade)
            .frame(width: w, height: h)
            .position(pt(x, 0.192))
    }

    // MARK: Ansigt

    private var eyeY: CGFloat { G.geometry.eyeY }
    private var eyeDX: CGFloat { G.geometry.eyeDX }
    private var mouthY: CGFloat { 0.228 }

    private var faceLayer: some View {
        ZStack {
            eyes
            brows
            mouth
        }
    }

    @ViewBuilder
    private var eyes: some View {
        switch state {
        case .leave:
            closedEye(x: 0.50 - eyeDX, happy: true)
            closedEye(x: 0.50 + eyeDX, happy: true)
        case .resting:
            closedEye(x: 0.50 - eyeDX, happy: false)
            closedEye(x: 0.50 + eyeDX, happy: false)
        case .tired:
            sleepyEye(x: 0.50 - eyeDX)
            sleepyEye(x: 0.50 + eyeDX)
        case .suspended:
            dotEye(x: 0.50 - eyeDX, dy: 0.005, size: 0.013)
            dotEye(x: 0.50 + eyeDX, dy: 0.005, size: 0.013)
        case .exhausted:
            dotEye(x: 0.50 - eyeDX, dy: 0.002, size: 0.014)
            dotEye(x: 0.50 + eyeDX, dy: 0.002, size: 0.014)
        default:
            dotEye(x: 0.50 - eyeDX, dy: 0, size: 0.016)
            dotEye(x: 0.50 + eyeDX, dy: 0, size: 0.016)
        }
    }

    private func dotEye(x: CGFloat, dy: CGFloat, size: CGFloat) -> some View {
        let w: CGFloat = s * size
        let h: CGFloat = s * size * 1.12 * blink
        return Ellipse()
            .fill(Theme.eye)
            .frame(width: w, height: h)
            .position(pt(x, eyeY + dy))
    }

    /// Halvt lukket øje: lille flad prik med et låg ovenover.
    private func sleepyEye(x: CGFloat) -> some View {
        let dotW: CGFloat = s * 0.016
        let dotH: CGFloat = s * 0.008
        let lidW: CGFloat = s * 0.022
        let lidH: CGFloat = s * 0.003
        return ZStack {
            Ellipse()
                .fill(Theme.eye)
                .frame(width: dotW, height: dotH)
                .position(pt(x, eyeY + 0.003))
            Capsule()
                .fill(Theme.eye)
                .frame(width: lidW, height: lidH)
                .position(pt(x, eyeY - 0.002))
        }
    }

    @ViewBuilder
    private func closedEye(x: CGFloat, happy: Bool) -> some View {
        let w: CGFloat = s * 0.02
        let h: CGFloat = s * 0.006
        let line: CGFloat = max(0.8, s * 0.004)
        let style = StrokeStyle(lineWidth: line, lineCap: .round)
        if happy {
            AthHumpShape()
                .stroke(Theme.eye, style: style)
                .frame(width: w, height: h)
                .position(pt(x, eyeY))
        } else {
            AthCupShape()
                .stroke(Theme.eye, style: style)
                .frame(width: w, height: h)
                .position(pt(x, eyeY))
        }
    }

    @ViewBuilder
    private var brows: some View {
        if state == .exhausted {
            brow(x: 0.50 - eyeDX, degrees: -16)
            brow(x: 0.50 + eyeDX, degrees: 16)
        }
    }

    private func brow(x: CGFloat, degrees: Double) -> some View {
        let w: CGFloat = s * 0.02
        let h: CGFloat = s * 0.004
        return Capsule()
            .fill(G.hairColor)
            .frame(width: w, height: h)
            .rotationEffect(.degrees(degrees))
            .position(pt(x, eyeY - 0.017))
    }

    @ViewBuilder
    private var mouth: some View {
        switch state {
        case .ready, .leave:
            smile(width: 0.028)
        case .resting:
            smile(width: 0.016)
        case .exhausted, .suspended:
            frown(width: 0.02)
        case .tired:
            flatMouth(width: 0.014)
        default:
            flatMouth(width: 0.018)
        }
    }

    private var mouthLine: CGFloat { max(0.8, s * 0.004) }

    private func smile(width: CGFloat) -> some View {
        let w: CGFloat = s * width
        let h: CGFloat = s * 0.006
        return AthCupShape()
            .stroke(G.mouthColor, style: StrokeStyle(lineWidth: mouthLine, lineCap: .round))
            .frame(width: w, height: h)
            .position(pt(0.50, mouthY))
    }

    private func frown(width: CGFloat) -> some View {
        let w: CGFloat = s * width
        let h: CGFloat = s * 0.005
        return AthHumpShape()
            .stroke(G.mouthColor, style: StrokeStyle(lineWidth: mouthLine, lineCap: .round))
            .frame(width: w, height: h)
            .position(pt(0.50, mouthY + 0.004))
    }

    private func flatMouth(width: CGFloat) -> some View {
        let w: CGFloat = s * width
        let h: CGFloat = mouthLine
        return Capsule()
            .fill(G.mouthColor)
            .frame(width: w, height: h)
            .position(pt(0.50, mouthY + 0.002))
    }
}
