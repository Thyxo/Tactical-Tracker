import SwiftUI
import UIKit

/// Baggrunde/baser. Bruger bg_<id>.png fra Assets/Incoming hvis den findes – ellers kodet scene.
/// Nederste midterste tredjedel holdes rolig (der står figuren), toppen simpel.
struct SceneBackground: View {
    let id: String

    var body: some View {
        if let img = incomingImage("bg_\(id)") {
            Image(uiImage: img).resizable().scaledToFill()
        } else {
            switch id {
            case "range": ScnRangeScene()
            case "vehicle": ScnVehicleScene()
            case "city": ScnCityScene()
            default: ScnHQScene()
            }
        }
    }
}

/// Lille forhåndsvisning til butikken.
struct ScenePreview: View {
    let id: String

    var body: some View {
        SceneBackground(id: id)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Fælles

/// Langsomt ur til rolige baggrundsanimationer (skaleret med Tuning.Motion.ambientSpeed).
struct ScnClock<Content: View>: View {
    let content: (Double) -> Content

    init(@ViewBuilder content: @escaping (Double) -> Content) {
        self.content = content
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { ctx in
            content(ctx.date.timeIntervalSinceReferenceDate * Tuning.Motion.ambientSpeed)
        }
    }
}

/// Gitter (fx på vægkortet).
struct ScnGridShape: Shape {
    let cols: Int
    let rows: Int

    func path(in r: CGRect) -> Path {
        var p = Path()
        if cols > 1 {
            for i in 1..<cols {
                let x: CGFloat = r.minX + r.width * CGFloat(i) / CGFloat(cols)
                p.move(to: CGPoint(x: x, y: r.minY))
                p.addLine(to: CGPoint(x: x, y: r.maxY))
            }
        }
        if rows > 1 {
            for j in 1..<rows {
                let y: CGFloat = r.minY + r.height * CGFloat(j) / CGFloat(rows)
                p.move(to: CGPoint(x: r.minX, y: y))
                p.addLine(to: CGPoint(x: r.maxX, y: y))
            }
        }
        return p
    }
}

/// Fladtoppet volde/bakke.
struct ScnBermShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + h * 0.55))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * 0.30, y: r.minY + h * 0.15),
                       control: CGPoint(x: r.minX + w * 0.12, y: r.minY + h * 0.20))
        p.addLine(to: CGPoint(x: r.minX + w * 0.74, y: r.minY + h * 0.10))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.45),
                       control: CGPoint(x: r.minX + w * 0.92, y: r.minY + h * 0.10))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Lampeskærm (trapez, smal foroven).
struct ScnShadeShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        p.move(to: CGPoint(x: r.minX + w * 0.28, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - w * 0.28, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Lyskegle fra lampe (smal foroven, bred forneden).
struct ScnConeShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        p.move(to: CGPoint(x: r.midX - w * 0.08, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX + w * 0.08, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Spidst tårn (trekant).
struct ScnSpireShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Snoet spir-mønster (zigzag op ad en trekant) – Vor Frelsers Kirke.
struct ScnSpiralShape: Shape {
    let turns: Int

    func path(in r: CGRect) -> Path {
        var p = Path()
        let h: CGFloat = r.height
        let half: CGFloat = r.width * 0.5
        let steps: Int = max(2, turns * 2)
        for k in 0...steps {
            let f: CGFloat = CGFloat(k) / CGFloat(steps)
            let y: CGFloat = r.maxY - h * f
            let hw: CGFloat = half * (1 - f)
            let x: CGFloat = k % 2 == 0 ? r.midX - hw : r.midX + hw
            if k == 0 {
                p.move(to: CGPoint(x: x, y: y))
            } else {
                p.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return p
    }
}

/// Tagsilhuet med trappede højder og enkelte gavle.
struct ScnSkylineShape: Shape {
    let heights: [CGFloat]

    func path(in r: CGRect) -> Path {
        var p = Path()
        let n: Int = heights.count
        guard n > 0 else { return p }
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        let segW: CGFloat = w / CGFloat(n)
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        for i in 0..<n {
            let x0: CGFloat = r.minX + segW * CGFloat(i)
            let x1: CGFloat = x0 + segW
            let top: CGFloat = r.maxY - h * heights[i]
            p.addLine(to: CGPoint(x: x0, y: top))
            if i % 3 == 1 {
                let peak: CGFloat = top - h * 0.10
                p.addLine(to: CGPoint(x: x0 + segW * 0.5, y: peak))
            }
            p.addLine(to: CGPoint(x: x1, y: top))
        }
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - HQ (operationsrum, standard)

struct ScnHQScene: View {
    private static let pins: [CGPoint] = [
        CGPoint(x: 0.22, y: 0.35), CGPoint(x: 0.47, y: 0.62),
        CGPoint(x: 0.71, y: 0.28), CGPoint(x: 0.83, y: 0.70),
    ]

    var body: some View {
        GeometryReader { g in
            let w: CGFloat = g.size.width
            let h: CGFloat = g.size.height
            ZStack {
                wall(w: w, h: h)
                map(w: w, h: h)
                monitors(w: w, h: h)
                table(w: w, h: h)
                lamp(w: w, h: h)
            }
            .frame(width: w, height: h)
        }
    }

    private func wall(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x1B232A), Color(hex: 0x12181D)],
                           startPoint: .top, endPoint: .bottom)
            ForEach(0..<5, id: \.self) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 1, height: h)
                    .position(x: w * CGFloat(i + 1) / 6.0, y: h * 0.5)
            }
        }
    }

    private func map(w: CGFloat, h: CGFloat) -> some View {
        let mw: CGFloat = w * 0.56
        let mh: CGFloat = min(h * 0.30, mw * 0.62)
        return ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0x1E3238), Color(hex: 0x172629)],
                                     startPoint: .top, endPoint: .bottom))
            Ellipse()
                .fill(Theme.olive.opacity(0.25))
                .frame(width: mw * 0.36, height: mh * 0.42)
                .rotationEffect(.degrees(-15))
                .offset(x: -mw * 0.16, y: -mh * 0.06)
            Ellipse()
                .fill(Theme.olive.opacity(0.2))
                .frame(width: mw * 0.30, height: mh * 0.32)
                .rotationEffect(.degrees(20))
                .offset(x: mw * 0.22, y: mh * 0.14)
            ScnGridShape(cols: 8, rows: 5)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
            ForEach(0..<Self.pins.count, id: \.self) { i in
                pin(i: i, mw: mw, mh: mh)
            }
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Theme.line, lineWidth: 2)
        }
        .frame(width: mw, height: mh)
        .position(x: w * 0.5, y: h * 0.36)
    }

    private func pin(i: Int, mw: CGFloat, mh: CGFloat) -> some View {
        let p: CGPoint = Self.pins[i]
        let col: Color = i % 2 == 0 ? Theme.alert : Theme.amber
        return ZStack {
            Circle().fill(col.opacity(0.25)).frame(width: 12, height: 12)
            Circle().fill(col).frame(width: 5, height: 5)
        }
        .position(x: mw * p.x, y: mh * p.y)
    }

    private func monitors(w: CGFloat, h: CGFloat) -> some View {
        let mw: CGFloat = w * 0.17
        let mh: CGFloat = w * 0.12
        return ScnClock { t in
            ZStack {
                ScnMonitor(t: t, tint: Theme.steady, phase: 0)
                    .frame(width: mw, height: mh)
                    .position(x: w * 0.13, y: h * 0.58)
                ScnMonitor(t: t, tint: Theme.ready, phase: 1.7)
                    .frame(width: mw, height: mh)
                    .position(x: w * 0.87, y: h * 0.58)
            }
        }
    }

    private func table(w: CGFloat, h: CGFloat) -> some View {
        let th: CGFloat = h * 0.16
        return ZStack(alignment: .top) {
            LinearGradient(colors: [Color(hex: 0x2B231C), Color(hex: 0x1A1510)],
                           startPoint: .top, endPoint: .bottom)
            Rectangle()
                .fill(Color(hex: 0x4A3B2C))
                .frame(height: 3)
        }
        .frame(width: w, height: th)
        .position(x: w * 0.5, y: h - th * 0.5)
    }

    private func lamp(w: CGFloat, h: CGFloat) -> some View {
        let x: CGFloat = w * 0.84
        let tableTop: CGFloat = h * 0.84
        let shadeW: CGFloat = w * 0.09
        let shadeH: CGFloat = w * 0.05
        let shadeY: CGFloat = tableTop - h * 0.12
        let stemH: CGFloat = tableTop - shadeY
        return ZStack {
            Ellipse()
                .fill(RadialGradient(colors: [Theme.amber.opacity(0.22), Color.clear],
                                     center: .center, startRadius: 0, endRadius: w * 0.25))
                .frame(width: w * 0.5, height: h * 0.4)
                .position(x: x, y: tableTop - h * 0.05)
            ScnConeShape()
                .fill(LinearGradient(colors: [Theme.amber.opacity(0.18), Theme.amber.opacity(0.02)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: shadeW * 2.2, height: stemH)
                .position(x: x, y: shadeY + stemH * 0.5)
            Rectangle()
                .fill(Theme.metal)
                .frame(width: 2, height: stemH)
                .position(x: x - shadeW * 0.6, y: shadeY + stemH * 0.5)
            Capsule()
                .fill(Theme.metal)
                .frame(width: shadeW * 0.8, height: 4)
                .position(x: x - shadeW * 0.6, y: tableTop)
            ScnShadeShape()
                .fill(Color(hex: 0x3D4A3A))
                .frame(width: shadeW, height: shadeH)
                .position(x: x, y: shadeY)
            Capsule()
                .fill(Color(hex: 0xFFE2A0))
                .frame(width: shadeW * 0.7, height: 3)
                .position(x: x, y: shadeY + shadeH * 0.5)
        }
    }
}

/// Lille vægmonitor med rolig glød.
struct ScnMonitor: View {
    let t: Double
    let tint: Color
    let phase: Double

    var body: some View {
        GeometryReader { g in
            let w: CGFloat = g.size.width
            let h: CGFloat = g.size.height
            let glow: Double = 0.6 + 0.25 * sin(t * 1.3 + phase)
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.08, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .blur(radius: w * 0.08)
                    .scaleEffect(1.15)
                RoundedRectangle(cornerRadius: w * 0.06, style: .continuous)
                    .fill(Color(hex: 0x0B0F12))
                RoundedRectangle(cornerRadius: w * 0.04, style: .continuous)
                    .fill(tint.opacity(0.10 + 0.12 * glow))
                    .padding(w * 0.06)
                lines(w: w, h: h, glow: glow)
                blip(w: w, h: h)
            }
        }
    }

    private func lines(w: CGFloat, h: CGFloat, glow: Double) -> some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                line(i: i, w: w, h: h, glow: glow)
            }
        }
    }

    private func line(i: Int, w: CGFloat, h: CGFloat, glow: Double) -> some View {
        let frac: CGFloat = 0.55 - 0.1 * CGFloat(i % 3)
        let lw: CGFloat = w * frac
        let x: CGFloat = w * 0.14 + lw * 0.5
        let y: CGFloat = h * (0.25 + 0.15 * CGFloat(i))
        return Capsule()
            .fill(tint.opacity(0.5 * glow))
            .frame(width: lw, height: max(1.5, h * 0.05))
            .position(x: x, y: y)
    }

    private func blip(w: CGFloat, h: CGFloat) -> some View {
        let on: Bool = sin(t * 2.0 + phase * 2.0) > 0.3
        let d: CGFloat = max(3, w * 0.06)
        return Circle()
            .fill(tint.opacity(on ? 0.95 : 0.25))
            .frame(width: d, height: d)
            .position(x: w * 0.82, y: h * 0.26)
    }
}

// MARK: - Skydebane i skumring

struct ScnRangeScene: View {
    var body: some View {
        GeometryReader { g in
            let w: CGFloat = g.size.width
            let h: CGFloat = g.size.height
            ZStack {
                sky(w: w, h: h)
                ScnBermShape()
                    .fill(Color(hex: 0x2A2E2A))
                    .frame(width: w, height: h * 0.12)
                    .position(x: w * 0.5, y: h * 0.62)
                ground(w: w, h: h)
                targets(w: w, h: h)
                sandbags(w: w, h: h)
            }
            .frame(width: w, height: h)
        }
    }

    private func sky(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x1C2340), Color(hex: 0x3E3552), Color(hex: 0xB0685A)],
                           startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.66))
            Circle()
                .fill(Color(hex: 0xF2A65A).opacity(0.55))
                .frame(width: w * 0.16, height: w * 0.16)
                .blur(radius: w * 0.03)
                .position(x: w * 0.70, y: h * 0.60)
            Circle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 2, height: 2)
                .position(x: w * 0.18, y: h * 0.10)
            Circle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 2, height: 2)
                .position(x: w * 0.82, y: h * 0.16)
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 1.5, height: 1.5)
                .position(x: w * 0.42, y: h * 0.07)
        }
    }

    private func ground(w: CGFloat, h: CGFloat) -> some View {
        let gh: CGFloat = h * 0.36
        return LinearGradient(colors: [Color(hex: 0x2C2E25), Color(hex: 0x1B1D17)],
                              startPoint: .top, endPoint: .bottom)
            .frame(width: w, height: gh)
            .position(x: w * 0.5, y: h - gh * 0.5)
    }

    private func targets(w: CGFloat, h: CGFloat) -> some View {
        let small: CGFloat = w * 0.06
        let mid: CGFloat = w * 0.075
        return ZStack {
            ScnTargetStand(size: small)
                .position(x: w * 0.16, y: h * 0.61)
            ScnTargetStand(size: small)
                .position(x: w * 0.36, y: h * 0.60)
            ScnTargetStand(size: mid)
                .position(x: w * 0.80, y: h * 0.61)
        }
        .colorMultiply(Color(hex: 0xD9C4B4))
    }

    private func sandbags(w: CGFloat, h: CGFloat) -> some View {
        let bag: CGFloat = w * 0.09
        return ZStack {
            ScnSandbags(bag: bag)
                .position(x: w * 0.12, y: h * 0.88)
            ScnSandbags(bag: bag)
                .position(x: w * 0.88, y: h * 0.88)
        }
    }
}

/// Papirskive på to pæle (koncentriske ringe – ingen silhuetter).
struct ScnTargetStand: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            post(x: -size * 0.32)
            post(x: size * 0.32)
            RoundedRectangle(cornerRadius: size * 0.05, style: .continuous)
                .fill(Color(hex: 0xD8CFB6))
                .frame(width: size * 0.86, height: size * 0.86)
            ForEach(0..<3, id: \.self) { i in
                ring(i)
            }
            Circle()
                .fill(Color(hex: 0xA2453A))
                .frame(width: size * 0.12, height: size * 0.12)
        }
        .frame(width: size, height: size)
    }

    private func post(x: CGFloat) -> some View {
        Rectangle()
            .fill(Color(hex: 0x4A3B2A))
            .frame(width: size * 0.07, height: size * 1.1)
            .offset(x: x, y: size * 0.45)
    }

    private func ring(_ i: Int) -> some View {
        let d: CGFloat = size * (0.72 - 0.2 * CGFloat(i))
        let col: Color = i == 2 ? Color(hex: 0xA2453A) : Color(hex: 0x3A3A3A)
        return Circle()
            .stroke(col, lineWidth: max(0.8, size * 0.035))
            .frame(width: d, height: d)
    }
}

struct ScnSandbags: View {
    let bag: CGFloat

    var body: some View {
        VStack(spacing: -bag * 0.12) {
            HStack(spacing: -bag * 0.1) {
                ForEach(0..<2, id: \.self) { _ in
                    ScnBag(bag: bag)
                }
            }
            HStack(spacing: -bag * 0.1) {
                ForEach(0..<3, id: \.self) { _ in
                    ScnBag(bag: bag)
                }
            }
        }
    }
}

struct ScnBag: View {
    let bag: CGFloat

    var body: some View {
        Capsule()
            .fill(LinearGradient(colors: [Color(hex: 0x8F7D5A), Color(hex: 0x6A5A40)],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(Capsule().stroke(Color(hex: 0x4E4230), lineWidth: 1))
            .frame(width: bag, height: bag * 0.45)
    }
}

// MARK: - Pansret mandskabsvogn (indvendig)

struct ScnVehicleScene: View {
    var body: some View {
        GeometryReader { g in
            let w: CGFloat = g.size.width
            let h: CGFloat = g.size.height
            ZStack {
                walls(w: w, h: h)
                rivets(w: w, h: h, y: h * 0.18)
                rivets(w: w, h: h, y: h * 0.50)
                ScnClock { t in
                    ZStack {
                        redLamp(t: t, w: w, h: h)
                        ScnVanWindow(t: t)
                            .frame(width: w * 0.22, height: h * 0.11)
                            .position(x: w * 0.24, y: h * 0.32)
                        ScnVanWindow(t: t + 0.5)
                            .frame(width: w * 0.22, height: h * 0.11)
                            .position(x: w * 0.76, y: h * 0.32)
                    }
                }
                floor(w: w, h: h)
                bench(w: w, h: h, left: true)
                bench(w: w, h: h, left: false)
            }
            .frame(width: w, height: h)
        }
    }

    private func walls(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x262B30), Color(hex: 0x1A1E21)],
                           startPoint: .top, endPoint: .bottom)
            ForEach(0..<4, id: \.self) { i in
                Rectangle()
                    .fill(Color.black.opacity(0.25))
                    .frame(width: 2, height: h * 0.62)
                    .position(x: w * CGFloat(i + 1) / 5.0, y: h * 0.31)
            }
            Rectangle()
                .fill(Color.black.opacity(0.3))
                .frame(width: w, height: h * 0.1)
                .position(x: w * 0.5, y: h * 0.05)
        }
    }

    private func rivets(w: CGFloat, h: CGFloat, y: CGFloat) -> some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                rivet(x: w * (0.04 + 0.92 * CGFloat(i) / 11.0), y: y, w: w)
            }
        }
    }

    private func rivet(x: CGFloat, y: CGFloat, w: CGFloat) -> some View {
        let d: CGFloat = max(3, w * 0.012)
        return Circle()
            .fill(Theme.metalLight.opacity(0.7))
            .overlay(Circle().stroke(Color.black.opacity(0.4), lineWidth: 0.5))
            .frame(width: d, height: d)
            .position(x: x, y: y)
    }

    private func redLamp(t: Double, w: CGFloat, h: CGFloat) -> some View {
        let pulse: Double = 0.85 + 0.15 * sin(t * 0.8)
        return ZStack {
            Ellipse()
                .fill(RadialGradient(colors: [Theme.alert.opacity(0.28 * pulse), Color.clear],
                                     center: .center, startRadius: 0, endRadius: w * 0.45))
                .frame(width: w * 0.9, height: h * 0.45)
                .position(x: w * 0.5, y: h * 0.08)
            Capsule()
                .fill(Theme.alert.opacity(0.6 + 0.35 * pulse))
                .frame(width: w * 0.14, height: max(4, h * 0.022))
                .position(x: w * 0.5, y: h * 0.06)
        }
    }

    private func floor(w: CGFloat, h: CGFloat) -> some View {
        let fh: CGFloat = h * 0.38
        return ZStack {
            LinearGradient(colors: [Color(hex: 0x1C1F22), Color(hex: 0x111315)],
                           startPoint: .top, endPoint: .bottom)
            ForEach(0..<5, id: \.self) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: w, height: 1)
                    .position(x: w * 0.5, y: fh * (0.15 + 0.18 * CGFloat(i)))
            }
        }
        .frame(width: w, height: fh)
        .position(x: w * 0.5, y: h - fh * 0.5)
    }

    private func bench(w: CGFloat, h: CGFloat, left: Bool) -> some View {
        let bw: CGFloat = w * 0.32
        let cx: CGFloat = left ? bw * 0.5 - w * 0.02 : w - bw * 0.5 + w * 0.02
        let seatY: CGFloat = h * 0.66
        let seatH: CGFloat = h * 0.05
        let frontH: CGFloat = h * 0.14
        return ZStack {
            Rectangle()
                .fill(Color(hex: 0x24282C))
                .frame(width: bw, height: frontH)
                .position(x: cx, y: seatY + seatH * 0.5 + frontH * 0.5)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0x4A433A), Color(hex: 0x332E28)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: bw, height: seatH)
                .position(x: cx, y: seatY)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: 0x3A352F))
                .frame(width: bw * 0.9, height: h * 0.12)
                .position(x: cx, y: seatY - h * 0.1)
        }
    }
}

/// Lille vindue med forbipasserende gadelys.
struct ScnVanWindow: View {
    let t: Double

    var body: some View {
        GeometryReader { g in
            let w: CGFloat = g.size.width
            let h: CGFloat = g.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0x0A0F17), Color(hex: 0x151C27)],
                               startPoint: .top, endPoint: .bottom)
                ForEach(0..<3, id: \.self) { i in
                    light(i: i, w: w, h: h)
                }
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: w * 0.15, height: h * 1.6)
                    .rotationEffect(.degrees(20))
                    .position(x: w * 0.3, y: h * 0.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: h * 0.18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: h * 0.18, style: .continuous)
                    .stroke(Color(hex: 0x3A4148), lineWidth: max(2, h * 0.08))
            )
        }
    }

    private func light(i: Int, w: CGFloat, h: CGFloat) -> some View {
        let speed: Double = 0.35 + 0.1 * Double(i)
        let raw: Double = (t * speed + Double(i) * 0.37).truncatingRemainder(dividingBy: 1)
        let x: CGFloat = w * CGFloat(1.2 - raw * 1.4)
        let y: CGFloat = h * CGFloat(0.35 + 0.2 * Double(i % 2))
        let col: Color = i == 1 ? Color(hex: 0xBFD4F2) : Theme.amber
        return Capsule()
            .fill(col.opacity(0.7))
            .frame(width: w * 0.18, height: h * 0.08)
            .blur(radius: h * 0.04)
            .position(x: x, y: y)
    }
}

// MARK: - København om natten

struct ScnCityScene: View {
    private static let stars: [CGPoint] = [
        CGPoint(x: 0.06, y: 0.05), CGPoint(x: 0.14, y: 0.17), CGPoint(x: 0.23, y: 0.08),
        CGPoint(x: 0.31, y: 0.25), CGPoint(x: 0.38, y: 0.12), CGPoint(x: 0.46, y: 0.04),
        CGPoint(x: 0.52, y: 0.20), CGPoint(x: 0.59, y: 0.09), CGPoint(x: 0.66, y: 0.28),
        CGPoint(x: 0.72, y: 0.06), CGPoint(x: 0.93, y: 0.10), CGPoint(x: 0.95, y: 0.27),
        CGPoint(x: 0.10, y: 0.33), CGPoint(x: 0.44, y: 0.34), CGPoint(x: 0.78, y: 0.36),
        CGPoint(x: 0.27, y: 0.40), CGPoint(x: 0.62, y: 0.42), CGPoint(x: 0.88, y: 0.44),
    ]

    private static let farHeights: [CGFloat] = [
        0.35, 0.55, 0.42, 0.60, 0.38, 0.50, 0.66, 0.40, 0.58, 0.45, 0.52, 0.36,
    ]

    private static let nearHeights: [CGFloat] = [
        0.50, 0.70, 0.45, 0.62, 0.80, 0.40, 0.58, 0.72, 0.48, 0.66, 0.38, 0.55, 0.75, 0.44,
    ]

    private static let windows: [CGPoint] = [
        CGPoint(x: 0.05, y: 0.625), CGPoint(x: 0.09, y: 0.640), CGPoint(x: 0.17, y: 0.615),
        CGPoint(x: 0.30, y: 0.630), CGPoint(x: 0.34, y: 0.615), CGPoint(x: 0.41, y: 0.640),
        CGPoint(x: 0.53, y: 0.620), CGPoint(x: 0.61, y: 0.635), CGPoint(x: 0.66, y: 0.615),
        CGPoint(x: 0.79, y: 0.630), CGPoint(x: 0.86, y: 0.620), CGPoint(x: 0.93, y: 0.640),
    ]

    var body: some View {
        GeometryReader { g in
            let w: CGFloat = g.size.width
            let h: CGFloat = g.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0x070B18), Color(hex: 0x131D36), Color(hex: 0x22304A)],
                               startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.66))
                moon(w: w, h: h)
                ScnClock { t in
                    stars(t: t, w: w, h: h)
                }
                skyline(w: w, h: h)
                ScnClock { t in
                    water(t: t, w: w, h: h)
                }
                quay(w: w, h: h)
            }
            .frame(width: w, height: h)
        }
    }

    private func moon(w: CGFloat, h: CGFloat) -> some View {
        let d: CGFloat = w * 0.07
        return ZStack {
            Circle()
                .fill(Color(hex: 0xE6E2D3).opacity(0.15))
                .frame(width: d * 2.4, height: d * 2.4)
                .blur(radius: d * 0.4)
            Circle()
                .fill(Color(hex: 0xE6E2D3))
                .frame(width: d, height: d)
        }
        .position(x: w * 0.84, y: h * 0.17)
    }

    private func stars(t: Double, w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            ForEach(0..<Self.stars.count, id: \.self) { i in
                star(i: i, t: t, w: w, h: h)
            }
        }
    }

    private func star(i: Int, t: Double, w: CGFloat, h: CGFloat) -> some View {
        let p: CGPoint = Self.stars[i]
        let tw: Double = 0.45 + 0.3 * sin(t * 0.9 + Double(i) * 1.7)
        let d: CGFloat = i % 4 == 0 ? 2.5 : 1.6
        return Circle()
            .fill(Color.white.opacity(tw))
            .frame(width: d, height: d)
            .position(x: w * p.x, y: h * p.y)
    }

    private func skyline(w: CGFloat, h: CGFloat) -> some View {
        let baseY: CGFloat = h * 0.66
        let farH: CGFloat = h * 0.12
        let nearH: CGFloat = h * 0.16
        return ZStack {
            ScnSkylineShape(heights: Self.farHeights)
                .fill(Color(hex: 0x162036))
                .frame(width: w, height: farH)
                .position(x: w * 0.5, y: baseY - farH * 0.5 - h * 0.02)
            ScnTwistedSpire(width: w * 0.06, height: h * 0.30)
                .position(x: w * 0.22, y: baseY - h * 0.15)
            ScnDomeTower(width: w * 0.12, height: h * 0.16)
                .position(x: w * 0.74, y: baseY - h * 0.08)
            ScnSlimTower(width: w * 0.035, height: h * 0.24)
                .position(x: w * 0.56, y: baseY - h * 0.12)
            ScnSkylineShape(heights: Self.nearHeights)
                .fill(Color(hex: 0x0B111C))
                .frame(width: w, height: nearH)
                .position(x: w * 0.5, y: baseY - nearH * 0.5)
            ForEach(0..<Self.windows.count, id: \.self) { i in
                window(i: i, w: w, h: h)
            }
        }
    }

    private func window(i: Int, w: CGFloat, h: CGFloat) -> some View {
        let p: CGPoint = Self.windows[i]
        let op: Double = i % 3 == 0 ? 0.55 : 0.8
        return Rectangle()
            .fill(Color(hex: 0xF2C46B).opacity(op))
            .frame(width: max(2, w * 0.012), height: max(2, h * 0.016))
            .position(x: w * p.x, y: h * p.y)
    }

    private func water(t: Double, w: CGFloat, h: CGFloat) -> some View {
        let top: CGFloat = h * 0.66
        let wh: CGFloat = h * 0.22
        return ZStack {
            LinearGradient(colors: [Color(hex: 0x0E1828), Color(hex: 0x070B12)],
                           startPoint: .top, endPoint: .bottom)
                .frame(width: w, height: wh)
                .position(x: w * 0.5, y: top + wh * 0.5)
            ForEach(0..<Self.windows.count, id: \.self) { i in
                reflection(i: i, t: t, w: w, top: top, wh: wh)
            }
            ForEach(0..<4, id: \.self) { i in
                ripple(i: i, t: t, w: w, top: top, wh: wh)
            }
        }
    }

    private func reflection(i: Int, t: Double, w: CGFloat, top: CGFloat, wh: CGFloat) -> some View {
        let p: CGPoint = Self.windows[i]
        let wobble: CGFloat = CGFloat(sin(t * 1.2 + Double(i) * 0.9)) * w * 0.004
        let len: CGFloat = wh * (0.25 + 0.1 * CGFloat(i % 3))
        return Capsule()
            .fill(Color(hex: 0xF2C46B).opacity(0.16))
            .frame(width: max(2, w * 0.012), height: len)
            .position(x: w * p.x + wobble, y: top + len * 0.5 + wh * 0.06)
    }

    private func ripple(i: Int, t: Double, w: CGFloat, top: CGFloat, wh: CGFloat) -> some View {
        let drift: CGFloat = CGFloat(sin(t * 0.5 + Double(i) * 1.3)) * w * 0.03
        let x: CGFloat = w * (0.2 + 0.2 * CGFloat(i)) + drift
        let y: CGFloat = top + wh * (0.25 + 0.17 * CGFloat(i))
        return Capsule()
            .fill(Color.white.opacity(0.05))
            .frame(width: w * 0.16, height: 1.5)
            .position(x: x, y: y)
    }

    private func quay(w: CGFloat, h: CGFloat) -> some View {
        let qh: CGFloat = h * 0.12
        return ZStack(alignment: .top) {
            LinearGradient(colors: [Color(hex: 0x1C1F24), Color(hex: 0x111317)],
                           startPoint: .top, endPoint: .bottom)
            Rectangle()
                .fill(Color(hex: 0x2C3036))
                .frame(height: 2)
        }
        .frame(width: w, height: qh)
        .position(x: w * 0.5, y: h - qh * 0.5)
    }
}

/// Vor Frelsers Kirkes snoede spir (forenklet).
struct ScnTwistedSpire: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let spireH: CGFloat = height * 0.55
        let towerH: CGFloat = height - spireH
        let ball: CGFloat = max(3, width * 0.18)
        return VStack(spacing: 0) {
            Circle()
                .fill(Theme.gold.opacity(0.8))
                .frame(width: ball, height: ball)
            ZStack {
                ScnSpireShape()
                    .fill(Color(hex: 0x0E1422))
                ScnSpiralShape(turns: 6)
                    .stroke(Theme.gold.opacity(0.5), lineWidth: 1)
            }
            .frame(width: width * 0.7, height: spireH - ball)
            Rectangle()
                .fill(Color(hex: 0x111827))
                .frame(width: width, height: towerH)
        }
        .frame(width: width, height: height)
    }
}

/// Kobbergrøn kuppel (Marmorkirken-agtig).
struct ScnDomeTower: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let domeH: CGFloat = height * 0.45
        let baseH: CGFloat = height - domeH
        return VStack(spacing: 0) {
            Rectangle()
                .fill(Color(hex: 0x3E6B5E))
                .frame(width: max(1.5, width * 0.04), height: domeH * 0.3)
            Ellipse()
                .fill(LinearGradient(colors: [Color(hex: 0x4F8273), Color(hex: 0x2E5247)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: width * 0.8, height: domeH * 1.4)
                .frame(height: domeH * 0.7, alignment: .top)
                .clipped()
            Rectangle()
                .fill(Color(hex: 0x111827))
                .frame(width: width, height: baseH)
        }
        .frame(width: width, height: height)
    }
}

/// Slankt tårn med spids (Rådhustårnet-agtigt).
struct ScnSlimTower: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let topH: CGFloat = height * 0.35
        return VStack(spacing: 0) {
            ScnSpireShape()
                .fill(Color(hex: 0x2E5247))
                .frame(width: width, height: topH)
            Rectangle()
                .fill(Color(hex: 0x111827))
                .frame(width: width, height: height - topH)
        }
        .frame(width: width, height: height)
    }
}
