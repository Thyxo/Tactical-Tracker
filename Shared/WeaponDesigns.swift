import SwiftUI
import UIKit

// Kodetegnede våben-skins til Våbenskabet (rene samlerobjekter, statiske illustrationer).
// Kontrakt (Docs/DRAWING_CONTRACT.md): vandret, mundingen mod højre (+x), greb/magasin nedad (+y),
// centreret i bounding box. Længde som andel af s: pistol 0.20, MP 0.40, riffel 0.60 (SR-25 0.66).
// Alle koordinater nedenfor er i enheder af s, relativt til centrum (venstre, top, højre, bund).

enum WeaponDesigns {
    /// Returnerer et tegnet våben for id, eller nil hvis id er ukendt.
    static func view(_ id: String, s: CGFloat) -> AnyView? {
        switch id {
        case "pistol_glock17": return AnyView(WpnGlock17View(s: s))
        case "pistol_p226": return AnyView(WpnP226View(s: s))
        case "pistol_usp": return AnyView(WpnUSPView(s: s))
        case "pistol_1911": return AnyView(Wpn1911View(s: s))
        case "pistol_deagle": return AnyView(WpnDeagleView(s: s))
        case "smg_mp5": return AnyView(WpnMP5View(s: s))
        case "smg_ump": return AnyView(WpnUMPView(s: s))
        case "smg_mp7": return AnyView(WpnMP7View(s: s))
        case "smg_vector": return AnyView(WpnVectorView(s: s))
        case "rifle_m4": return AnyView(WpnM4View(s: s))
        case "rifle_m10": return AnyView(WpnM10View(s: s))
        case "rifle_ak": return AnyView(WpnAKView(s: s))
        case "rifle_hk416": return AnyView(WpnHK416View(s: s))
        case "rifle_scar": return AnyView(WpnSCARView(s: s))
        case "rifle_sr25": return AnyView(WpnSR25View(s: s))
        default: return nil
        }
    }
}

// MARK: - Geometri og visning

enum WeaponGeometry {
    /// Våbnets længde som andel af s.
    static func length(_ c: GearCategory) -> CGFloat {
        switch c {
        case .pistol: return 0.20
        case .smg: return 0.40
        case .rifle: return 0.60
        default: return 0.25
        }
    }
}

/// Viser et våben skaleret til ca. 85 % af bredden `size` (museumsmontre).
struct WeaponDisplayView: View {
    let id: String
    let size: CGFloat

    private var scale: CGFloat {
        let cat: GearCategory = GearCatalog.item(id)?.category ?? .pistol
        let len: CGFloat = WeaponGeometry.length(cat)
        let target: CGFloat = size * 0.85
        return target / len
    }

    var body: some View {
        content
            .frame(width: size, height: size * 0.6)
    }

    @ViewBuilder
    private var content: some View {
        if let img = incomingImage("wpn_\(id)") {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.85, height: size * 0.55)
        } else if let v = WeaponDesigns.view(id, s: scale) {
            v
        } else {
            Image(systemName: "questionmark.square.dashed")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.white.opacity(0.4))
                .frame(width: size * 0.3, height: size * 0.3)
        }
    }
}

// MARK: - Farver

enum WpnC {
    static let body = Color(hex: 0x2C3136)
    static let dark = Color(hex: 0x1B1E21)
    static let deep = Color(hex: 0x111315)
    static let mid = Theme.metalLight
    static let steel = Color(hex: 0x4E565E)
    static let steelLight = Color(hex: 0x7C858E)
    static let akSteel = Color(hex: 0x33383D)
    static let blued = Color(hex: 0x3F4A58)
    static let bluedDark = Color(hex: 0x2B333D)
    static let wood = Color(hex: 0x8F5B33)
    static let woodDark = Color(hex: 0x6B4022)
    static let woodLight = Color(hex: 0xB27A49)
    static let plum = Color(hex: 0x6A3A2C)
    static let oliveDark = Color(hex: 0x4F5A37)
    static let coyoteDark = Color(hex: 0x846941)
    static let goldLight = Color(hex: 0xF7DC8A)
    static let goldDeep = Color(hex: 0x8A6420)
    static let vector = Color(hex: 0x575E66)
    static let glass = Color(hex: 0x4E8FB0)
    static let red = Color(hex: 0xE5484D)
    static let hi = Color.white.opacity(0.16)

    static var goldV: LinearGradient {
        LinearGradient(colors: [goldLight, Theme.gold, Theme.goldDark],
                       startPoint: .top, endPoint: .bottom)
    }
    static var goldGrip: LinearGradient {
        LinearGradient(colors: [Theme.gold, Theme.goldDark],
                       startPoint: .leading, endPoint: .trailing)
    }
}

// MARK: - Placering og byggeklodser

extension View {
    /// Placerer en del ud fra kanter (venstre, top, højre, bund) i enheder af s, relativt til centrum.
    func wpnAt(_ s: CGFloat, _ l: CGFloat, _ t: CGFloat, _ r: CGFloat, _ b: CGFloat) -> some View {
        let w: CGFloat = max((r - l) * s, 0.5)
        let h: CGFloat = max((b - t) * s, 0.5)
        let cx: CGFloat = (l + r) * 0.5 * s
        let cy: CGFloat = (t + b) * 0.5 * s
        return self.frame(width: w, height: h).offset(x: cx, y: cy)
    }
}

enum WpnK {
    static func box<S: ShapeStyle>(_ c: S, _ s: CGFloat, _ l: CGFloat, _ t: CGFloat,
                                   _ r: CGFloat, _ b: CGFloat, _ rad: CGFloat = 0.002) -> some View {
        let cr: CGFloat = rad * s
        return RoundedRectangle(cornerRadius: cr).fill(c).wpnAt(s, l, t, r, b)
    }

    static func poly<S: ShapeStyle>(_ c: S, _ pts: [CGFloat], _ s: CGFloat, _ l: CGFloat,
                                    _ t: CGFloat, _ r: CGFloat, _ b: CGFloat) -> some View {
        WpnPoly(pts: pts).fill(c).wpnAt(s, l, t, r, b)
    }

    static func outline(_ c: Color, _ pts: [CGFloat], _ lw: CGFloat, _ s: CGFloat, _ l: CGFloat,
                        _ t: CGFloat, _ r: CGFloat, _ b: CGFloat) -> some View {
        let w: CGFloat = lw * s
        let style = StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round)
        return WpnPoly(pts: pts).stroke(c, style: style).wpnAt(s, l, t, r, b)
    }

    static func hi(_ s: CGFloat, _ l: CGFloat, _ t: CGFloat, _ r: CGFloat, _ b: CGFloat) -> some View {
        box(WpnC.hi, s, l, t, r, b, 0.001)
    }

    static func notches(_ c: Color, _ n: Int, _ s: CGFloat, _ l: CGFloat, _ t: CGFloat,
                        _ r: CGFloat, _ b: CGFloat) -> some View {
        WpnNotches(n: n).fill(c).wpnAt(s, l, t, r, b)
    }

    static func guardShape(_ c: Color, _ lw: CGFloat, _ s: CGFloat, _ l: CGFloat, _ t: CGFloat,
                           _ r: CGFloat, _ b: CGFloat) -> some View {
        let w: CGFloat = lw * s
        let style = StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round)
        return WpnGuard().stroke(c, style: style).wpnAt(s, l, t, r, b)
    }

    static func dot<S: ShapeStyle>(_ c: S, _ s: CGFloat, _ l: CGFloat, _ t: CGFloat,
                                   _ r: CGFloat, _ b: CGFloat) -> some View {
        Ellipse().fill(c).wpnAt(s, l, t, r, b)
    }

    static func ring(_ c: Color, _ lw: CGFloat, _ s: CGFloat, _ l: CGFloat, _ t: CGFloat,
                     _ r: CGFloat, _ b: CGFloat) -> some View {
        let w: CGFloat = lw * s
        return Ellipse().stroke(c, lineWidth: w).wpnAt(s, l, t, r, b)
    }

    static func mag<S: ShapeStyle>(_ c: S, _ bend: CGFloat, _ s: CGFloat, _ l: CGFloat,
                                   _ t: CGFloat, _ r: CGFloat, _ b: CGFloat) -> some View {
        WpnBanana(bend: bend).fill(c).wpnAt(s, l, t, r, b)
    }
}

// MARK: - Former

/// Polygon med normaliserede punkter (x0, y0, x1, y1, ...) i 0...1.
struct WpnPoly: Shape {
    let pts: [CGFloat]

    func path(in r: CGRect) -> Path {
        var p = Path()
        let n: Int = pts.count / 2
        guard n > 1 else { return p }
        for i in 0..<n {
            let nx: CGFloat = pts[2 * i]
            let ny: CGFloat = pts[2 * i + 1]
            let px: CGFloat = r.minX + nx * r.width
            let py: CGFloat = r.minY + ny * r.height
            let pt = CGPoint(x: px, y: py)
            if i == 0 {
                p.move(to: pt)
            } else {
                p.addLine(to: pt)
            }
        }
        p.closeSubpath()
        return p
    }
}

/// Gentagne lodrette små hak (skinner, riller).
struct WpnNotches: Shape {
    let n: Int

    func path(in r: CGRect) -> Path {
        var p = Path()
        guard n > 0 else { return p }
        let step: CGFloat = r.width / CGFloat(n)
        let w: CGFloat = step * 0.5
        for i in 0..<n {
            let x0: CGFloat = r.minX + step * CGFloat(i)
            let x: CGFloat = x0 + step * 0.25
            p.addRect(CGRect(x: x, y: r.minY, width: w, height: r.height))
        }
        return p
    }
}

/// Aftrækkerbøjle (åben sti, tegnes med stroke). Bagende til venstre, front til højre.
struct WpnGuard: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let h: CGFloat = r.height
        let w: CGFloat = r.width
        let y0: CGFloat = r.minY + h * 0.7
        let x1: CGFloat = r.minX + w * 0.3
        let x2: CGFloat = r.maxX - w * 0.25
        let y3: CGFloat = r.minY + h * 0.5
        p.move(to: CGPoint(x: r.minX, y: y0))
        p.addQuadCurve(to: CGPoint(x: x1, y: r.maxY), control: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: x2, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: y3), control: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        return p
    }
}

/// Magasin der buer fremad (mod højre). bend 0 = lige.
struct WpnBanana: Shape {
    let bend: CGFloat

    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        let topW: CGFloat = w * (1 - bend)
        let topR: CGFloat = r.minX + topW
        let ctrlY: CGFloat = r.minY + h * 0.62
        let frontY: CGFloat = r.minY + h * 0.92
        let botL: CGFloat = r.maxX - topW * 0.95
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: topR, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: frontY), control: CGPoint(x: topR, y: ctrlY))
        p.addLine(to: CGPoint(x: botL, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY), control: CGPoint(x: r.minX, y: ctrlY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Pistoler (L = 0.20, H = 0.14)

struct WpnGlock17View: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            lower
            upper
            details
        }
        .frame(width: s * 0.20, height: s * 0.14)
    }

    private var lower: some View {
        ZStack {
            WpnK.box(WpnC.dark, s, -0.062, -0.020, 0.088, -0.004, 0.003)
            WpnK.poly(WpnC.dark, [0.18, 0, 1, 0, 0.85, 1, 0, 0.96], s, -0.097, -0.020, -0.042, 0.056)
            WpnK.box(WpnC.deep, s, -0.099, 0.050, -0.051, 0.057, 0.002)
            WpnK.guardShape(WpnC.dark, 0.006, s, -0.046, -0.006, -0.004, 0.024)
            WpnK.box(WpnC.mid, s, -0.032, -0.004, -0.027, 0.013, 0.001)
            WpnK.notches(WpnC.deep, 3, s, 0.045, -0.012, 0.082, -0.006)
        }
    }

    private var upper: some View {
        ZStack {
            WpnK.box(WpnC.body, s, -0.096, -0.048, 0.098, -0.018, 0.004)
            WpnK.box(WpnC.dark, s, -0.096, -0.022, 0.098, -0.018, 0.001)
            WpnK.hi(s, -0.090, -0.046, 0.092, -0.0435)
            WpnK.box(WpnC.deep, s, 0.000, -0.046, 0.034, -0.036, 0.001)
            WpnK.notches(WpnC.deep, 6, s, -0.090, -0.043, -0.068, -0.024)
            WpnK.box(WpnC.deep, s, 0.095, -0.042, 0.098, -0.024, 0.001)
        }
    }

    private var details: some View {
        ZStack {
            WpnK.box(WpnC.deep, s, 0.086, -0.053, 0.092, -0.047, 0.001)
            WpnK.box(WpnC.deep, s, -0.088, -0.054, -0.078, -0.047, 0.001)
            WpnK.box(WpnC.deep, s, -0.036, -0.016, -0.010, -0.012, 0.001)
            WpnK.box(WpnC.mid, s, 0.010, -0.015, 0.018, -0.011, 0.001)
        }
    }
}

struct WpnP226View: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            lower
            upper
            details
        }
        .frame(width: s * 0.20, height: s * 0.14)
    }

    private var lower: some View {
        ZStack {
            WpnK.poly(WpnC.deep, [0.3, 0, 1, 0.3, 1, 1, 0, 1], s, -0.100, -0.044, -0.088, -0.030)
            WpnK.box(WpnC.deep, s, -0.062, -0.020, 0.086, -0.004, 0.003)
            WpnK.poly(WpnC.deep, [0.2, 0, 1, 0, 0.82, 1, 0, 0.95], s, -0.098, -0.020, -0.040, 0.057)
            WpnK.poly(WpnC.dark, [0.3, 0.1, 0.88, 0.1, 0.74, 0.9, 0.1, 0.86], s, -0.098, -0.020, -0.040, 0.057)
            WpnK.guardShape(WpnC.deep, 0.0065, s, -0.046, -0.006, -0.002, 0.026)
            WpnK.box(WpnC.mid, s, -0.031, -0.005, -0.026, 0.014, 0.001)
            WpnK.box(WpnC.mid, s, -0.046, -0.017, -0.036, -0.013, 0.001)
        }
    }

    private var upper: some View {
        ZStack {
            WpnK.box(Color(hex: 0x2A2D31), s, -0.092, -0.049, 0.098, -0.018, 0.003)
            WpnK.poly(WpnC.dark, [0, 1, 0.7, 0, 1, 0, 1, 1], s, 0.070, -0.028, 0.098, -0.018)
            WpnK.hi(s, -0.086, -0.047, 0.092, -0.0445)
            WpnK.box(WpnC.deep, s, -0.006, -0.047, 0.036, -0.034, 0.001)
            WpnK.notches(WpnC.deep, 7, s, -0.088, -0.043, -0.062, -0.024)
            WpnK.box(WpnC.deep, s, 0.095, -0.044, 0.098, -0.026, 0.001)
        }
    }

    private var details: some View {
        ZStack {
            WpnK.box(WpnC.deep, s, 0.086, -0.054, 0.092, -0.048, 0.001)
            WpnK.box(WpnC.deep, s, -0.086, -0.055, -0.076, -0.048, 0.001)
            WpnK.box(WpnC.deep, s, -0.030, -0.016, -0.008, -0.012, 0.001)
            WpnK.dot(WpnC.mid, s, 0.012, -0.016, 0.018, -0.010)
        }
    }
}

struct WpnUSPView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            lower
            upper
            details
        }
        .frame(width: s * 0.20, height: s * 0.14)
    }

    private var lower: some View {
        ZStack {
            WpnK.box(WpnC.dark, s, -0.064, -0.022, 0.090, -0.004, 0.004)
            WpnK.poly(WpnC.dark, [0.2, 0, 1, 0, 0.84, 1, 0.02, 0.97], s, -0.098, -0.022, -0.040, 0.057)
            WpnK.poly(WpnC.deep, [0.3, 0.12, 0.86, 0.12, 0.74, 0.88, 0.12, 0.86], s, -0.098, -0.022, -0.040, 0.057)
            WpnK.box(WpnC.deep, s, -0.099, 0.051, -0.050, 0.058, 0.003)
            WpnK.guardShape(WpnC.dark, 0.0065, s, -0.046, -0.006, 0.000, 0.028)
            WpnK.box(WpnC.mid, s, -0.032, -0.005, -0.027, 0.014, 0.002)
            WpnK.box(WpnC.deep, s, 0.030, -0.010, 0.086, -0.004, 0.001)
            WpnK.notches(WpnC.body, 5, s, 0.032, -0.010, 0.084, -0.006)
        }
    }

    private var upper: some View {
        ZStack {
            WpnK.box(WpnC.body, s, -0.095, -0.049, 0.098, -0.020, 0.008)
            WpnK.box(WpnC.dark, s, -0.090, -0.024, 0.094, -0.020, 0.002)
            WpnK.hi(s, -0.086, -0.047, 0.088, -0.0445)
            WpnK.box(WpnC.deep, s, -0.002, -0.047, 0.034, -0.036, 0.002)
            WpnK.notches(WpnC.deep, 6, s, -0.088, -0.042, -0.066, -0.026)
            WpnK.box(WpnC.deep, s, 0.094, -0.042, 0.098, -0.028, 0.002)
        }
    }

    private var details: some View {
        ZStack {
            WpnK.box(WpnC.deep, s, 0.084, -0.054, 0.090, -0.048, 0.001)
            WpnK.box(WpnC.deep, s, -0.086, -0.055, -0.076, -0.048, 0.001)
            WpnK.box(WpnC.deep, s, -0.034, -0.018, -0.010, -0.014, 0.002)
            WpnK.box(WpnC.deep, s, -0.096, -0.040, -0.090, -0.030, 0.002)
        }
    }
}

struct Wpn1911View: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            lower
            grips
            upper
            details
        }
        .frame(width: s * 0.20, height: s * 0.14)
    }

    private var lower: some View {
        ZStack {
            WpnK.poly(WpnC.bluedDark, [0, 0, 0.7, 0.2, 1, 1, 0.4, 1], s, -0.100, -0.050, -0.090, -0.036)
            WpnK.poly(WpnC.bluedDark, [1, 0, 1, 1, 0, 0.55], s, -0.100, -0.024, -0.086, -0.010)
            WpnK.box(WpnC.bluedDark, s, -0.070, -0.020, 0.072, -0.006, 0.002)
            WpnK.poly(WpnC.bluedDark, [0.15, 0, 1, 0, 0.86, 1, 0, 0.97], s, -0.096, -0.020, -0.044, 0.058)
            WpnK.guardShape(WpnC.bluedDark, 0.006, s, -0.046, -0.008, -0.004, 0.022)
            WpnK.box(WpnC.steelLight, s, -0.040, -0.006, -0.034, 0.008, 0.001)
        }
    }

    private var grips: some View {
        ZStack {
            WpnK.poly(WpnC.wood, [0.25, 0.08, 0.92, 0.08, 0.8, 0.9, 0.12, 0.88], s, -0.096, -0.020, -0.044, 0.058)
            WpnK.poly(WpnC.woodDark, [0.3, 0.3, 0.84, 0.3, 0.78, 0.7, 0.24, 0.7], s, -0.096, -0.020, -0.044, 0.058)
            WpnK.poly(WpnC.woodLight.opacity(0.6), [0.25, 0.08, 0.92, 0.08, 0.91, 0.14, 0.25, 0.14], s, -0.096, -0.020, -0.044, 0.058)
            WpnK.dot(WpnC.steelLight, s, -0.077, -0.012, -0.072, -0.007)
            WpnK.dot(WpnC.steelLight, s, -0.083, 0.040, -0.078, 0.045)
        }
    }

    private var upper: some View {
        ZStack {
            WpnK.box(WpnC.blued, s, -0.094, -0.044, 0.098, -0.018, 0.002)
            WpnK.hi(s, -0.090, -0.0425, 0.094, -0.040)
            WpnK.box(WpnC.bluedDark, s, -0.094, -0.021, 0.098, -0.018, 0.001)
            WpnK.box(WpnC.steelLight, s, 0.091, -0.041, 0.098, -0.022, 0.002)
            WpnK.box(WpnC.deep, s, 0.000, -0.042, 0.028, -0.034, 0.001)
            WpnK.notches(WpnC.bluedDark, 8, s, -0.090, -0.040, -0.064, -0.024)
        }
    }

    private var details: some View {
        ZStack {
            WpnK.box(WpnC.bluedDark, s, 0.084, -0.049, 0.089, -0.043, 0.001)
            WpnK.box(WpnC.bluedDark, s, -0.086, -0.048, -0.076, -0.043, 0.001)
            WpnK.box(WpnC.bluedDark, s, -0.032, -0.016, -0.006, -0.012, 0.001)
            WpnK.dot(WpnC.steelLight, s, -0.010, -0.017, -0.004, -0.011)
        }
    }
}

struct WpnDeagleView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            lower
            slide
            barrel
            details
        }
        .frame(width: s * 0.20, height: s * 0.14)
    }

    private var lower: some View {
        ZStack {
            WpnK.poly(Theme.goldDark, [0.3, 0, 1, 0.3, 1, 1, 0, 1], s, -0.100, -0.046, -0.090, -0.032)
            WpnK.box(WpnC.goldGrip, s, -0.064, -0.018, 0.064, -0.002, 0.003)
            WpnK.poly(WpnC.goldGrip, [0.15, 0, 1, 0, 0.84, 1, 0, 0.96], s, -0.097, -0.018, -0.040, 0.060)
            WpnK.poly(WpnC.dark, [0.28, 0.1, 0.88, 0.1, 0.76, 0.9, 0.12, 0.88], s, -0.097, -0.018, -0.040, 0.060)
            WpnK.notches(WpnC.deep, 4, s, -0.084, 0.004, -0.058, 0.040)
            WpnK.guardShape(Theme.goldDark, 0.007, s, -0.044, -0.006, 0.000, 0.026)
            WpnK.box(WpnC.dark, s, -0.030, -0.004, -0.024, 0.014, 0.001)
        }
    }

    private var slide: some View {
        ZStack {
            WpnK.box(WpnC.goldV, s, -0.096, -0.052, 0.012, -0.016, 0.003)
            WpnK.box(WpnC.goldLight.opacity(0.7), s, -0.090, -0.050, 0.006, -0.0475, 0.001)
            WpnK.box(WpnC.goldDeep, s, -0.032, -0.050, -0.002, -0.038, 0.001)
            WpnK.notches(Theme.goldDark, 6, s, -0.090, -0.046, -0.066, -0.022)
        }
    }

    private var barrel: some View {
        ZStack {
            WpnK.poly(WpnC.goldV, [0, 0, 1, 0, 1, 0.62, 0.55, 1, 0, 1], s, 0.008, -0.054, 0.100, -0.014)
            WpnK.box(Theme.goldDark, s, 0.014, -0.058, 0.098, -0.053, 0.001)
            WpnK.notches(WpnC.goldDeep, 8, s, 0.016, -0.058, 0.096, -0.055)
            WpnK.poly(Theme.goldDark.opacity(0.55), [0, 0, 1, 0, 0.7, 1, 0, 1], s, 0.030, -0.044, 0.086, -0.030)
            WpnK.box(WpnC.goldLight.opacity(0.7), s, 0.014, -0.0525, 0.094, -0.050, 0.001)
            WpnK.box(WpnC.goldDeep, s, 0.096, -0.050, 0.100, -0.032, 0.001)
        }
    }

    private var details: some View {
        ZStack {
            WpnK.box(WpnC.goldDeep, s, 0.090, -0.062, 0.095, -0.057, 0.001)
            WpnK.box(WpnC.goldDeep, s, -0.088, -0.057, -0.078, -0.051, 0.001)
            WpnK.box(Theme.goldDark, s, -0.036, -0.014, -0.012, -0.010, 0.001)
        }
    }
}

// MARK: - Maskinpistoler (L = 0.40, H = 0.20)

struct WpnMP5View: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            stock
            lower
            receiver
            front
        }
        .frame(width: s * 0.40, height: s * 0.20)
    }

    private var stock: some View {
        ZStack {
            WpnK.box(WpnC.dark, s, -0.185, -0.030, -0.075, -0.024, 0.002)
            WpnK.box(WpnC.dark, s, -0.185, -0.010, -0.075, -0.004, 0.002)
            WpnK.box(WpnC.body, s, -0.198, -0.040, -0.180, 0.012, 0.006)
            WpnK.box(WpnC.deep, s, -0.200, -0.040, -0.194, 0.012, 0.002)
            WpnK.box(WpnC.body, s, -0.090, -0.034, -0.072, 0.004, 0.003)
        }
    }

    private var lower: some View {
        ZStack {
            WpnK.poly(WpnC.dark, [0, 0, 1, 0, 1, 1, 0.1, 1], s, -0.060, -0.004, 0.026, 0.014)
            WpnK.poly(WpnC.dark, [0.3, 0, 1, 0, 0.72, 1, 0, 0.96], s, -0.052, 0.008, -0.010, 0.080)
            WpnK.guardShape(WpnC.dark, 0.006, s, -0.012, 0.010, 0.026, 0.036)
            WpnK.box(WpnC.mid, s, 0.002, 0.012, 0.007, 0.028, 0.001)
            WpnK.mag(WpnC.deep, 0.35, s, 0.033, 0.010, 0.090, 0.096)
            WpnK.box(WpnC.body, s, 0.030, -0.004, 0.066, 0.016, 0.002)
            WpnK.dot(WpnC.mid, s, -0.050, -0.014, -0.042, -0.006)
        }
    }

    private var receiver: some View {
        ZStack {
            WpnK.box(WpnC.body, s, -0.080, -0.036, 0.102, -0.002, 0.006)
            WpnK.hi(s, -0.074, -0.034, 0.096, -0.031)
            WpnK.box(WpnC.deep, s, -0.005, -0.026, 0.035, -0.016, 0.002)
            WpnK.box(WpnC.body, s, -0.066, -0.050, -0.046, -0.034, 0.003)
            WpnK.dot(WpnC.deep, s, -0.060, -0.046, -0.052, -0.038)
            WpnK.box(WpnC.body, s, 0.100, -0.034, 0.152, -0.020, 0.004)
            WpnK.box(WpnC.dark, s, 0.118, -0.042, 0.126, -0.030, 0.002)
        }
    }

    private var front: some View {
        ZStack {
            WpnK.poly(WpnC.dark, [0, 0, 1, 0.12, 0.95, 0.85, 0.15, 1], s, 0.098, -0.022, 0.168, 0.016)
            WpnK.hi(s, 0.104, -0.019, 0.160, -0.017)
            WpnK.box(WpnC.deep, s, 0.150, -0.022, 0.196, -0.012, 0.001)
            WpnK.box(WpnC.dark, s, 0.186, -0.025, 0.200, -0.009, 0.002)
            WpnK.box(WpnC.body, s, 0.162, -0.040, 0.176, -0.018, 0.002)
            WpnK.ring(WpnC.body, 0.004, s, 0.158, -0.058, 0.180, -0.036)
            WpnK.box(WpnC.deep, s, 0.168, -0.052, 0.170, -0.042, 0.0005)
        }
    }
}

struct WpnUMPView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            stock
            lower
            receiver
            front
        }
        .frame(width: s * 0.40, height: s * 0.20)
    }

    private var stock: some View {
        ZStack {
            WpnK.outline(WpnC.dark, [1, 0, 0.08, 0.05, 0, 0.95, 0.12, 1, 1, 0.55], 0.008, s, -0.190, -0.032, -0.088, 0.018)
            WpnK.box(WpnC.deep, s, -0.198, -0.038, -0.186, 0.024, 0.003)
            WpnK.box(WpnC.body, s, -0.096, -0.034, -0.082, 0.004, 0.002)
        }
    }

    private var lower: some View {
        ZStack {
            WpnK.poly(WpnC.body, [0.32, 0, 1, 0, 0.74, 1, 0, 0.96], s, -0.060, 0.000, -0.018, 0.080)
            WpnK.guardShape(WpnC.body, 0.007, s, -0.022, 0.004, 0.026, 0.036)
            WpnK.box(WpnC.mid, s, -0.010, 0.006, -0.005, 0.022, 0.001)
            WpnK.poly(WpnC.dark, [0, 0, 0.78, 0, 1, 1, 0.22, 1], s, 0.028, 0.018, 0.074, 0.096)
            WpnK.box(WpnC.deep, s, 0.040, 0.090, 0.076, 0.098, 0.002)
            WpnK.box(WpnC.body, s, 0.024, 0.000, 0.064, 0.026, 0.002)
            WpnK.dot(WpnC.mid, s, -0.054, -0.012, -0.046, -0.004)
        }
    }

    private var receiver: some View {
        ZStack {
            WpnK.box(WpnC.body, s, -0.086, -0.036, 0.120, 0.004, 0.003)
            WpnK.poly(WpnC.body, [0, 0, 1, 0, 0.8, 1, 0, 1], s, 0.040, 0.000, 0.120, 0.022)
            WpnK.box(WpnC.dark, s, -0.080, -0.044, 0.112, -0.036, 0.001)
            WpnK.notches(WpnC.deep, 18, s, -0.078, -0.044, 0.110, -0.039)
            WpnK.hi(s, -0.082, -0.034, 0.116, -0.031)
            WpnK.box(WpnC.deep, s, -0.010, -0.030, 0.030, -0.020, 0.001)
            WpnK.box(WpnC.dark, s, 0.070, 0.010, 0.112, 0.018, 0.001)
            WpnK.notches(WpnC.deep, 5, s, 0.072, 0.010, 0.110, 0.015)
            WpnK.box(WpnC.dark, s, 0.088, -0.032, 0.102, -0.024, 0.002)
        }
    }

    private var front: some View {
        ZStack {
            WpnK.box(WpnC.deep, s, 0.120, -0.022, 0.168, -0.010, 0.001)
            WpnK.box(WpnC.dark, s, 0.160, -0.025, 0.176, -0.007, 0.002)
            WpnK.box(WpnC.dark, s, -0.074, -0.054, -0.062, -0.044, 0.001)
            WpnK.box(WpnC.dark, s, 0.098, -0.054, 0.110, -0.044, 0.001)
        }
    }
}

struct WpnMP7View: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            stock
            lower
            receiver
            optic
        }
        .frame(width: s * 0.40, height: s * 0.20)
    }

    private var stock: some View {
        ZStack {
            WpnK.box(WpnC.dark, s, -0.190, -0.022, -0.060, -0.017, 0.002)
            WpnK.box(WpnC.dark, s, -0.190, -0.006, -0.060, -0.001, 0.002)
            WpnK.box(WpnC.body, s, -0.200, -0.032, -0.184, 0.010, 0.004)
            WpnK.box(WpnC.deep, s, -0.200, -0.032, -0.195, 0.010, 0.002)
            WpnK.box(WpnC.dark, s, -0.080, -0.034, -0.060, 0.004, 0.002)
        }
    }

    private var lower: some View {
        ZStack {
            WpnK.poly(WpnC.body, [0.35, 0, 1, 0, 0.72, 1, 0, 0.95], s, -0.030, 0.004, 0.020, 0.072)
            WpnK.box(WpnC.deep, s, -0.031, 0.068, 0.008, 0.090, 0.003)
            WpnK.guardShape(WpnC.body, 0.006, s, 0.016, 0.006, 0.056, 0.032)
            WpnK.box(WpnC.mid, s, 0.030, 0.010, 0.035, 0.024, 0.001)
            WpnK.poly(WpnC.dark, [0, 0, 1, 0, 0.9, 1, 0.1, 1], s, 0.064, 0.006, 0.112, 0.020)
            WpnK.dot(WpnC.mid, s, -0.022, -0.012, -0.014, -0.004)
        }
    }

    private var receiver: some View {
        ZStack {
            WpnK.poly(WpnC.body, [0, 0, 1, 0, 1, 0.6, 0.85, 1, 0, 1], s, -0.070, -0.040, 0.120, 0.008)
            WpnK.box(WpnC.dark, s, -0.060, -0.048, 0.112, -0.040, 0.001)
            WpnK.notches(WpnC.deep, 16, s, -0.058, -0.048, 0.110, -0.043)
            WpnK.hi(s, -0.066, -0.038, 0.116, -0.035)
            WpnK.box(WpnC.deep, s, 0.010, -0.032, 0.050, -0.022, 0.001)
            WpnK.box(WpnC.dark, s, 0.070, -0.016, 0.116, -0.008, 0.001)
            WpnK.box(WpnC.deep, s, 0.118, -0.026, 0.168, -0.016, 0.001)
            WpnK.box(WpnC.dark, s, 0.160, -0.028, 0.174, -0.014, 0.002)
        }
    }

    private var optic: some View {
        ZStack {
            WpnK.box(WpnC.dark, s, 0.000, -0.054, 0.030, -0.046, 0.001)
            WpnK.box(WpnC.dark, s, -0.010, -0.074, 0.040, -0.052, 0.004)
            WpnK.box(WpnC.glass, s, 0.035, -0.070, 0.040, -0.056, 0.001)
            WpnK.hi(s, -0.006, -0.072, 0.034, -0.0695)
            WpnK.box(WpnC.dark, s, -0.054, -0.058, -0.044, -0.048, 0.001)
        }
    }
}

struct WpnVectorView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            stock
            lower
            receiver
            front
        }
        .frame(width: s * 0.40, height: s * 0.20)
    }

    private var stock: some View {
        ZStack {
            WpnK.outline(WpnC.dark, [1, 0, 0, 0.1, 0, 1, 1, 0.7], 0.008, s, -0.188, -0.040, -0.082, 0.010)
            WpnK.box(WpnC.deep, s, -0.200, -0.046, -0.186, 0.018, 0.003)
            WpnK.box(WpnC.dark, s, -0.092, -0.042, -0.074, 0.000, 0.002)
        }
    }

    private var lower: some View {
        ZStack {
            WpnK.poly(WpnC.dark, [0.3, 0, 1, 0, 0.72, 1, 0, 0.96], s, -0.052, -0.004, -0.010, 0.072)
            WpnK.guardShape(WpnC.dark, 0.006, s, -0.016, -0.004, 0.004, 0.026)
            WpnK.box(WpnC.mid, s, -0.008, -0.002, -0.004, 0.014, 0.001)
            WpnK.box(WpnC.dark, s, 0.010, 0.034, 0.046, 0.094, 0.002)
            WpnK.box(WpnC.deep, s, 0.008, 0.090, 0.048, 0.098, 0.002)
        }
    }

    private var receiver: some View {
        ZStack {
            WpnK.poly(WpnC.vector, [0, 0, 1, 0, 1, 0.3, 0.62, 1, 0.35, 1, 0.3, 0.5, 0, 0.5], s, -0.078, -0.046, 0.140, 0.040)
            WpnK.poly(WpnC.dark.opacity(0.55), [0.55, 0, 1, 0, 0.45, 1, 0, 1], s, 0.030, -0.010, 0.120, 0.034)
            WpnK.box(WpnC.dark, s, -0.078, -0.058, 0.130, -0.046, 0.001)
            WpnK.notches(WpnC.deep, 18, s, -0.076, -0.058, 0.128, -0.051)
            WpnK.box(Theme.gold, s, -0.072, -0.042, 0.134, -0.039, 0.001)
            WpnK.box(WpnC.deep, s, 0.030, -0.034, 0.100, -0.030, 0.001)
            WpnK.box(WpnC.deep, s, -0.040, -0.030, -0.004, -0.018, 0.001)
            WpnK.dot(WpnC.mid, s, -0.064, -0.026, -0.056, -0.018)
        }
    }

    private var front: some View {
        ZStack {
            WpnK.box(WpnC.dark, s, 0.138, -0.034, 0.180, -0.010, 0.003)
            WpnK.notches(WpnC.deep, 4, s, 0.144, -0.028, 0.174, -0.016)
            WpnK.box(WpnC.deep, s, 0.178, -0.026, 0.200, -0.018, 0.001)
            WpnK.box(WpnC.dark, s, -0.068, -0.068, -0.056, -0.058, 0.001)
            WpnK.box(WpnC.dark, s, 0.114, -0.068, 0.126, -0.058, 0.001)
        }
    }
}

// MARK: - Rifler (L = 0.60, H = 0.27)

/// Fælles AR-platform (M4, M/10, HK416).
/// optic: 0 = kompakt prisme, 1 = rødpunkt-rør, 2 = holografisk.
struct WpnARView: View {
    let s: CGFloat
    let furn: Color
    let furnDark: Color
    let grip: Color
    let magColor: Color
    let longRail: Bool
    let frontPost: Bool
    let foregrip: Bool
    let optic: Int

    var body: some View {
        ZStack {
            stock
            lower
            receiver
            handguard
            barrel
            opticView
        }
        .frame(width: s * 0.60, height: s * 0.27)
    }

    private var hgEnd: CGFloat { longRail ? 0.205 : 0.170 }

    private var stock: some View {
        ZStack {
            WpnK.box(WpnC.dark, s, -0.230, -0.036, -0.105, -0.020, 0.003)
            WpnK.poly(furn, [0, 0, 1, 0.15, 1, 0.55, 0, 1], s, -0.290, -0.046, -0.180, 0.022)
            WpnK.poly(furnDark, [0.15, 0.55, 0.85, 0.38, 0.85, 0.5, 0.15, 0.78], s, -0.290, -0.046, -0.180, 0.022)
            WpnK.hi(s, -0.286, -0.044, -0.184, -0.041)
            WpnK.box(WpnC.deep, s, -0.300, -0.048, -0.288, 0.024, 0.003)
        }
    }

    private var lower: some View {
        ZStack {
            WpnK.poly(grip, [0.38, 0, 1, 0, 0.66, 1, 0, 0.94], s, -0.098, 0.008, -0.050, 0.090)
            WpnK.guardShape(WpnC.body, 0.007, s, -0.054, 0.014, -0.016, 0.042)
            WpnK.box(WpnC.mid, s, -0.040, 0.016, -0.035, 0.034, 0.001)
            WpnK.mag(magColor, 0.30, s, -0.017, 0.034, 0.050, 0.128)
            WpnK.poly(WpnC.body, [0, 0, 1, 0, 1, 1, 0.72, 1, 0.62, 0.45, 0, 0.45], s, -0.110, -0.014, 0.036, 0.040)
            WpnK.dot(WpnC.mid, s, -0.094, -0.008, -0.084, 0.002)
        }
    }

    private var receiver: some View {
        ZStack {
            WpnK.box(WpnC.body, s, -0.115, -0.044, 0.042, -0.012, 0.003)
            WpnK.box(WpnC.dark, s, -0.110, -0.052, 0.040, -0.044, 0.001)
            WpnK.notches(WpnC.deep, 12, s, -0.108, -0.052, 0.038, -0.047)
            WpnK.box(WpnC.dark, s, -0.128, -0.044, -0.114, -0.036, 0.001)
            WpnK.box(WpnC.deep, s, -0.050, -0.034, 0.000, -0.022, 0.001)
            WpnK.dot(WpnC.dark, s, -0.074, -0.036, -0.062, -0.024)
            WpnK.hi(s, -0.110, -0.042, 0.036, -0.039)
        }
    }

    @ViewBuilder
    private var handguard: some View {
        ZStack {
            WpnK.box(furn, s, 0.040, -0.046, hgEnd, -0.004, 0.004)
            WpnK.box(furnDark, s, 0.042, -0.052, hgEnd - 0.002, -0.046, 0.001)
            WpnK.notches(WpnC.deep, longRail ? 20 : 15, s, 0.044, -0.052, hgEnd - 0.004, -0.047)
            WpnK.notches(furnDark, longRail ? 8 : 6, s, 0.050, -0.034, hgEnd - 0.010, -0.018)
            WpnK.notches(furnDark, longRail ? 16 : 12, s, 0.046, -0.008, hgEnd - 0.006, -0.004)
            WpnK.hi(s, 0.044, -0.044, hgEnd - 0.004, -0.041)
            if foregrip {
                WpnK.poly(furn, [0, 0, 1, 0, 0.75, 1, 0.35, 1], s, 0.096, -0.006, 0.146, 0.046)
                WpnK.hi(s, 0.100, -0.002, 0.140, 0.001)
            }
        }
    }

    @ViewBuilder
    private var barrel: some View {
        ZStack {
            WpnK.box(WpnC.dark, s, hgEnd, -0.029, 0.272, -0.019, 0.001)
            WpnK.box(WpnC.dark, s, 0.268, -0.032, 0.300, -0.015, 0.002)
            WpnK.notches(WpnC.deep, 3, s, 0.274, -0.030, 0.296, -0.017)
            if frontPost {
                WpnK.poly(WpnC.dark, [0.3, 0, 0.7, 0, 1, 1, 0, 1], s, 0.168, -0.072, 0.190, -0.018)
                WpnK.box(WpnC.dark, s, 0.170, -0.034, 0.188, -0.014, 0.002)
            } else {
                WpnK.box(WpnC.dark, s, hgEnd - 0.016, -0.064, hgEnd - 0.004, -0.050, 0.001)
                WpnK.box(WpnC.dark, s, -0.104, -0.062, -0.092, -0.052, 0.001)
            }
        }
    }

    @ViewBuilder
    private var opticView: some View {
        switch optic {
        case 0:
            ZStack {
                WpnK.box(WpnC.dark, s, -0.072, -0.060, -0.024, -0.052, 0.001)
                WpnK.box(WpnC.body, s, -0.086, -0.082, -0.016, -0.058, 0.004)
                WpnK.poly(WpnC.dark, [0, 0.12, 1, 0, 1, 1, 0, 0.88], s, -0.022, -0.086, 0.004, -0.054)
                WpnK.box(WpnC.glass, s, 0.001, -0.083, 0.005, -0.057, 0.001)
                WpnK.box(WpnC.dark, s, -0.056, -0.090, -0.042, -0.082, 0.001)
                WpnK.hi(s, -0.082, -0.080, -0.020, -0.077)
            }
        case 1:
            ZStack {
                WpnK.box(WpnC.dark, s, -0.062, -0.060, -0.030, -0.052, 0.001)
                WpnK.box(WpnC.dark, s, -0.074, -0.088, -0.018, -0.060, 0.006)
                WpnK.box(WpnC.deep, s, -0.024, -0.091, -0.012, -0.057, 0.002)
                WpnK.box(WpnC.dark, s, -0.052, -0.096, -0.040, -0.088, 0.001)
                WpnK.box(WpnC.glass, s, -0.013, -0.086, -0.009, -0.062, 0.001)
                WpnK.dot(WpnC.red, s, -0.080, -0.077, -0.073, -0.071)
                WpnK.hi(s, -0.070, -0.086, -0.026, -0.083)
            }
        default:
            ZStack {
                WpnK.box(WpnC.dark, s, -0.082, -0.064, -0.008, -0.052, 0.003)
                WpnK.box(WpnC.dark, s, -0.082, -0.076, -0.044, -0.062, 0.003)
                WpnK.box(WpnC.dark, s, -0.042, -0.094, -0.008, -0.062, 0.003)
                WpnK.box(WpnC.glass.opacity(0.7), s, -0.038, -0.090, -0.012, -0.068, 0.002)
                WpnK.dot(WpnC.red, s, -0.027, -0.081, -0.023, -0.077)
                WpnK.hi(s, -0.078, -0.074, -0.048, -0.071)
            }
        }
    }
}

struct WpnM4View: View {
    let s: CGFloat

    var body: some View {
        WpnARView(s: s, furn: WpnC.dark, furnDark: WpnC.deep, grip: WpnC.dark,
                  magColor: Color(hex: 0x30353A), longRail: false, frontPost: true,
                  foregrip: false, optic: 0)
    }
}

struct WpnM10View: View {
    let s: CGFloat

    var body: some View {
        WpnARView(s: s, furn: Theme.olive, furnDark: WpnC.oliveDark, grip: Theme.olive,
                  magColor: WpnC.dark, longRail: false, frontPost: false,
                  foregrip: false, optic: 1)
    }
}

struct WpnHK416View: View {
    let s: CGFloat

    var body: some View {
        WpnARView(s: s, furn: Theme.coyote, furnDark: WpnC.coyoteDark, grip: Theme.coyote,
                  magColor: Theme.coyote, longRail: true, frontPost: false,
                  foregrip: true, optic: 2)
    }
}

struct WpnAKView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            stock
            lower
            receiver
            handguard
            barrel
        }
        .frame(width: s * 0.60, height: s * 0.27)
    }

    private var stock: some View {
        ZStack {
            WpnK.poly(WpnC.wood, [0, 0.29, 1, 0.04, 1, 0.41, 0.6, 0.62, 0, 0.97], s, -0.296, -0.028, -0.120, 0.052)
            WpnK.poly(WpnC.woodLight.opacity(0.55), [0, 0.29, 1, 0.04, 1, 0.1, 0, 0.35], s, -0.296, -0.028, -0.120, 0.052)
            WpnK.poly(WpnC.woodDark.opacity(0.6), [0.1, 0.5, 0.8, 0.3, 0.8, 0.36, 0.1, 0.58], s, -0.296, -0.028, -0.120, 0.052)
            WpnK.box(WpnC.dark, s, -0.300, -0.006, -0.292, 0.050, 0.002)
        }
    }

    private var lower: some View {
        ZStack {
            WpnK.poly(WpnC.plum, [0.35, 0, 1, 0, 0.66, 1, 0, 0.94], s, -0.100, 0.002, -0.058, 0.080)
            WpnK.guardShape(WpnC.akSteel, 0.006, s, -0.064, 0.004, -0.018, 0.030)
            WpnK.box(WpnC.mid, s, -0.046, 0.008, -0.041, 0.024, 0.001)
            WpnK.mag(WpnC.plum, 0.45, s, -0.016, 0.000, 0.080, 0.128)
            WpnK.notches(Color.black.opacity(0.25), 3, s, -0.006, 0.006, 0.030, 0.012)
        }
    }

    private var receiver: some View {
        ZStack {
            WpnK.box(WpnC.akSteel, s, -0.130, -0.032, 0.046, 0.006, 0.003)
            WpnK.box(Color(hex: 0x3C4248), s, -0.126, -0.038, 0.022, -0.026, 0.006)
            WpnK.hi(s, -0.120, -0.036, 0.016, -0.0335)
            WpnK.poly(WpnC.akSteel, [0, 1, 0.3, 0, 1, 0, 1, 1], s, 0.026, -0.046, 0.058, -0.030)
            WpnK.box(WpnC.deep, s, -0.040, -0.024, -0.004, -0.018, 0.001)
            WpnK.box(WpnC.dark, s, -0.096, -0.015, -0.014, -0.011, 0.001)
            WpnK.box(WpnC.steelLight, s, 0.000, -0.022, 0.014, -0.013, 0.003)
        }
    }

    private var handguard: some View {
        ZStack {
            WpnK.poly(WpnC.wood, [0, 0, 1, 0, 0.92, 1, 0, 1], s, 0.046, -0.026, 0.150, 0.012)
            WpnK.hi(s, 0.050, -0.024, 0.144, -0.021)
            WpnK.notches(WpnC.woodDark.opacity(0.6), 3, s, 0.070, 0.000, 0.120, 0.008)
            WpnK.box(WpnC.woodDark, s, 0.040, -0.044, 0.135, -0.026, 0.005)
            WpnK.box(WpnC.akSteel, s, 0.144, -0.028, 0.154, 0.012, 0.002)
        }
    }

    private var barrel: some View {
        ZStack {
            WpnK.box(WpnC.akSteel, s, 0.135, -0.042, 0.182, -0.032, 0.003)
            WpnK.box(WpnC.akSteel, s, 0.176, -0.046, 0.192, -0.016, 0.002)
            WpnK.box(WpnC.akSteel, s, 0.150, -0.026, 0.262, -0.016, 0.001)
            WpnK.box(WpnC.steel, s, 0.154, -0.016, 0.240, -0.013, 0.001)
            WpnK.poly(WpnC.akSteel, [0.2, 0, 0.8, 0, 1, 1, 0, 1], s, 0.228, -0.054, 0.250, -0.016)
            WpnK.box(WpnC.steel, s, 0.258, -0.029, 0.298, -0.013, 0.002)
            WpnK.notches(WpnC.deep, 2, s, 0.264, -0.027, 0.290, -0.015)
        }
    }
}

struct WpnSCARView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            stock
            lower
            receiver
            front
        }
        .frame(width: s * 0.60, height: s * 0.27)
    }

    private var stock: some View {
        ZStack {
            WpnK.poly(Theme.coyote, [0, 0, 1, 0.05, 1, 0.62, 0.42, 0.62, 0, 1], s, -0.290, -0.046, -0.132, 0.030)
            WpnK.poly(WpnC.coyoteDark, [0.12, 0.28, 0.76, 0.3, 0.76, 0.46, 0.12, 0.74], s, -0.290, -0.046, -0.132, 0.030)
            WpnK.box(Theme.coyote, s, -0.270, -0.054, -0.200, -0.042, 0.003)
            WpnK.hi(s, -0.268, -0.052, -0.204, -0.049)
            WpnK.box(WpnC.deep, s, -0.300, -0.050, -0.288, 0.032, 0.003)
            WpnK.box(WpnC.dark, s, -0.140, -0.044, -0.124, 0.002, 0.002)
        }
    }

    private var lower: some View {
        ZStack {
            WpnK.poly(WpnC.dark, [0.38, 0, 1, 0, 0.66, 1, 0, 0.94], s, -0.098, 0.008, -0.052, 0.090)
            WpnK.guardShape(WpnC.coyoteDark, 0.007, s, -0.056, 0.014, -0.016, 0.042)
            WpnK.box(WpnC.mid, s, -0.042, 0.016, -0.037, 0.034, 0.001)
            WpnK.mag(WpnC.dark, 0.12, s, -0.016, 0.040, 0.040, 0.118)
            WpnK.poly(WpnC.coyoteDark, [0, 0, 1, 0, 1, 1, 0.66, 1, 0.6, 0.4, 0, 0.4], s, -0.110, -0.008, 0.040, 0.044)
            WpnK.dot(WpnC.dark, s, -0.094, -0.004, -0.084, 0.006)
        }
    }

    private var receiver: some View {
        ZStack {
            WpnK.poly(Theme.coyote, [0, 0, 1, 0, 1, 0.62, 0.92, 1, 0, 1], s, -0.128, -0.048, 0.180, -0.006)
            WpnK.box(WpnC.dark, s, -0.124, -0.056, 0.176, -0.048, 0.001)
            WpnK.notches(WpnC.deep, 24, s, -0.122, -0.056, 0.174, -0.051)
            WpnK.hi(s, -0.124, -0.046, 0.176, -0.043)
            WpnK.box(WpnC.dark, s, 0.090, -0.030, 0.168, -0.020, 0.001)
            WpnK.notches(WpnC.deep, 6, s, 0.092, -0.030, 0.166, -0.024)
            WpnK.box(WpnC.coyoteDark, s, -0.050, -0.036, -0.005, -0.024, 0.001)
            WpnK.box(WpnC.dark, s, 0.030, -0.040, 0.046, -0.022, 0.003)
        }
    }

    private var front: some View {
        ZStack {
            WpnK.box(WpnC.dark, s, 0.180, -0.030, 0.266, -0.019, 0.001)
            WpnK.box(WpnC.dark, s, 0.262, -0.033, 0.300, -0.015, 0.002)
            WpnK.notches(WpnC.deep, 3, s, 0.268, -0.031, 0.296, -0.017)
            WpnK.box(WpnC.dark, s, 0.158, -0.068, 0.170, -0.056, 0.001)
            WpnK.box(WpnC.dark, s, -0.112, -0.068, -0.100, -0.056, 0.001)
        }
    }
}

struct WpnSR25View: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            stock
            lower
            receiver
            front
            bipod
            scopeMounts
            scope
        }
        .frame(width: s * 0.66, height: s * 0.30)
    }

    private var stock: some View {
        ZStack {
            WpnK.box(WpnC.dark, s, -0.200, -0.036, -0.110, -0.022, 0.003)
            WpnK.poly(WpnC.dark, [0, 0, 1, 0.12, 1, 0.5, 0.45, 0.55, 0, 1], s, -0.322, -0.050, -0.190, 0.038)
            WpnK.box(WpnC.body, s, -0.300, -0.060, -0.214, -0.048, 0.004)
            WpnK.hi(s, -0.296, -0.058, -0.218, -0.055)
            WpnK.box(WpnC.deep, s, -0.330, -0.054, -0.318, 0.040, 0.003)
            WpnK.dot(WpnC.mid, s, -0.262, -0.010, -0.250, 0.002)
        }
    }

    private var lower: some View {
        ZStack {
            WpnK.poly(WpnC.dark, [0.38, 0, 1, 0, 0.66, 1, 0, 0.94], s, -0.102, 0.008, -0.054, 0.090)
            WpnK.guardShape(WpnC.body, 0.007, s, -0.058, 0.014, -0.020, 0.042)
            WpnK.box(WpnC.mid, s, -0.044, 0.016, -0.039, 0.034, 0.001)
            WpnK.mag(WpnC.dark, 0.08, s, -0.019, 0.034, 0.040, 0.104)
            WpnK.poly(WpnC.body, [0, 0, 1, 0, 1, 1, 0.72, 1, 0.62, 0.45, 0, 0.45], s, -0.115, -0.014, 0.036, 0.040)
            WpnK.dot(WpnC.mid, s, -0.098, -0.008, -0.088, 0.002)
        }
    }

    private var receiver: some View {
        ZStack {
            WpnK.box(WpnC.body, s, -0.120, -0.046, 0.044, -0.012, 0.003)
            WpnK.box(WpnC.body, s, 0.044, -0.046, 0.230, -0.006, 0.004)
            WpnK.box(WpnC.dark, s, -0.115, -0.054, 0.226, -0.046, 0.001)
            WpnK.notches(WpnC.deep, 30, s, -0.113, -0.054, 0.224, -0.049)
            WpnK.notches(WpnC.dark, 7, s, 0.060, -0.032, 0.220, -0.020)
            WpnK.hi(s, -0.114, -0.044, 0.226, -0.041)
            WpnK.box(WpnC.dark, s, -0.132, -0.046, -0.118, -0.038, 0.001)
            WpnK.box(WpnC.deep, s, -0.054, -0.036, -0.004, -0.024, 0.001)
            WpnK.dot(WpnC.dark, s, -0.078, -0.038, -0.066, -0.026)
        }
    }

    private var front: some View {
        ZStack {
            WpnK.box(WpnC.dark, s, 0.230, -0.031, 0.304, -0.021, 0.001)
            WpnK.box(WpnC.dark, s, 0.300, -0.035, 0.330, -0.017, 0.002)
            WpnK.notches(WpnC.deep, 3, s, 0.305, -0.033, 0.326, -0.019)
        }
    }

    private var bipod: some View {
        ZStack {
            WpnK.box(WpnC.dark, s, 0.100, -0.004, 0.212, 0.004, 0.003)
            WpnK.box(WpnC.body, s, 0.104, 0.004, 0.206, 0.010, 0.003)
            WpnK.dot(WpnC.deep, s, 0.202, -0.010, 0.222, 0.010)
            WpnK.box(WpnC.deep, s, 0.094, -0.006, 0.104, 0.012, 0.002)
        }
    }

    private var scopeMounts: some View {
        ZStack {
            WpnK.box(WpnC.dark, s, -0.090, -0.072, -0.074, -0.054, 0.001)
            WpnK.box(WpnC.dark, s, -0.010, -0.072, 0.006, -0.054, 0.001)
            WpnK.box(WpnC.dark, s, -0.092, -0.096, -0.072, -0.068, 0.003)
            WpnK.box(WpnC.dark, s, -0.012, -0.096, 0.008, -0.068, 0.003)
        }
    }

    private var scope: some View {
        ZStack {
            WpnK.box(WpnC.body, s, -0.130, -0.090, 0.060, -0.074, 0.004)
            WpnK.poly(WpnC.body, [0, 0, 1, 0.25, 1, 0.75, 0, 1], s, -0.170, -0.098, -0.128, -0.066)
            WpnK.poly(WpnC.body, [0, 0.3, 1, 0, 1, 1, 0, 0.7], s, 0.056, -0.104, 0.124, -0.060)
            WpnK.box(WpnC.glass, s, 0.120, -0.102, 0.126, -0.062, 0.002)
            WpnK.box(Theme.gold, s, 0.052, -0.095, 0.060, -0.069, 0.001)
            WpnK.box(WpnC.dark, s, -0.050, -0.112, -0.026, -0.088, 0.003)
            WpnK.notches(WpnC.mid, 4, s, -0.048, -0.112, -0.028, -0.102)
            WpnK.dot(WpnC.dark, s, -0.050, -0.092, -0.028, -0.072)
            WpnK.box(WpnC.dark, s, -0.122, -0.094, -0.104, -0.070, 0.002)
            WpnK.hi(s, -0.160, -0.088, 0.110, -0.085)
        }
    }
}
