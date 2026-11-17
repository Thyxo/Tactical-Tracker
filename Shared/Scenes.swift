import SwiftUI
import UIKit

/// Baggrunde/baser. Bruger bg_<id>.png fra Assets/Incoming hvis den findes – ellers kodet scene.
/// Rolig, lys og enkel stil (som Sælliv): få store flader, bløde gradienter, max én langsom animation.
/// Nederste ~45 % holdes rolig (der står figuren), toppen simpel (piller og taleboble).
/// Vælger scene efter tema: mørkt tema = den oprindelige base, lyst tema = den lyse.
struct SceneBackground: View {
    let id: String

    var body: some View {
        if Theme.isDark { DarkSceneBackground(id: id) } else { LightSceneBackground(id: id) }
    }
}

/// Lys, rolig udgave.
struct LightSceneBackground: View {
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

/// Blød, flad sky.
struct ScnCloud: View {
    let width: CGFloat

    var body: some View {
        let h: CGFloat = width * 0.42
        let big: CGFloat = h * 0.95
        let small: CGFloat = h * 0.72
        ZStack {
            Capsule().fill(Color.white)
                .frame(width: width, height: h * 0.55)
                .offset(y: h * 0.2)
            Circle().fill(Color.white)
                .frame(width: small, height: small)
                .offset(x: -width * 0.18, y: h * 0.02)
            Circle().fill(Color.white)
                .frame(width: big, height: big)
                .offset(x: width * 0.1, y: -h * 0.08)
        }
        .frame(width: width, height: h)
        .opacity(0.85)
    }
}

/// Én sky der driver langsomt hen over et område (eneste animation i scenen).
struct ScnDriftingCloud: View {
    let areaWidth: CGFloat
    let cloudWidth: CGFloat
    let y: CGFloat
    let speed: Double
    let phase: Double

    var body: some View {
        ScnClock { t in
            let raw: Double = t * speed + phase
            let p: Double = raw - floor(raw)
            let span: CGFloat = areaWidth + cloudWidth * 2
            let x: CGFloat = -cloudWidth + span * CGFloat(p)
            ScnCloud(width: cloudWidth)
                .position(x: x, y: y)
        }
    }
}

/// Simpel trekant (gavl, vimpel).
struct ScnTriangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Vimpel der peger mod højre.
struct ScnPennantShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Blødt bølgende bakke-/voldprofil, fyldt ned til bunden.
struct ScnHillShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        let y0: CGFloat = r.minY + h * 0.45
        let y1: CGFloat = r.minY + h * 0.12
        let y2: CGFloat = r.minY + h * 0.35
        let y3: CGFloat = r.minY + h * 0.05
        let y4: CGFloat = r.minY + h * 0.4
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: y0))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * 0.35, y: y2),
                       control: CGPoint(x: r.minX + w * 0.15, y: y1))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * 0.72, y: y2),
                       control: CGPoint(x: r.minX + w * 0.55, y: y3))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: y4),
                       control: CGPoint(x: r.minX + w * 0.88, y: y1))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Snoet spir (Vor Frelsers Kirke) – smalt, aftagende, med let forskudte led.
struct ScnSpireShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let steps: Int = 5
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        var left: [CGPoint] = []
        var right: [CGPoint] = []
        for i in 0...steps {
            let f: CGFloat = CGFloat(i) / CGFloat(steps)
            let y: CGFloat = r.maxY - h * f
            let half: CGFloat = w * 0.5 * (1 - f)
            let shift: CGFloat = (i % 2 == 0 ? 1 : -1) * w * 0.06 * (1 - f)
            left.append(CGPoint(x: r.midX - half + shift, y: y))
            right.append(CGPoint(x: r.midX + half + shift, y: y))
        }
        p.move(to: left[0])
        for i in 1...steps {
            p.addLine(to: left[i])
        }
        for i in stride(from: steps, through: 0, by: -1) {
            p.addLine(to: right[i])
        }
        p.closeSubpath()
        return p
    }
}

/// Hus-silhuet med valgfri gavl, bundforankret.
struct ScnHouse: View {
    let width: CGFloat
    let height: CGFloat
    let gable: Bool
    let color: Color

    var body: some View {
        VStack(spacing: 0) {
            if gable {
                ScnTriangle().fill(color)
                    .frame(width: width, height: width * 0.42)
            }
            Rectangle().fill(color)
                .frame(width: width, height: height)
        }
    }
}

// MARK: - HQ (lyst roligt rum)

struct ScnHQScene: View {
    var body: some View {
        GeometryReader { g in
            let w: CGFloat = g.size.width
            let h: CGFloat = g.size.height
            let floorTop: CGFloat = h * 0.6
            let winW: CGFloat = w * 0.48
            let winH: CGFloat = h * 0.27
            let winX: CGFloat = w * 0.36
            let winY: CGFloat = h * 0.31
            let shelfY: CGFloat = h * 0.4
            let shelfX: CGFloat = w * 0.8
            ZStack {
                // væg
                LinearGradient(colors: [Color(hex: 0xF5F1E8), Color(hex: 0xEBE5D7)],
                               startPoint: .top, endPoint: .bottom)

                // vindue med himmel og én drivende sky
                ZStack {
                    LinearGradient(colors: [Color(hex: 0xC9E0EC), Color(hex: 0xEAF3F4)],
                                   startPoint: .top, endPoint: .bottom)
                    ScnDriftingCloud(areaWidth: winW, cloudWidth: winW * 0.36,
                                     y: winH * 0.32, speed: 0.012, phase: 0.3)
                    ScnHillShape()
                        .fill(Color(hex: 0xBFD2AE))
                        .frame(width: winW, height: winH * 0.4)
                        .position(x: winW * 0.5, y: winH * 0.8)
                }
                .frame(width: winW, height: winH)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(7)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(hex: 0xFBF9F3))
                )
                .position(x: winX, y: winY)

                // vindueskarm
                Capsule()
                    .fill(Color(hex: 0xFBF9F3))
                    .frame(width: winW + 34, height: 9)
                    .position(x: winX, y: winY + winH * 0.5 + 12)

                // vimpel
                Capsule()
                    .fill(Color(hex: 0xB7A88A))
                    .frame(width: 3, height: h * 0.1)
                    .position(x: w * 0.79, y: h * 0.2)
                ScnPennantShape()
                    .fill(LinearGradient(colors: [Color(hex: 0x8FA483), Color(hex: 0x7D9271)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.13, height: h * 0.05)
                    .position(x: w * 0.79 + w * 0.065, y: h * 0.175)

                Group {
                    // hylde med to bøger og en plante
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color(hex: 0xD8C7A6))
                        .frame(width: w * 0.24, height: 7)
                        .position(x: shelfX, y: shelfY)
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color(hex: 0xA9B99B))
                        .frame(width: w * 0.035, height: h * 0.05)
                        .position(x: shelfX - w * 0.08, y: shelfY - h * 0.025 - 3)
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color(hex: 0xD9C8A2))
                        .frame(width: w * 0.03, height: h * 0.042)
                        .position(x: shelfX - w * 0.042, y: shelfY - h * 0.021 - 3)
                    Capsule()
                        .fill(Color(hex: 0x9DB28C))
                        .frame(width: w * 0.06, height: h * 0.035)
                        .position(x: shelfX + w * 0.06, y: shelfY - h * 0.03)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color(hex: 0xE2D4BC))
                        .frame(width: w * 0.045, height: h * 0.02)
                        .position(x: shelfX + w * 0.06, y: shelfY - h * 0.01 - 3)
                }
                // lyst trægulv
                Rectangle()
                    .fill(LinearGradient(colors: [Color(hex: 0xE6D5B6), Color(hex: 0xDBC7A3)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w, height: h - floorTop)
                    .position(x: w * 0.5, y: floorTop + (h - floorTop) * 0.5)

                // fodliste
                Rectangle()
                    .fill(Color(hex: 0xF7F3EA))
                    .frame(width: w, height: 6)
                    .position(x: w * 0.5, y: floorTop)

                // blødt tæppe
                Ellipse()
                    .fill(Color(hex: 0xCAD6BD).opacity(0.7))
                    .frame(width: w * 0.7, height: h * 0.1)
                    .position(x: w * 0.5, y: h * 0.86)
            }
            .frame(width: w, height: h)
        }
    }
}

// MARK: - Skydebane (udendørs om dagen)

struct ScnRangeScene: View {
    var body: some View {
        GeometryReader { g in
            let w: CGFloat = g.size.width
            let h: CGFloat = g.size.height
            let groundTop: CGFloat = h * 0.58
            let bermH: CGFloat = h * 0.2
            let board: CGFloat = w * 0.17
            let boardY: CGFloat = h * 0.44
            ZStack {
                // himmel
                LinearGradient(colors: [Color(hex: 0xCFE3EE), Color(hex: 0xF2EFE4)],
                               startPoint: .top, endPoint: .bottom)

                ScnDriftingCloud(areaWidth: w, cloudWidth: w * 0.26,
                                 y: h * 0.22, speed: 0.006, phase: 0.55)

                // fjern bakke
                Ellipse()
                    .fill(Color(hex: 0xD3DEC4))
                    .frame(width: w * 1.5, height: h * 0.2)
                    .position(x: w * 0.6, y: groundTop - h * 0.05)

                // volden
                ScnHillShape()
                    .fill(LinearGradient(colors: [Color(hex: 0xB4C79F), Color(hex: 0xA6BB90)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w, height: bermH)
                    .position(x: w * 0.5, y: groundTop - bermH * 0.5 + 4)

                // to skiver på pæle
                ScnTargetBoard(size: board)
                    .position(x: w * 0.2, y: boardY)
                ScnTargetBoard(size: board)
                    .position(x: w * 0.8, y: boardY)

                // jord / græs
                Rectangle()
                    .fill(LinearGradient(colors: [Color(hex: 0xDCE4C8), Color(hex: 0xD2DBBA)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w, height: h - groundTop)
                    .position(x: w * 0.5, y: groundTop + (h - groundTop) * 0.5)

                // sandsække ved siderne
                ScnSandbags(bag: w * 0.075)
                    .position(x: w * 0.1, y: groundTop + 2)
                ScnSandbags(bag: w * 0.075)
                    .position(x: w * 0.9, y: groundTop + 2)
            }
            .frame(width: w, height: h)
        }
    }
}

/// Rund skive med koncentriske cirkler på to pæle.
struct ScnTargetBoard: View {
    let size: CGFloat

    var body: some View {
        let postH: CGFloat = size * 0.9
        let ring1: CGFloat = size * 0.72
        let ring2: CGFloat = size * 0.46
        let ring3: CGFloat = size * 0.2
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: 0xA99577))
                .frame(width: 5, height: postH)
                .offset(x: -size * 0.22, y: size * 0.5)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: 0xA99577))
                .frame(width: 5, height: postH)
                .offset(x: size * 0.22, y: size * 0.5)
            Circle().fill(Color(hex: 0xF4EFE2)).frame(width: size, height: size)
            Circle().fill(Color(hex: 0xD9C7A4)).frame(width: ring1, height: ring1)
            Circle().fill(Color(hex: 0xF4EFE2)).frame(width: ring2, height: ring2)
            Circle().fill(Color(hex: 0xC99B7D)).frame(width: ring3, height: ring3)
        }
        .frame(width: size, height: size)
    }
}

/// Få flade sandsække (3 nederst, 2 øverst).
struct ScnSandbags: View {
    let bag: CGFloat

    var body: some View {
        let bh: CGFloat = bag * 0.45
        VStack(spacing: -2) {
            HStack(spacing: -2) {
                ForEach(0..<2, id: \.self) { _ in
                    Capsule().fill(Color(hex: 0xD6C59E)).frame(width: bag, height: bh)
                }
            }
            HStack(spacing: -2) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule().fill(Color(hex: 0xCDBB92)).frame(width: bag, height: bh)
                }
            }
        }
    }
}

// MARK: - Køretøj (parkeret varevogn på lys gade)

struct ScnVehicleScene: View {
    var body: some View {
        GeometryReader { g in
            let w: CGFloat = g.size.width
            let h: CGFloat = g.size.height
            let curbY: CGFloat = h * 0.6
            let vanW: CGFloat = w * 0.8
            let vanH: CGFloat = h * 0.16
            let vanX: CGFloat = w * 0.5
            let wheelY: CGFloat = curbY - 2
            let vanY: CGFloat = wheelY - vanH * 0.55
            let wheel: CGFloat = vanH * 0.42
            let hub: CGFloat = wheel * 0.42
            ZStack {
                // himmel
                LinearGradient(colors: [Color(hex: 0xD1E4EE), Color(hex: 0xF3EFE5)],
                               startPoint: .top, endPoint: .bottom)

                ScnDriftingCloud(areaWidth: w, cloudWidth: w * 0.24,
                                 y: h * 0.2, speed: 0.006, phase: 0.15)

                // blege bygninger i baggrunden
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(hex: 0xE7E0D2))
                    .frame(width: w * 0.42, height: h * 0.2)
                    .position(x: w * 0.2, y: curbY - h * 0.1)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(hex: 0xDFE3D6))
                    .frame(width: w * 0.5, height: h * 0.15)
                    .position(x: w * 0.78, y: curbY - h * 0.075)

                // fortov
                Rectangle()
                    .fill(Color(hex: 0xECE7DC))
                    .frame(width: w, height: h * 0.04)
                    .position(x: w * 0.5, y: curbY - h * 0.02)

                // vej
                Rectangle()
                    .fill(LinearGradient(colors: [Color(hex: 0xDEDAD0), Color(hex: 0xD3CFC5)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w, height: h - curbY)
                    .position(x: w * 0.5, y: curbY + (h - curbY) * 0.5)

                // blød skygge
                Ellipse()
                    .fill(Color(hex: 0xBDB8AC).opacity(0.5))
                    .frame(width: vanW * 0.95, height: h * 0.025)
                    .position(x: vanX, y: wheelY + wheel * 0.4)

                // karosseri
                RoundedRectangle(cornerRadius: vanH * 0.22, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: 0x66725A), Color(hex: 0x56614B)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: vanW, height: vanH)
                    .position(x: vanX, y: vanY)

                Group {
                    // ruder
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(hex: 0xC6D6DC))
                        .frame(width: vanW * 0.4, height: vanH * 0.32)
                        .position(x: vanX - vanW * 0.12, y: vanY - vanH * 0.18)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(hex: 0xC6D6DC))
                        .frame(width: vanW * 0.18, height: vanH * 0.32)
                        .position(x: vanX + vanW * 0.33, y: vanY - vanH * 0.18)
                }
                Group {
                    // hjul
                    Circle().fill(Color(hex: 0x3F443E)).frame(width: wheel, height: wheel)
                        .position(x: vanX - vanW * 0.3, y: wheelY)
                    Circle().fill(Color(hex: 0x3F443E)).frame(width: wheel, height: wheel)
                        .position(x: vanX + vanW * 0.3, y: wheelY)
                    Circle().fill(Color(hex: 0x9EA398)).frame(width: hub, height: hub)
                        .position(x: vanX - vanW * 0.3, y: wheelY)
                    Circle().fill(Color(hex: 0x9EA398)).frame(width: hub, height: hub)
                        .position(x: vanX + vanW * 0.3, y: wheelY)
                }
            }
            .frame(width: w, height: h)
        }
    }
}

// MARK: - By (København i skumring, lys og blød)

struct ScnCityScene: View {
    private let xs: [CGFloat] = [0.05, 0.16, 0.27, 0.5, 0.62, 0.74, 0.88, 0.98]
    private let ws: [CGFloat] = [0.12, 0.11, 0.12, 0.13, 0.11, 0.12, 0.13, 0.1]
    private let hs: [CGFloat] = [0.09, 0.12, 0.08, 0.1, 0.13, 0.08, 0.11, 0.09]
    private let gables: [Bool] = [true, false, true, true, false, true, false, true]

    var body: some View {
        GeometryReader { g in
            let w: CGFloat = g.size.width
            let h: CGFloat = g.size.height
            let waterTop: CGFloat = h * 0.56
            let quayTop: CGFloat = h * 0.7
            let spireX: CGFloat = w * 0.39
            let spireBase: CGFloat = waterTop - h * 0.12
            let roofColor: Color = Color(hex: 0xA899AE)
            ZStack {
                // himmel lavendel → fersken
                LinearGradient(colors: [Color(hex: 0xE2DBEC), Color(hex: 0xF1DCD6), Color(hex: 0xF7E3CF)],
                               startPoint: .top, endPoint: .bottom)

                // én langsomt blinkende stjerne
                ScnClock { t in
                    let a: Double = 0.45 + 0.35 * sin(t * 0.8)
                    Circle()
                        .fill(Color.white.opacity(a))
                        .frame(width: 4, height: 4)
                        .position(x: w * 0.82, y: h * 0.27)
                }

                // lav sol
                Circle()
                    .fill(Color(hex: 0xF6CDA9).opacity(0.7))
                    .frame(width: w * 0.22, height: w * 0.22)
                    .position(x: w * 0.68, y: waterTop - h * 0.1)

                // bagerste lyse række
                Rectangle()
                    .fill(Color(hex: 0xCDBFCF))
                    .frame(width: w, height: h * 0.07)
                    .position(x: w * 0.5, y: waterTop - h * 0.035)

                Group {
                    // snoet spir på tårn
                    ScnSpireShape()
                        .fill(roofColor)
                        .frame(width: w * 0.06, height: h * 0.14)
                        .position(x: spireX, y: spireBase - h * 0.07)
                    Rectangle()
                        .fill(roofColor)
                        .frame(width: w * 0.07, height: h * 0.12)
                        .position(x: spireX, y: spireBase + h * 0.06)
                }
                // tagrække
                ForEach(0..<8, id: \.self) { i in
                    let bw: CGFloat = w * ws[i]
                    let bh: CGFloat = h * hs[i]
                    let roof: CGFloat = gables[i] ? bw * 0.42 : 0
                    let total: CGFloat = bh + roof
                    let cy: CGFloat = waterTop - total * 0.5
                    ScnHouse(width: bw, height: bh, gable: gables[i], color: roofColor)
                        .position(x: w * xs[i], y: cy)
                }

                // få varme vinduer
                ForEach(0..<5, id: \.self) { i in
                    let wx: [CGFloat] = [0.15, 0.27, 0.5, 0.63, 0.87]
                    let wy: [CGFloat] = [0.06, 0.04, 0.05, 0.08, 0.06]
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(Color(hex: 0xF3C98A).opacity(0.9))
                        .frame(width: 6, height: 8)
                        .position(x: w * wx[i], y: waterTop - h * wy[i])
                }

                // havnevand
                Rectangle()
                    .fill(LinearGradient(colors: [Color(hex: 0xCBC4D8), Color(hex: 0xE5D7D6)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w, height: quayTop - waterTop)
                    .position(x: w * 0.5, y: waterTop + (quayTop - waterTop) * 0.5)

                Group {
                    // blød vandlinje / solrefleks
                    Capsule()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: w * 0.5, height: 3)
                        .position(x: w * 0.55, y: waterTop + h * 0.035)
                    Capsule()
                        .fill(Color(hex: 0xF6CDA9).opacity(0.45))
                        .frame(width: w * 0.16, height: 3)
                        .position(x: w * 0.68, y: waterTop + h * 0.07)
                }
                Group {
                    // kaj
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(hex: 0xE9DED0), Color(hex: 0xDED1C1)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: w, height: h - quayTop)
                        .position(x: w * 0.5, y: quayTop + (h - quayTop) * 0.5)
                    Rectangle()
                        .fill(Color(hex: 0xF3EBE0))
                        .frame(width: w, height: 5)
                        .position(x: w * 0.5, y: quayTop)
                }
            }
            .frame(width: w, height: h)
        }
    }
}
