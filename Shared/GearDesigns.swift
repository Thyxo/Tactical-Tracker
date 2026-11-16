import SwiftUI

// Kodetegnet udstyr til operatøren. Hver ting tegnes centreret i sit EGET koordinatsystem:
// visningens midtpunkt lægges på kategoriens ankerpunkt (se Docs/DRAWING_CONTRACT.md).
// Alle mål er andele af s. Flad "toy/vector"-stil med 2–3 toner pr. materiale.

enum GearDesigns {
    /// Drawn view for a gear id, or nil if this file doesn't draw it.
    static func view(_ id: String, s: CGFloat) -> AnyView? {
        switch id {
        // Hjelme
        case "helmet_fast": return AnyView(GearFastHelmetView(s: s))
        case "helmet_ach": return AnyView(GearAchHelmetView(s: s))
        case "helmet_pasgt": return AnyView(GearPasgtHelmetView(s: s))
        case "cap_swat": return AnyView(GearSwatCapView(s: s))
        case "beanie_watch": return AnyView(GearWatchCapView(s: s))
        case "boonie": return AnyView(GearBoonieView(s: s))
        case "helmet_exfil": return AnyView(GearExfilHelmetView(s: s))
        case "helmet_gold": return AnyView(GearGoldHelmetView(s: s))
        case "helmet_nisse": return AnyView(GearNisseCoverView(s: s))
        // Briller
        case "glasses_mframe": return AnyView(GearMFrameView(s: s))
        case "glasses_crossbow": return AnyView(GearCrossbowView(s: s))
        case "goggles_locust": return AnyView(GearLocustView(s: s))
        case "glasses_aviator": return AnyView(GearAviatorView(s: s))
        // Nattesyn
        case "nvg_pvs14": return AnyView(GearPvs14View(s: s))
        case "nvg_pvs31": return AnyView(GearPvs31View(s: s))
        case "nvg_gpnvg": return AnyView(GearGpnvgView(s: s))
        // Ansigt
        case "face_balaclava": return AnyView(GearBalaclavaView(s: s))
        case "face_shemagh": return AnyView(GearShemaghView(s: s))
        case "face_headset": return AnyView(GearHeadsetView(s: s))
        case "face_skull": return AnyView(GearSkullMaskView(s: s))
        // Veste
        case "vest_police": return AnyView(GearPoliceVestView(s: s))
        case "vest_swat": return AnyView(GearSwatVestView(s: s))
        case "vest_chestrig": return AnyView(GearChestRigView(s: s))
        case "vest_jpc": return AnyView(GearJpcVestView(s: s))
        case "vest_avs": return AnyView(GearAvsVestView(s: s))
        case "vest_gold": return AnyView(GearGoldVestView(s: s))
        // Tasker
        case "pouch_mags": return AnyView(GearMagPouchView(s: s))
        case "pouch_ifak": return AnyView(GearIfakView(s: s))
        case "pouch_light": return AnyView(GearFlashlightView(s: s))
        case "pouch_admin": return AnyView(GearAdminPanelView(s: s))
        case "pouch_radio": return AnyView(GearRadioView(s: s))
        // Patches
        case "patch_dk": return AnyView(GearPatchDKView(s: s))
        case "patch_swat": return AnyView(GearPatchSwatView(s: s))
        case "patch_blood": return AnyView(GearPatchBloodView(s: s))
        case "patch_ir": return AnyView(GearPatchIRView(s: s))
        case "patch_seal": return AnyView(GearPatchSealView(s: s))
        case "patch_kbh": return AnyView(GearPatchKbhView(s: s))
        case "patch_star": return AnyView(GearPatchStarView(s: s))
        default: return nil
        }
    }

    /// Ikon-tilpasning: skala k (ikon-s = size * k) og tegningens visuelle centrum (dx, dy) i andele af s.
    static func iconFit(_ id: String) -> (k: CGFloat, dx: CGFloat, dy: CGFloat) {
        switch id {
        case "boonie": return (2.0, 0, 0.01)
        case "helmet_nisse": return (1.9, 0.035, 0)
        case "helmet_gold": return (2.5, 0, -0.025)
        case "goggles_locust": return (2.7, 0, 0)
        case "nvg_pvs14": return (6.5, 0, 0)
        case "nvg_pvs31": return (5.5, 0, 0)
        case "nvg_gpnvg": return (4.0, 0, 0)
        case "face_balaclava": return (2.4, 0, -0.03)
        case "face_headset": return (2.3, 0, -0.07)
        case "face_shemagh": return (2.8, 0, 0.06)
        case "face_skull": return (3.2, 0, 0.042)
        case "vest_chestrig": return (2.2, 0, 0)
        case "pouch_mags": return (5.0, 0, 0)
        case "pouch_ifak": return (11.0, 0.11, 0.01)
        case "pouch_light": return (10.0, -0.115, 0.015)
        case "pouch_admin": return (7.5, 0, -0.09)
        case "pouch_radio": return (4.5, 0.13, -0.125)
        default: break
        }
        guard let cat = GearCatalog.item(id)?.category else { return (2.5, 0, 0) }
        switch cat {
        case .helmet: return (2.6, 0, 0)
        case .eyewear: return (3.2, 0, 0)
        case .nvg: return (4.5, 0, 0)
        case .face: return (2.4, 0, 0)
        case .vest: return (2.25, 0, 0)
        case .pouch: return (5.0, 0, 0)
        case .patch: return (11.0, 0, 0)
        default: return (2.5, 0, 0)
        }
    }
}

// MARK: - Ikon

struct GearIconView: View {
    let id: String
    let size: CGFloat

    var body: some View {
        let fit = GearDesigns.iconFit(id)
        let big: CGFloat = size * fit.k
        let ox: CGFloat = -fit.dx * big
        let oy: CGFloat = -fit.dy * big
        return Group {
            if let v = GearDesigns.view(id, s: big) {
                v.offset(x: ox, y: oy)
                    .frame(width: size, height: size)
                    .clipped()
            } else {
                Image(systemName: "questionmark.square.dashed")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Theme.textSoft)
                    .frame(width: size * 0.6, height: size * 0.6)
                    .frame(width: size, height: size)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Hjælpere

fileprivate func gearGrad(_ top: UInt32, _ bottom: UInt32) -> LinearGradient {
    LinearGradient(colors: [Color(hex: top), Color(hex: bottom)], startPoint: .top, endPoint: .bottom)
}

fileprivate func gearGrad3(_ top: UInt32, _ mid: UInt32, _ bottom: UInt32) -> LinearGradient {
    LinearGradient(colors: [Color(hex: top), Color(hex: mid), Color(hex: bottom)], startPoint: .top, endPoint: .bottom)
}

fileprivate func gearGradC(_ top: Color, _ bottom: Color) -> LinearGradient {
    LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
}

fileprivate func gearGoldGrad() -> LinearGradient {
    LinearGradient(colors: [Color(hex: 0xF8DE92), Theme.gold, Theme.goldDark], startPoint: .top, endPoint: .bottom)
}

extension View {
    /// Placér en del: størrelse (w, h) og forskydning (x, y) i andele af s, evt. drejet.
    fileprivate func gearAt(_ s: CGFloat, _ w: CGFloat, _ h: CGFloat,
                            _ x: CGFloat = 0, _ y: CGFloat = 0, _ deg: Double = 0) -> some View {
        self.frame(width: s * w, height: s * h)
            .rotationEffect(.degrees(deg))
            .offset(x: s * x, y: s * y)
    }
}

// MARK: - Former

/// Kuppel: øverste halvdel af en ellipse med flad bund.
struct GearDomeShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let k: CGFloat = 0.5523
        let rx: CGFloat = r.width / 2
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY),
                   control1: CGPoint(x: r.minX, y: r.maxY - r.height * k),
                   control2: CGPoint(x: r.midX - rx * k, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.maxY),
                   control1: CGPoint(x: r.midX + rx * k, y: r.minY),
                   control2: CGPoint(x: r.maxX, y: r.maxY - r.height * k))
        p.closeSubpath()
        return p
    }
}

/// Åben bue (øverste halvdel af ellipse) – til hovedbøjler og kindben.
struct GearArcShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let k: CGFloat = 0.5523
        let rx: CGFloat = r.width / 2
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY),
                   control1: CGPoint(x: r.minX, y: r.maxY - r.height * k),
                   control2: CGPoint(x: r.midX - rx * k, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.maxY),
                   control1: CGPoint(x: r.midX + rx * k, y: r.minY),
                   control2: CGPoint(x: r.maxX, y: r.maxY - r.height * k))
        return p
    }
}

/// Åben U-kurve fra øverste venstre til øverste højre hjørne med bund i maxY.
struct GearJawShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let cy: CGFloat = 2 * r.maxY - r.minY
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.midX, y: cy))
        return p
    }
}

/// Vandret linje gennem midten (til stiplede MOLLE-rækker).
struct GearHLineShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        return p
    }
}

/// Mikrofonarm: fra øverste venstre ned og ind mod nederste højre.
struct GearBoomShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.minX + r.width * 0.1, y: r.maxY))
        return p
    }
}

/// Hjelm set forfra med ørefrihed: `cut` = hvor højt siderne er skåret op (andel af højden).
struct GearHighCutShape: Shape {
    var cut: CGFloat = 0.4

    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        let sideY: CGFloat = r.maxY - h * cut
        let rise: CGFloat = (sideY - r.minY) * 0.5
        let rx: CGFloat = w * 0.5 * 0.5523
        p.move(to: CGPoint(x: r.minX, y: sideY))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY),
                   control1: CGPoint(x: r.minX, y: sideY - rise),
                   control2: CGPoint(x: r.midX - rx, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: sideY),
                   control1: CGPoint(x: r.midX + rx, y: r.minY),
                   control2: CGPoint(x: r.maxX, y: sideY - rise))
        p.addQuadCurve(to: CGPoint(x: r.maxX - w * 0.2, y: r.maxY),
                       control: CGPoint(x: r.maxX - w * 0.03, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + w * 0.2, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: sideY),
                       control: CGPoint(x: r.minX + w * 0.03, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// PASGT: rund kuppel der går lavt ned over ørerne, med højere pandekant.
struct GearPasgtShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        let k: CGFloat = 0.5523
        let rx: CGFloat = w * 0.5 * k
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY),
                   control1: CGPoint(x: r.minX, y: r.maxY - h * 0.6),
                   control2: CGPoint(x: r.midX - rx, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.maxY),
                   control1: CGPoint(x: r.midX + rx, y: r.minY),
                   control2: CGPoint(x: r.maxX, y: r.maxY - h * 0.6))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY - h * 0.17),
                       control: CGPoint(x: r.maxX - w * 0.16, y: r.maxY - h * 0.22))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY),
                       control: CGPoint(x: r.minX + w * 0.16, y: r.maxY - h * 0.22))
        p.closeSubpath()
        return p
    }
}

/// Kasketskygge set forfra.
struct GearBillShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX, y: r.minY + h * 0.25))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.25),
                       control: CGPoint(x: r.midX, y: r.minY - h * 0.2))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.25),
                       control: CGPoint(x: r.midX, y: r.maxY + h * 0.55))
        p.closeSubpath()
        return p
    }
}

/// Forreste del af en blød, hængende hatteskygge.
struct GearFloppyBrimShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX, y: r.minY + h * 0.6))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * 0.2, y: r.minY + h * 0.2),
                       control: CGPoint(x: r.minX + w * 0.06, y: r.minY + h * 0.2))
        p.addQuadCurve(to: CGPoint(x: r.maxX - w * 0.2, y: r.minY + h * 0.2),
                       control: CGPoint(x: r.midX, y: r.minY - h * 0.05))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.6),
                       control: CGPoint(x: r.maxX - w * 0.06, y: r.minY + h * 0.2))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.6),
                       control: CGPoint(x: r.midX, y: r.maxY + h * 0.45))
        p.closeSubpath()
        return p
    }
}

/// Kam på ceremonihjelmen (top i minY).
struct GearCrestShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY),
                       control: CGPoint(x: r.midX, y: r.minY - h))
        p.closeSubpath()
        return p
    }
}

/// Nisse-overtræk: kuppel i venstre 80 % og spids der hænger ned mod højre.
struct GearNisseShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.minX + w * 0.42, y: r.minY + h * 0.08),
                   control1: CGPoint(x: r.minX, y: r.minY + h * 0.4),
                   control2: CGPoint(x: r.minX + w * 0.16, y: r.minY + h * 0.08))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.62),
                   control1: CGPoint(x: r.minX + w * 0.70, y: r.minY + h * 0.06),
                   control2: CGPoint(x: r.maxX - w * 0.06, y: r.minY + h * 0.25))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * 0.74, y: r.minY + h * 0.50),
                       control: CGPoint(x: r.minX + w * 0.84, y: r.minY + h * 0.40))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * 0.80, y: r.maxY),
                       control: CGPoint(x: r.minX + w * 0.81, y: r.minY + h * 0.72))
        p.closeSubpath()
        return p
    }
}

/// Wraparound-glas med næseindhak.
struct GearWrapLensShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX, y: r.minY + h * 0.15))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.15),
                       control: CGPoint(x: r.midX, y: r.minY - h * 0.1))
        p.addQuadCurve(to: CGPoint(x: r.maxX - w * 0.12, y: r.maxY),
                       control: CGPoint(x: r.maxX, y: r.maxY - h * 0.1))
        p.addQuadCurve(to: CGPoint(x: r.midX + w * 0.07, y: r.maxY - h * 0.25),
                       control: CGPoint(x: r.midX + w * 0.2, y: r.maxY + h * 0.05))
        p.addQuadCurve(to: CGPoint(x: r.midX - w * 0.07, y: r.maxY - h * 0.25),
                       control: CGPoint(x: r.midX, y: r.minY + h * 0.35))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * 0.12, y: r.maxY),
                       control: CGPoint(x: r.midX - w * 0.2, y: r.maxY + h * 0.05))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.15),
                       control: CGPoint(x: r.minX, y: r.maxY - h * 0.1))
        p.closeSubpath()
        return p
    }
}

/// Kantet skjoldglas (ESS Crossbow).
struct GearShieldLensShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX + w * 0.02, y: r.minY + h * 0.08))
        p.addLine(to: CGPoint(x: r.midX - w * 0.05, y: r.minY + h * 0.08))
        p.addLine(to: CGPoint(x: r.midX, y: r.minY + h * 0.18))
        p.addLine(to: CGPoint(x: r.midX + w * 0.05, y: r.minY + h * 0.08))
        p.addLine(to: CGPoint(x: r.maxX - w * 0.02, y: r.minY + h * 0.08))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + h * 0.45))
        p.addQuadCurve(to: CGPoint(x: r.maxX - w * 0.14, y: r.maxY),
                       control: CGPoint(x: r.maxX - w * 0.02, y: r.maxY))
        p.addLine(to: CGPoint(x: r.midX + w * 0.18, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.midX + w * 0.06, y: r.maxY - h * 0.32),
                       control: CGPoint(x: r.midX + w * 0.11, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.midX - w * 0.06, y: r.maxY - h * 0.32),
                       control: CGPoint(x: r.midX, y: r.minY + h * 0.45))
        p.addQuadCurve(to: CGPoint(x: r.midX - w * 0.18, y: r.maxY),
                       control: CGPoint(x: r.midX - w * 0.11, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + w * 0.14, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.45),
                       control: CGPoint(x: r.minX + w * 0.02, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Afrundet goggle-form med næseindhak.
struct GearGoggleShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX + w * 0.1, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX - w * 0.1, y: r.minY),
                       control: CGPoint(x: r.midX, y: r.minY - h * 0.08))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.4),
                       control: CGPoint(x: r.maxX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX - w * 0.1, y: r.maxY),
                       control: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.midX + w * 0.1, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.midX - w * 0.1, y: r.maxY),
                       control: CGPoint(x: r.midX, y: r.minY + h * 0.3))
        p.addLine(to: CGPoint(x: r.minX + w * 0.1, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.4),
                       control: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * 0.1, y: r.minY),
                       control: CGPoint(x: r.minX, y: r.minY))
        p.closeSubpath()
        return p
    }
}

/// Dråbeformet pilotglas (højre glas set forfra; næsesiden er minX). Spejl med scaleEffect(x: -1).
struct GearTeardropShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX + w * 0.04, y: r.minY + h * 0.12))
        p.addQuadCurve(to: CGPoint(x: r.maxX - w * 0.06, y: r.minY + h * 0.04),
                       control: CGPoint(x: r.midX, y: r.minY - h * 0.02))
        p.addCurve(to: CGPoint(x: r.minX + w * 0.38, y: r.maxY),
                   control1: CGPoint(x: r.maxX + w * 0.04, y: r.minY + h * 0.35),
                   control2: CGPoint(x: r.maxX - w * 0.05, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.minX + w * 0.04, y: r.minY + h * 0.12),
                   control1: CGPoint(x: r.minX + w * 0.1, y: r.maxY),
                   control2: CGPoint(x: r.minX - w * 0.04, y: r.minY + h * 0.55))
        p.closeSubpath()
        return p
    }
}

/// Balaklava: hovedellipse med øjenspalte (fyld med eoFill).
struct GearBalaclavaShape: Shape {
    var slotTop: CGFloat = 0.5
    var slotBottom: CGFloat = 0.62
    var slotInset: CGFloat = 0.17

    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: r)
        let sx: CGFloat = r.minX + r.width * slotInset
        let sy: CGFloat = r.minY + r.height * slotTop
        let sw: CGFloat = r.width * (1 - 2 * slotInset)
        let sh: CGFloat = r.height * (slotBottom - slotTop)
        let corner: CGFloat = sh * 0.45
        p.addRoundedRect(in: CGRect(x: sx, y: sy, width: sw, height: sh),
                         cornerSize: CGSize(width: corner, height: corner))
        return p
    }
}

/// Tørklæde/maske over nedre ansigt: let buet overkant, U-formet bund.
struct GearScarfShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        p.move(to: CGPoint(x: r.minX + w * 0.03, y: r.minY + h * 0.12))
        p.addQuadCurve(to: CGPoint(x: r.maxX - w * 0.03, y: r.minY + h * 0.12),
                       control: CGPoint(x: r.midX, y: r.minY - h * 0.08))
        p.addCurve(to: CGPoint(x: r.midX, y: r.maxY),
                   control1: CGPoint(x: r.maxX, y: r.minY + h * 0.6),
                   control2: CGPoint(x: r.maxX - w * 0.2, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.minX + w * 0.03, y: r.minY + h * 0.12),
                   control1: CGPoint(x: r.minX + w * 0.2, y: r.maxY),
                   control2: CGPoint(x: r.minX, y: r.minY + h * 0.6))
        p.closeSubpath()
        return p
    }
}

/// Plate carrier / vest set forfra: skulderstropper, halsudskæring og ærmegab.
struct GearVestShape: Shape {
    var neckDepth: CGFloat = 0.16
    var strapOuter: CGFloat = 0.12
    var strapInner: CGFloat = 0.32
    var sideTop: CGFloat = 0.24
    var corner: CGFloat = 0.06

    func path(in r: CGRect) -> Path {
        var p = Path()
        let w: CGFloat = r.width
        let h: CGFloat = r.height
        let sideY: CGFloat = r.minY + h * sideTop
        let c: CGFloat = w * corner
        let neckCY: CGFloat = r.minY + h * neckDepth * 2
        p.move(to: CGPoint(x: r.minX, y: sideY))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * strapOuter, y: r.minY),
                       control: CGPoint(x: r.minX + w * strapOuter, y: sideY))
        p.addLine(to: CGPoint(x: r.minX + w * strapInner, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX - w * strapInner, y: r.minY),
                       control: CGPoint(x: r.midX, y: neckCY))
        p.addLine(to: CGPoint(x: r.maxX - w * strapOuter, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: sideY),
                       control: CGPoint(x: r.maxX - w * strapOuter, y: sideY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - c))
        p.addQuadCurve(to: CGPoint(x: r.maxX - c, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + c, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - c), control: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Simpel trekant med spidsen opad.
struct GearTriangleShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Femtakket stjerne.
struct GearStarShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let cx: CGFloat = r.midX
        let cy: CGFloat = r.midY + r.height * 0.04
        let outer: CGFloat = min(r.width, r.height) * 0.5
        let inner: CGFloat = outer * 0.45
        for i in 0..<10 {
            let rad: CGFloat = (i % 2 == 0) ? outer : inner
            let angle: Double = Double(i) * Double.pi / 5.0 - Double.pi / 2.0
            let px: CGFloat = cx + rad * CGFloat(cos(angle))
            let py: CGFloat = cy + rad * CGFloat(sin(angle))
            if i == 0 {
                p.move(to: CGPoint(x: px, y: py))
            } else {
                p.addLine(to: CGPoint(x: px, y: py))
            }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Fælles småting

/// Skinne på hjelmens side med tre slidser.
struct GearRailView: View {
    let s: CGFloat
    let top: UInt32
    let bottom: UInt32
    let slot: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.006).fill(gearGrad(top, bottom))
            VStack(spacing: s * 0.007) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule().fill(slot).frame(width: s * 0.011, height: s * 0.006)
                }
            }
        }
    }
}

/// Lille glans.
struct GearShine: View {
    let alpha: Double
    var body: some View {
        Capsule().fill(Color.white.opacity(alpha))
    }
}

/// Grønt nattesynsglas med ring.
struct GearNVLens: View {
    let s: CGFloat
    let d: CGFloat

    var body: some View {
        let outer: CGFloat = s * d
        let lens: CGFloat = s * d * 0.74
        let glow: CGFloat = s * d * 0.4
        let dot: CGFloat = s * d * 0.18
        let dotOff: CGFloat = -s * d * 0.14
        return ZStack {
            Circle().fill(gearGrad(0x15181B, 0x2A2F34)).frame(width: outer, height: outer)
            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0x8CF0A6), Color(hex: 0x2E8A4E), Color(hex: 0x123A22)],
                                     center: .center, startRadius: 0, endRadius: glow))
                .frame(width: lens, height: lens)
            Circle().fill(Color.white.opacity(0.55)).frame(width: dot, height: dot)
                .offset(x: dotOff, y: dotOff)
        }
    }
}

/// Spænde (guld eller plast).
struct GearBuckleView: View {
    let s: CGFloat
    let gold: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.005)
                .fill(gold ? gearGoldGrad() : gearGrad(0x3A4148, 0x1E2226))
            RoundedRectangle(cornerRadius: s * 0.002)
                .fill(Color(hex: 0x15181B).opacity(0.85))
                .frame(width: s * 0.022, height: s * 0.007)
        }
    }
}

// MARK: - Hjelme

struct GearFastHelmetView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            shell
            GearRailView(s: s, top: 0x5A636C, bottom: 0x353B41, slot: Color(hex: 0x14171A))
                .gearAt(s, 0.024, 0.056, -0.122, 0.0, -14)
            GearRailView(s: s, top: 0x5A636C, bottom: 0x353B41, slot: Color(hex: 0x14171A))
                .gearAt(s, 0.024, 0.056, 0.122, 0.0, 14)
            shroud
        }
        .frame(width: s * 0.36, height: s * 0.26)
    }

    private var shell: some View {
        ZStack {
            GearHighCutShape(cut: 0.42).fill(gearGrad3(0x5A6168, 0x40464C, 0x2A2E33))
            RoundedRectangle(cornerRadius: s * 0.006).fill(Color(hex: 0x6A727A).opacity(0.55))
                .gearAt(s, 0.075, 0.018, 0, -0.032)
            GearHighCutShape(cut: 0.42).stroke(Color(hex: 0x1A1D20), lineWidth: s * 0.004)
            GearShine(alpha: 0.16).gearAt(s, 0.07, 0.016, -0.07, -0.028, -24)
        }
        .frame(width: s * 0.29, height: s * 0.115)
        .clipShape(GearHighCutShape(cut: 0.42))
    }

    private var shroud: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.007).fill(gearGrad(0x2E3338, 0x16191C))
                .gearAt(s, 0.062, 0.032, 0, 0.026)
            RoundedRectangle(cornerRadius: s * 0.003).fill(Color(hex: 0x0B0D0F))
                .gearAt(s, 0.03, 0.009, 0, 0.026)
            Circle().fill(Color(hex: 0x5A636C)).gearAt(s, 0.006, 0.006, -0.022, 0.018)
            Circle().fill(Color(hex: 0x5A636C)).gearAt(s, 0.006, 0.006, 0.022, 0.018)
        }
    }
}

struct GearAchHelmetView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            shell
            RoundedRectangle(cornerRadius: s * 0.005).fill(gearGrad(0x3A4148, 0x1E2226))
                .gearAt(s, 0.042, 0.022, 0, 0.03)
            Circle().fill(Color(hex: 0x2B3020)).gearAt(s, 0.012, 0.012, -0.122, 0.022)
            Circle().fill(Color(hex: 0x2B3020)).gearAt(s, 0.012, 0.012, 0.122, 0.022)
        }
        .frame(width: s * 0.36, height: s * 0.26)
    }

    private var shell: some View {
        ZStack {
            GearHighCutShape(cut: 0.18).fill(gearGrad3(0x8A9867, 0x6E7B4F, 0x4E5836))
            GearHighCutShape(cut: 0.18).stroke(Color(hex: 0x353C25), lineWidth: s * 0.006)
            GearShine(alpha: 0.18).gearAt(s, 0.07, 0.016, -0.07, -0.03, -22)
        }
        .frame(width: s * 0.29, height: s * 0.118)
        .clipShape(GearHighCutShape(cut: 0.18))
    }
}

struct GearPasgtHelmetView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            shell.offset(y: s * 0.004)
        }
        .frame(width: s * 0.36, height: s * 0.26)
    }

    private var shell: some View {
        ZStack {
            GearPasgtShape().fill(gearGrad3(0x7A8052, 0x5F6540, 0x41462B))
            Ellipse().fill(Color(hex: 0x3B2F22).opacity(0.45)).gearAt(s, 0.06, 0.03, -0.07, -0.01, 20)
            Ellipse().fill(Color(hex: 0x2A2E1C).opacity(0.5)).gearAt(s, 0.07, 0.025, 0.05, -0.03, -15)
            Ellipse().fill(Color(hex: 0x9A8E62).opacity(0.4)).gearAt(s, 0.05, 0.022, 0.02, 0.02, 10)
            Ellipse().fill(Color(hex: 0x3B2F22).opacity(0.45)).gearAt(s, 0.05, 0.03, 0.12, 0.03, 30)
            Ellipse().fill(Color(hex: 0x2A2E1C).opacity(0.45)).gearAt(s, 0.05, 0.026, -0.12, 0.035, -30)
            RoundedRectangle(cornerRadius: s * 0.004).fill(Color(hex: 0x353A22))
                .gearAt(s, 0.31, 0.014, 0, 0.022)
            GearPasgtShape().stroke(Color(hex: 0x2E3220), lineWidth: s * 0.006)
            GearShine(alpha: 0.16).gearAt(s, 0.07, 0.016, -0.07, -0.038, -22)
        }
        .frame(width: s * 0.31, height: s * 0.13)
        .clipShape(GearPasgtShape())
    }
}

struct GearSwatCapView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            crown
            GearBillShape().fill(gearGrad(0x3E4349, 0x17191C))
                .gearAt(s, 0.25, 0.04, 0, 0.056)
            GearBillShape().stroke(Color.white.opacity(0.08), lineWidth: s * 0.002)
                .gearAt(s, 0.22, 0.03, 0, 0.056)
        }
        .frame(width: s * 0.36, height: s * 0.26)
    }

    private var crown: some View {
        ZStack {
            GearDomeShape().fill(gearGrad3(0x3A3F44, 0x25292D, 0x16191C))
            Rectangle().fill(Color.black.opacity(0.35)).gearAt(s, 0.003, 0.1, 0, 0)
            GearShine(alpha: 0.1).gearAt(s, 0.06, 0.014, -0.065, -0.02, -25)
            Text("SWAT")
                .font(.system(size: s * 0.03, weight: .heavy, design: .monospaced))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .fixedSize()
                .offset(y: s * 0.015)
        }
        .frame(width: s * 0.27, height: s * 0.1)
        .clipShape(GearDomeShape())
        .overlay(
            Circle().fill(Color(hex: 0x2A2E33)).frame(width: s * 0.014, height: s * 0.014)
                .offset(y: -s * 0.05)
        )
        .offset(y: -s * 0.005)
    }
}

struct GearWatchCapView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            dome
            cuff
        }
        .frame(width: s * 0.36, height: s * 0.26)
    }

    private var dome: some View {
        ZStack {
            GearDomeShape().fill(gearGrad3(0x3A4656, 0x2A3442, 0x1B222C))
            ForEach(0..<11, id: \.self) { i in
                domeRib(i)
            }
            GearShine(alpha: 0.1).gearAt(s, 0.06, 0.016, -0.06, -0.035, -25)
        }
        .frame(width: s * 0.28, height: s * 0.11)
        .clipShape(GearDomeShape())
        .offset(y: -s * 0.02)
    }

    private func domeRib(_ i: Int) -> some View {
        let x: CGFloat = CGFloat(i) * 0.025 - 0.125
        return Capsule().fill(Color.black.opacity(0.22)).gearAt(s, 0.004, 0.12, x, 0.01)
    }

    private var cuff: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.012).fill(gearGrad(0x3A4656, 0x222A35))
            ForEach(0..<15, id: \.self) { i in
                cuffRib(i)
            }
        }
        .frame(width: s * 0.29, height: s * 0.038)
        .clipShape(RoundedRectangle(cornerRadius: s * 0.012))
        .offset(y: s * 0.04)
    }

    private func cuffRib(_ i: Int) -> some View {
        let x: CGFloat = CGFloat(i) * 0.019 - 0.133
        return Capsule().fill(Color.black.opacity(0.28)).gearAt(s, 0.004, 0.04, x, 0)
    }
}

struct GearBoonieView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            Ellipse().fill(gearGrad(0x8C6F48, 0x6A5434))
                .gearAt(s, 0.40, 0.06, 0, 0.038)
            crown
            GearFloppyBrimShape().fill(gearGrad3(0xC2A273, 0xA8875A, 0x86683F))
                .gearAt(s, 0.42, 0.075, 0, 0.05)
            GearFloppyBrimShape().stroke(Color(hex: 0x6A5434).opacity(0.7),
                                         style: StrokeStyle(lineWidth: s * 0.002, dash: [s * 0.006, s * 0.004]))
                .gearAt(s, 0.37, 0.055, 0, 0.051)
        }
        .frame(width: s * 0.46, height: s * 0.26)
    }

    private var crown: some View {
        ZStack {
            GearDomeShape().fill(gearGrad3(0xC4A577, 0xA8875A, 0x8A6C43))
            Rectangle().fill(Color(hex: 0x6E5636)).gearAt(s, 0.26, 0.018, 0, 0.038)
            ForEach(0..<6, id: \.self) { i in
                loop(i)
            }
            GearShine(alpha: 0.16).gearAt(s, 0.06, 0.014, -0.06, -0.025, -25)
        }
        .frame(width: s * 0.25, height: s * 0.1)
        .clipShape(GearDomeShape())
        .offset(y: -s * 0.008)
    }

    private func loop(_ i: Int) -> some View {
        let x: CGFloat = CGFloat(i) * 0.04 - 0.1
        return Rectangle().fill(Color(hex: 0x8A6C43)).gearAt(s, 0.006, 0.02, x, 0.038)
    }
}

struct GearExfilHelmetView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            shell
            GearRailView(s: s, top: 0x8E7A54, bottom: 0x67573A, slot: Color(hex: 0xE2D3AE))
                .gearAt(s, 0.028, 0.066, -0.124, -0.002, -18)
            GearRailView(s: s, top: 0x8E7A54, bottom: 0x67573A, slot: Color(hex: 0xE2D3AE))
                .gearAt(s, 0.028, 0.066, 0.124, -0.002, 18)
            RoundedRectangle(cornerRadius: s * 0.008).fill(gearGrad(0x7E6B48, 0x5A4B30))
                .gearAt(s, 0.058, 0.03, 0, 0.026)
            RoundedRectangle(cornerRadius: s * 0.003).fill(Color(hex: 0x1A1D20))
                .gearAt(s, 0.028, 0.009, 0, 0.027)
        }
        .frame(width: s * 0.36, height: s * 0.26)
    }

    private var shell: some View {
        ZStack {
            GearHighCutShape(cut: 0.48).fill(gearGrad3(0xDCC79A, 0xC8A86B, 0xA2834F))
            RoundedRectangle(cornerRadius: s * 0.006).fill(Color(hex: 0xB59762).opacity(0.8))
                .gearAt(s, 0.08, 0.02, 0, -0.03)
            GearHighCutShape(cut: 0.48).stroke(Color(hex: 0x7E6B48), lineWidth: s * 0.005)
            GearShine(alpha: 0.25).gearAt(s, 0.07, 0.016, -0.07, -0.03, -24)
        }
        .frame(width: s * 0.29, height: s * 0.115)
        .clipShape(GearHighCutShape(cut: 0.48))
    }
}

struct GearGoldHelmetView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            GearCrestShape().fill(gearGoldGrad()).gearAt(s, 0.05, 0.075, 0, -0.072)
            Capsule().fill(Color(hex: 0xC0392B)).gearAt(s, 0.012, 0.05, 0, -0.08)
            shell
            Capsule().fill(gearGrad(0xF0CF78, 0xA27A26)).gearAt(s, 0.3, 0.022, 0, 0.05)
            GearStarShape().fill(gearGrad(0xFFF3C4, 0xE2B451)).gearAt(s, 0.034, 0.034, 0, 0.012)
            GearStarShape().stroke(Theme.goldDark, lineWidth: s * 0.0025).gearAt(s, 0.034, 0.034, 0, 0.012)
        }
        .frame(width: s * 0.36, height: s * 0.28)
    }

    private var shell: some View {
        ZStack {
            GearDomeShape().fill(gearGoldGrad())
            GearShine(alpha: 0.45).gearAt(s, 0.08, 0.016, -0.07, -0.025, -24)
            GearShine(alpha: 0.3).gearAt(s, 0.02, 0.01, 0.08, -0.025, 24)
            GearDomeShape().stroke(Theme.goldDark, lineWidth: s * 0.004)
        }
        .frame(width: s * 0.29, height: s * 0.105)
        .clipShape(GearDomeShape())
    }
}

struct GearNisseCoverView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            body0
            Capsule().fill(gearGrad(0xFFFFFF, 0xD5D9DC)).gearAt(s, 0.305, 0.034, 0, 0.048)
            Circle().fill(gearGrad(0xFFFFFF, 0xD0D4D8)).gearAt(s, 0.045, 0.045, 0.215, 0.008)
        }
        .frame(width: s * 0.52, height: s * 0.26)
    }

    private var body0: some View {
        ZStack {
            GearNisseShape().fill(gearGrad3(0xEE5A4E, 0xD63A31, 0xA42923))
            GearShine(alpha: 0.25).gearAt(s, 0.07, 0.016, -0.08, -0.035, -30)
        }
        .frame(width: s * 0.3625, height: s * 0.13)
        .clipShape(GearNisseShape())
        .offset(x: s * 0.036, y: -s * 0.012)
    }
}

// MARK: - Briller

struct GearMFrameView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            Capsule().fill(Color(hex: 0x23272B)).gearAt(s, 0.03, 0.009, -0.118, -0.016, 8)
            Capsule().fill(Color(hex: 0x23272B)).gearAt(s, 0.03, 0.009, 0.118, -0.016, -8)
            GearWrapLensShape()
                .fill(LinearGradient(colors: [Color(hex: 0x1F2A36), Color(hex: 0x3E5A78), Color(hex: 0xC27B3E)],
                                     startPoint: .top, endPoint: .bottom))
                .opacity(0.94)
                .gearAt(s, 0.22, 0.058, 0, 0.004)
            Capsule().fill(gearGrad(0x3A3F44, 0x1A1D20)).gearAt(s, 0.226, 0.012, 0, -0.022)
            GearShine(alpha: 0.4).gearAt(s, 0.045, 0.008, -0.06, -0.006, -18)
            GearShine(alpha: 0.3).gearAt(s, 0.02, 0.006, 0.065, -0.008, -18)
        }
        .frame(width: s * 0.3, height: s * 0.12)
    }
}

struct GearCrossbowView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            Capsule().fill(Color(hex: 0x1A1D20)).gearAt(s, 0.03, 0.009, -0.12, -0.016, 6)
            Capsule().fill(Color(hex: 0x1A1D20)).gearAt(s, 0.03, 0.009, 0.12, -0.016, -6)
            GearShieldLensShape().fill(gearGrad3(0x6F808E, 0x46535E, 0x2A333B))
                .opacity(0.92)
                .gearAt(s, 0.235, 0.066, 0, 0.006)
            GearShieldLensShape().stroke(Color(hex: 0x15181B), lineWidth: s * 0.003)
                .gearAt(s, 0.235, 0.066, 0, 0.006)
            Rectangle().fill(Color(hex: 0x1A1D20)).gearAt(s, 0.22, 0.007, 0, -0.022)
            GearShine(alpha: 0.45).gearAt(s, 0.05, 0.007, -0.06, -0.008, -12)
            GearShine(alpha: 0.3).gearAt(s, 0.022, 0.006, 0.07, -0.01, -12)
        }
        .frame(width: s * 0.3, height: s * 0.12)
    }
}

struct GearLocustView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            Capsule().fill(gearGrad(0xC9AE7C, 0x8E7449)).gearAt(s, 0.3, 0.024, 0, -0.002)
            RoundedRectangle(cornerRadius: s * 0.003).fill(Color(hex: 0x23272B))
                .gearAt(s, 0.016, 0.03, -0.128, -0.002)
            RoundedRectangle(cornerRadius: s * 0.003).fill(Color(hex: 0x23272B))
                .gearAt(s, 0.016, 0.03, 0.128, -0.002)
            GearGoggleShape().fill(gearGrad(0x3A3F44, 0x1A1D20)).gearAt(s, 0.24, 0.078, 0, 0.002)
            GearGoggleShape()
                .fill(LinearGradient(colors: [Color(hex: 0x6B3E1C), Color(hex: 0xD8913F), Color(hex: 0xF0C27A)],
                                     startPoint: .top, endPoint: .bottom))
                .opacity(0.92)
                .gearAt(s, 0.205, 0.054, 0, 0.004)
            ForEach(0..<4, id: \.self) { i in
                vent(i)
            }
            GearShine(alpha: 0.45).gearAt(s, 0.05, 0.008, -0.05, -0.008, -15)
        }
        .frame(width: s * 0.34, height: s * 0.12)
    }

    private func vent(_ i: Int) -> some View {
        let x: CGFloat = CGFloat(i) * 0.03 - 0.045
        return Capsule().fill(Color(hex: 0x0E1012)).gearAt(s, 0.016, 0.004, x, -0.031)
    }
}

struct GearAviatorView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            Capsule().fill(gearGoldGrad()).gearAt(s, 0.03, 0.005, -0.112, -0.022, 4)
            Capsule().fill(gearGoldGrad()).gearAt(s, 0.03, 0.005, 0.112, -0.022, -4)
            lens.gearAt(s, 0.088, 0.07, 0.052, 0.006)
            lens.scaleEffect(x: -1, y: 1).gearAt(s, 0.088, 0.07, -0.052, 0.006)
            Capsule().fill(gearGoldGrad()).gearAt(s, 0.034, 0.005, 0, -0.024)
            GearJawShape().stroke(Theme.gold, lineWidth: s * 0.004).gearAt(s, 0.026, 0.008, 0, -0.012)
        }
        .frame(width: s * 0.3, height: s * 0.12)
    }

    private var lens: some View {
        ZStack {
            GearTeardropShape()
                .fill(LinearGradient(colors: [Color(hex: 0x2F3A2E), Color(hex: 0x56624A), Color(hex: 0x7C7A58)],
                                     startPoint: .top, endPoint: .bottom))
                .opacity(0.92)
            GearShine(alpha: 0.4).gearAt(s, 0.028, 0.007, -0.008, -0.016, -25)
            GearTeardropShape().stroke(gearGoldGrad(), lineWidth: s * 0.006)
        }
    }
}

// MARK: - Nattesyn

struct GearPvs14View: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.006).fill(gearGrad(0x2E3338, 0x14171A))
                .gearAt(s, 0.044, 0.022, 0, 0.034)
            RoundedRectangle(cornerRadius: s * 0.004).fill(gearGrad(0x6A737C, 0x3A4148))
                .gearAt(s, 0.016, 0.042, 0, 0.014)
            RoundedRectangle(cornerRadius: s * 0.014).fill(gearGrad3(0x4A5157, 0x2E3338, 0x1A1D20))
                .gearAt(s, 0.058, 0.064, 0, -0.014)
            Circle().fill(Color(hex: 0x3A4148)).gearAt(s, 0.014, 0.014, 0.034, -0.03)
            GearNVLens(s: s, d: 0.044).gearAt(s, 0.044, 0.044, 0, -0.012)
        }
        .frame(width: s * 0.14, height: s * 0.13)
    }
}

struct GearPvs31View: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.006).fill(gearGrad(0x2E3338, 0x14171A))
                .gearAt(s, 0.04, 0.022, 0, 0.036)
            Capsule().fill(gearGrad(0x4A5157, 0x1E2226)).gearAt(s, 0.12, 0.03, 0, 0.012)
            RoundedRectangle(cornerRadius: s * 0.005).fill(gearGrad(0x3A4148, 0x1E2226))
                .gearAt(s, 0.03, 0.02, 0, -0.03)
            Circle().fill(gearGrad(0x4A5157, 0x23272B)).gearAt(s, 0.054, 0.054, -0.033, -0.006)
            Circle().fill(gearGrad(0x4A5157, 0x23272B)).gearAt(s, 0.054, 0.054, 0.033, -0.006)
            GearNVLens(s: s, d: 0.042).gearAt(s, 0.042, 0.042, -0.033, -0.006)
            GearNVLens(s: s, d: 0.042).gearAt(s, 0.042, 0.042, 0.033, -0.006)
        }
        .frame(width: s * 0.17, height: s * 0.13)
    }
}

struct GearGpnvgView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.006).fill(gearGrad(0x2E3338, 0x14171A))
                .gearAt(s, 0.04, 0.022, 0, 0.038)
            RoundedRectangle(cornerRadius: s * 0.014).fill(gearGrad3(0x4A5157, 0x2E3338, 0x1A1D20))
                .gearAt(s, 0.18, 0.05, 0, 0.004)
            outerTube.gearAt(s, 0.04, 0.046, -0.07, 0.008, 14)
            outerTube.gearAt(s, 0.04, 0.046, 0.07, 0.008, -14)
            Circle().fill(gearGrad(0x4A5157, 0x23272B)).gearAt(s, 0.05, 0.05, -0.025, -0.002)
            Circle().fill(gearGrad(0x4A5157, 0x23272B)).gearAt(s, 0.05, 0.05, 0.025, -0.002)
            GearNVLens(s: s, d: 0.04).gearAt(s, 0.04, 0.04, -0.025, -0.002)
            GearNVLens(s: s, d: 0.04).gearAt(s, 0.04, 0.04, 0.025, -0.002)
        }
        .frame(width: s * 0.23, height: s * 0.13)
    }

    private var outerTube: some View {
        ZStack {
            Ellipse().fill(gearGrad(0x4A5157, 0x23272B))
            GearNVLens(s: s, d: 0.03).scaleEffect(x: 0.85, y: 1)
        }
    }
}

// MARK: - Ansigt

struct GearBalaclavaView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.025).fill(gearGrad(0x2A2E33, 0x15181B))
                .gearAt(s, 0.13, 0.09, 0, 0.085)
            neckRibs
            Ellipse().fill(Color(hex: 0x23272B)).gearAt(s, 0.045, 0.06, -0.128, -0.03)
            Ellipse().fill(Color(hex: 0x23272B)).gearAt(s, 0.045, 0.06, 0.128, -0.03)
            GearBalaclavaShape(slotTop: 0.5, slotBottom: 0.6207, slotInset: 0.17)
                .fill(gearGrad3(0x363B41, 0x25292D, 0x17191C), style: FillStyle(eoFill: true))
                .gearAt(s, 0.27, 0.29, 0, -0.045)
            GearShine(alpha: 0.08).gearAt(s, 0.08, 0.02, -0.05, -0.15, -25)
        }
        .frame(width: s * 0.34, height: s * 0.42)
    }

    private var neckRibs: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                rib(i)
            }
        }
    }

    private func rib(_ i: Int) -> some View {
        let y: CGFloat = CGFloat(i) * 0.016 + 0.08
        return Capsule().fill(Color.black.opacity(0.3)).gearAt(s, 0.12, 0.003, 0, y)
    }
}

struct GearShemaghView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.012).fill(gearGrad(0xB9AD86, 0x8F8360))
                .gearAt(s, 0.045, 0.065, 0.085, 0.115, -14)
            scarf
            Ellipse().fill(gearGrad(0xA99C74, 0x83775A)).gearAt(s, 0.038, 0.03, 0.07, 0.096)
        }
        .frame(width: s * 0.34, height: s * 0.32)
    }

    private var scarf: some View {
        ZStack {
            GearScarfShape().fill(gearGrad3(0xCBBF96, 0xB4A77E, 0x938660))
            ForEach(0..<10, id: \.self) { i in
                vLine(i)
            }
            ForEach(0..<7, id: \.self) { i in
                hLine(i)
            }
            GearJawShape().stroke(Color(hex: 0x6E6346).opacity(0.5), lineWidth: s * 0.003)
                .gearAt(s, 0.2, 0.03, 0, 0.02)
            GearJawShape().stroke(Color(hex: 0x6E6346).opacity(0.5), lineWidth: s * 0.003)
                .gearAt(s, 0.16, 0.03, 0, 0.045)
        }
        .frame(width: s * 0.27, height: s * 0.135)
        .clipShape(GearScarfShape())
        .offset(y: s * 0.058)
    }

    private func vLine(_ i: Int) -> some View {
        let x: CGFloat = CGFloat(i) * 0.03 - 0.135
        return Rectangle().fill(Color(hex: 0x5E6B42).opacity(0.45)).gearAt(s, 0.005, 0.14, x, 0)
    }

    private func hLine(_ i: Int) -> some View {
        let y: CGFloat = CGFloat(i) * 0.022 - 0.065
        return Rectangle().fill(Color(hex: 0x5E6B42).opacity(0.45)).gearAt(s, 0.28, 0.005, 0, y)
    }
}

struct GearHeadsetView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            GearArcShape().stroke(Color(hex: 0x1E2226), style: StrokeStyle(lineWidth: s * 0.02, lineCap: .round))
                .gearAt(s, 0.26, 0.14, 0, -0.125)
            GearArcShape().stroke(Color(hex: 0x4A5157), style: StrokeStyle(lineWidth: s * 0.006, lineCap: .round))
                .gearAt(s, 0.26, 0.14, 0, -0.127)
            GearBoomShape().stroke(Color(hex: 0x1A1D20), style: StrokeStyle(lineWidth: s * 0.008, lineCap: .round))
                .gearAt(s, 0.09, 0.042, -0.087, 0.019)
            Capsule().fill(gearGrad(0x3A3F44, 0x15181B)).gearAt(s, 0.026, 0.017, -0.038, 0.04)
            cup.gearAt(s, 0.068, 0.095, -0.13, -0.03)
            cup.gearAt(s, 0.068, 0.095, 0.13, -0.03)
            RoundedRectangle(cornerRadius: s * 0.003).fill(Color(hex: 0x1A1D20))
                .gearAt(s, 0.014, 0.022, -0.13, -0.055)
        }
        .frame(width: s * 0.36, height: s * 0.44)
    }

    private var cup: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.022).fill(gearGrad3(0x8A9666, 0x6E7B4F, 0x4A5434))
            RoundedRectangle(cornerRadius: s * 0.016).fill(Color(hex: 0x3E4730).opacity(0.7))
                .gearAt(s, 0.044, 0.068, 0, 0.004)
            GearShine(alpha: 0.25).gearAt(s, 0.012, 0.03, -0.017, -0.02, 8)
        }
    }
}

struct GearSkullMaskView: View {
    let s: CGFloat

    private var print: Color { Color(hex: 0xEDEBE2) }

    var body: some View {
        ZStack {
            GearScarfShape().fill(gearGrad3(0x363B41, 0x24282C, 0x14171A))
                .gearAt(s, 0.235, 0.105, 0, 0.042)
            GearArcShape().stroke(print, style: StrokeStyle(lineWidth: s * 0.004, lineCap: .round))
                .gearAt(s, 0.04, 0.014, -0.068, 0.014)
            GearArcShape().stroke(print, style: StrokeStyle(lineWidth: s * 0.004, lineCap: .round))
                .gearAt(s, 0.04, 0.014, 0.068, 0.014)
            GearTriangleShape().fill(print).gearAt(s, 0.022, 0.017, 0, 0.012)
            ForEach(0..<6, id: \.self) { i in
                tooth(i)
            }
            GearJawShape().stroke(print, style: StrokeStyle(lineWidth: s * 0.004, lineCap: .round))
                .gearAt(s, 0.12, 0.03, 0, 0.044)
        }
        .frame(width: s * 0.3, height: s * 0.2)
    }

    private func tooth(_ i: Int) -> some View {
        let x: CGFloat = CGFloat(i) * 0.015 - 0.0375
        let lift: CGFloat = x * x * 6
        let y: CGFloat = 0.042 - lift
        return RoundedRectangle(cornerRadius: s * 0.003).fill(print).gearAt(s, 0.012, 0.016, x, y)
    }
}

// MARK: - Veste

/// Fælles vestkrop: fyld, kantlinje og blød glans øverst.
struct GearVestBase: View {
    let s: CGFloat
    let shape: GearVestShape
    let fill: LinearGradient
    let edge: Color

    var body: some View {
        ZStack {
            shape.fill(fill)
            shape.stroke(edge, lineWidth: s * 0.004)
        }
    }
}

struct GearPoliceVestView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            GearVestBase(s: s, shape: GearVestShape(neckDepth: 0.17, corner: 0.1),
                         fill: gearGrad3(0x2C406A, 0x1F3052, 0x15213A), edge: Color(hex: 0x0E1628))
                .gearAt(s, 0.35, 0.26)
            RoundedRectangle(cornerRadius: s * 0.01)
                .strokeBorder(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: s * 0.002, dash: [s * 0.006, s * 0.004]))
                .gearAt(s, 0.3, 0.12, 0, 0.055)
            Text("POLITI")
                .font(.system(size: s * 0.034, weight: .heavy, design: .monospaced))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .fixedSize()
                .offset(y: -s * 0.03)
            Capsule().fill(Color.white.opacity(0.07)).gearAt(s, 0.24, 0.02, 0, -0.08)
        }
        .frame(width: s * 0.38, height: s * 0.3)
    }
}

struct GearSwatVestView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.008).fill(gearGrad(0x22262A, 0x101215))
                .gearAt(s, 0.35, 0.12, 0, 0.065)
            GearVestBase(s: s, shape: GearVestShape(strapOuter: 0.15, strapInner: 0.33, sideTop: 0.26, corner: 0.08),
                         fill: gearGrad3(0x383D42, 0x25292D, 0x16191C), edge: Color(hex: 0x0B0D0F))
                .gearAt(s, 0.31, 0.26)
            RoundedRectangle(cornerRadius: s * 0.008).fill(Color(hex: 0x16191C))
                .gearAt(s, 0.06, 0.03, -0.1, -0.112)
            RoundedRectangle(cornerRadius: s * 0.008).fill(Color(hex: 0x16191C))
                .gearAt(s, 0.06, 0.03, 0.1, -0.112)
            ForEach(0..<3, id: \.self) { i in
                molle(i)
            }
            RoundedRectangle(cornerRadius: s * 0.006).fill(gearGrad(0xD3D8DC, 0xA5ACB3))
                .gearAt(s, 0.15, 0.048, 0, -0.03)
            Text("SWAT")
                .font(.system(size: s * 0.032, weight: .heavy, design: .monospaced))
                .foregroundStyle(Color(hex: 0x1A1D20))
                .lineLimit(1)
                .fixedSize()
                .offset(y: -s * 0.03)
        }
        .frame(width: s * 0.38, height: s * 0.3)
    }

    private func molle(_ i: Int) -> some View {
        let y: CGFloat = CGFloat(i) * 0.03 + 0.04
        return GearHLineShape()
            .stroke(Color.black.opacity(0.5), style: StrokeStyle(lineWidth: s * 0.006, dash: [s * 0.014, s * 0.006]))
            .gearAt(s, 0.24, 0.01, 0, y)
    }
}

struct GearChestRigView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            Capsule().fill(gearGrad(0x6E7B4F, 0x4E5836)).gearAt(s, 0.036, 0.17, -0.1, -0.05, -6)
            Capsule().fill(gearGrad(0x6E7B4F, 0x4E5836)).gearAt(s, 0.036, 0.17, 0.1, -0.05, 6)
            Capsule().fill(gearGrad(0x5E6A43, 0x48512F)).gearAt(s, 0.21, 0.022, 0, -0.03)
            RoundedRectangle(cornerRadius: s * 0.004).fill(Color(hex: 0x23272B))
                .gearAt(s, 0.026, 0.024, 0, -0.03)
            RoundedRectangle(cornerRadius: s * 0.016).fill(gearGrad3(0x7C8A5A, 0x6E7B4F, 0x4E5836))
                .gearAt(s, 0.345, 0.115, 0, 0.07)
            ForEach(0..<4, id: \.self) { i in
                pouch(i)
            }
        }
        .frame(width: s * 0.38, height: s * 0.32)
    }

    private func pouch(_ i: Int) -> some View {
        let x: CGFloat = CGFloat(i) * 0.072 - 0.108
        return GearRigMagView(s: s).gearAt(s, 0.062, 0.09, x, 0.072)
    }
}

/// Én magasinlomme på chest riggen.
struct GearRigMagView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.004).fill(Color(hex: 0x23272B))
                .gearAt(s, 0.036, 0.03, 0, -0.03)
            RoundedRectangle(cornerRadius: s * 0.008).fill(gearGrad(0x8E9C6A, 0x5E6A43))
                .gearAt(s, 0.058, 0.07, 0, 0.01)
            RoundedRectangle(cornerRadius: s * 0.006).fill(gearGrad(0x9AA874, 0x6E7B4F))
                .gearAt(s, 0.058, 0.024, 0, -0.016)
            Capsule().fill(Color(hex: 0x2F3520)).gearAt(s, 0.014, 0.008, 0, -0.004)
        }
    }
}

struct GearJpcVestView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            cummerbund
            GearVestBase(s: s, shape: GearVestShape(strapOuter: 0.17, strapInner: 0.34, sideTop: 0.3, corner: 0.1),
                         fill: gearGrad3(0xC4A577, 0xA8875A, 0x86683F), edge: Color(hex: 0x6A5434))
                .gearAt(s, 0.28, 0.26)
            ForEach(0..<3, id: \.self) { i in
                slots(i)
            }
            RoundedRectangle(cornerRadius: s * 0.01).fill(gearGrad(0xB39268, 0x8A6C43))
                .gearAt(s, 0.16, 0.065, 0, 0.085)
            RoundedRectangle(cornerRadius: s * 0.004).fill(Color(hex: 0xCDB48A))
                .gearAt(s, 0.08, 0.026, 0, 0.075)
        }
        .frame(width: s * 0.38, height: s * 0.3)
    }

    private var cummerbund: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.008).fill(gearGrad(0x9A7B50, 0x6E5636))
                .gearAt(s, 0.345, 0.12, 0, 0.06)
            ForEach(0..<4, id: \.self) { i in
                band(i)
            }
        }
    }

    private func band(_ i: Int) -> some View {
        let y: CGFloat = CGFloat(i) * 0.026 + 0.02
        return Capsule().fill(Color.black.opacity(0.18)).gearAt(s, 0.34, 0.004, 0, y)
    }

    private func slots(_ i: Int) -> some View {
        let y: CGFloat = CGFloat(i) * 0.024 - 0.045
        return GearHLineShape()
            .stroke(Color(hex: 0x6A5434).opacity(0.8), style: StrokeStyle(lineWidth: s * 0.005, lineCap: .round, dash: [s * 0.016, s * 0.008]))
            .gearAt(s, 0.17, 0.01, 0, y)
    }
}

struct GearAvsVestView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            cummerbund(-0.152)
            cummerbund(0.152)
            GearVestBase(s: s, shape: GearVestShape(strapOuter: 0.12, strapInner: 0.31, sideTop: 0.22, corner: 0.07),
                         fill: gearGrad3(0x5E6950, 0x4A5340, 0x353C2C), edge: Color(hex: 0x262B1F))
                .gearAt(s, 0.31, 0.27)
            RoundedRectangle(cornerRadius: s * 0.01).fill(gearGrad(0x4F5843, 0x353C2C))
                .gearAt(s, 0.075, 0.042, -0.104, -0.112)
            RoundedRectangle(cornerRadius: s * 0.01).fill(gearGrad(0x4F5843, 0x353C2C))
                .gearAt(s, 0.075, 0.042, 0.104, -0.112)
            RoundedRectangle(cornerRadius: s * 0.004).fill(Color(hex: 0x6A7558))
                .gearAt(s, 0.1, 0.03, 0, -0.06)
            ForEach(0..<5, id: \.self) { i in
                molle(i)
            }
        }
        .frame(width: s * 0.4, height: s * 0.32)
    }

    private func cummerbund(_ x: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.01).fill(gearGrad(0x4A5340, 0x2E3426))
            VStack(spacing: s * 0.02) {
                ForEach(0..<4, id: \.self) { _ in
                    Capsule().fill(Color.black.opacity(0.28)).frame(width: s * 0.045, height: s * 0.005)
                }
            }
        }
        .gearAt(s, 0.06, 0.16, x, 0.04)
    }

    private func molle(_ i: Int) -> some View {
        let y: CGFloat = CGFloat(i) * 0.03 - 0.012
        return GearHLineShape()
            .stroke(Color(hex: 0x262B1F).opacity(0.85), style: StrokeStyle(lineWidth: s * 0.007, dash: [s * 0.016, s * 0.005]))
            .gearAt(s, 0.25, 0.012, 0, y)
    }
}

struct GearGoldVestView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.008).fill(gearGrad(0x22262A, 0x101215))
                .gearAt(s, 0.35, 0.12, 0, 0.065)
            GearVestShape(strapOuter: 0.15, strapInner: 0.33, sideTop: 0.26, corner: 0.08)
                .fill(gearGrad3(0x34383D, 0x212428, 0x121417))
                .gearAt(s, 0.31, 0.26)
            GearVestShape(strapOuter: 0.15, strapInner: 0.33, sideTop: 0.26, corner: 0.08)
                .stroke(gearGoldGrad(), lineWidth: s * 0.007)
                .gearAt(s, 0.31, 0.26)
            RoundedRectangle(cornerRadius: s * 0.006).stroke(gearGoldGrad(), lineWidth: s * 0.004)
                .gearAt(s, 0.15, 0.05, 0, -0.03)
            GearStarShape().fill(gearGoldGrad()).gearAt(s, 0.032, 0.032, 0, -0.03)
            GearBuckleView(s: s, gold: true).gearAt(s, 0.036, 0.024, -0.135, 0.075)
            GearBuckleView(s: s, gold: true).gearAt(s, 0.036, 0.024, 0.135, 0.075)
            GearBuckleView(s: s, gold: true).gearAt(s, 0.032, 0.022, -0.1, -0.1)
            GearBuckleView(s: s, gold: true).gearAt(s, 0.032, 0.022, 0.1, -0.1)
        }
        .frame(width: s * 0.38, height: s * 0.3)
    }
}

// MARK: - Tasker

struct GearMagPouchView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            mag.gearAt(s, 0.046, 0.08, -0.05, -0.004)
            mag.gearAt(s, 0.046, 0.08, 0, -0.004)
            mag.gearAt(s, 0.046, 0.08, 0.05, -0.004)
        }
        .frame(width: s * 0.2, height: s * 0.12)
    }

    private var mag: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.004).fill(gearGrad(0x3A3F44, 0x1E2226))
                .gearAt(s, 0.032, 0.026, 0, -0.026)
            RoundedRectangle(cornerRadius: s * 0.008).fill(gearGrad3(0xBE9D6C, 0xA8875A, 0x7E6440))
                .gearAt(s, 0.046, 0.062, 0, 0.009)
            RoundedRectangle(cornerRadius: s * 0.002)
                .strokeBorder(Color(hex: 0x5E4A2E).opacity(0.7), style: StrokeStyle(lineWidth: s * 0.0018, dash: [s * 0.003, s * 0.002]))
                .gearAt(s, 0.038, 0.052, 0, 0.011)
            Capsule().fill(Color(hex: 0x2F3520)).gearAt(s, 0.034, 0.006, 0, -0.02)
            Capsule().fill(Color(hex: 0x2F3520)).gearAt(s, 0.01, 0.014, 0, -0.012)
        }
    }
}

struct GearIfakView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.01).fill(gearGrad3(0x555C63, 0x40464C, 0x2A2E33))
                .gearAt(s, 0.056, 0.062, 0.11, 0.012)
            RoundedRectangle(cornerRadius: s * 0.008).fill(gearGrad(0x5E666E, 0x454B52))
                .gearAt(s, 0.056, 0.02, 0.11, -0.012)
            Capsule().fill(Color(hex: 0xD9433B)).gearAt(s, 0.014, 0.01, 0.11, -0.024)
            RoundedRectangle(cornerRadius: s * 0.001).fill(Color(hex: 0xD9433B))
                .gearAt(s, 0.024, 0.008, 0.11, 0.022)
            RoundedRectangle(cornerRadius: s * 0.001).fill(Color(hex: 0xD9433B))
                .gearAt(s, 0.008, 0.024, 0.11, 0.022)
        }
        .frame(width: s * 0.3, height: s * 0.12)
    }
}

struct GearFlashlightView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.003).fill(Color(hex: 0x23272B))
                .gearAt(s, 0.014, 0.036, -0.11, 0.012)
            Capsule().fill(gearGrad3(0x7A838C, 0x4A5157, 0x2A2E33))
                .gearAt(s, 0.058, 0.016, -0.108, 0.015)
            RoundedRectangle(cornerRadius: s * 0.004).fill(gearGrad3(0x7A838C, 0x4A5157, 0x2A2E33))
                .gearAt(s, 0.018, 0.024, -0.142, 0.015)
            Capsule().fill(Color(hex: 0xFFF2C2)).gearAt(s, 0.005, 0.018, -0.151, 0.015)
            ForEach(0..<3, id: \.self) { i in
                knurl(i)
            }
            Capsule().fill(Color(hex: 0x1A1D20)).gearAt(s, 0.008, 0.012, -0.078, 0.015)
        }
        .frame(width: s * 0.34, height: s * 0.1)
    }

    private func knurl(_ i: Int) -> some View {
        let x: CGFloat = CGFloat(i) * 0.008 - 0.1
        return Rectangle().fill(Color.black.opacity(0.3)).gearAt(s, 0.002, 0.014, x, 0.015)
    }
}

struct GearAdminPanelView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.008).fill(gearGrad3(0x7A8458, 0x5E6844, 0x454D31))
                .gearAt(s, 0.1, 0.068, 0, -0.088)
            RoundedRectangle(cornerRadius: s * 0.007).fill(gearGrad(0x86915F, 0x6A7550))
                .gearAt(s, 0.1, 0.024, 0, -0.11)
            RoundedRectangle(cornerRadius: s * 0.003).fill(Color(hex: 0x9BA772))
                .gearAt(s, 0.05, 0.012, 0, -0.11)
            RoundedRectangle(cornerRadius: s * 0.003).fill(Color(hex: 0xDDEBF2).opacity(0.45))
                .gearAt(s, 0.06, 0.03, -0.008, -0.08)
            Rectangle().fill(Color(hex: 0x2F3520).opacity(0.5)).gearAt(s, 0.044, 0.002, -0.008, -0.085)
            Rectangle().fill(Color(hex: 0x2F3520).opacity(0.5)).gearAt(s, 0.044, 0.002, -0.008, -0.076)
            Capsule().fill(gearGrad(0x2A2E33, 0x101215)).gearAt(s, 0.008, 0.05, 0.04, -0.09)
            Capsule().fill(Color(hex: 0xC7CDD2)).gearAt(s, 0.003, 0.018, 0.043, -0.1)
        }
        .frame(width: s * 0.14, height: s * 0.28)
    }
}

struct GearRadioView: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            Capsule().fill(gearGrad(0x2A2E33, 0x101215)).gearAt(s, 0.007, 0.11, 0.142, -0.155, 13)
            Circle().fill(Color(hex: 0x1A1D20)).gearAt(s, 0.012, 0.012, 0.154, -0.208)
            Circle().fill(Color(hex: 0x23272B)).gearAt(s, 0.012, 0.012, 0.11, -0.108)
            RoundedRectangle(cornerRadius: s * 0.008).fill(gearGrad(0x8C6F48, 0x6A5434))
                .gearAt(s, 0.05, 0.05, 0.12, -0.05)
            RoundedRectangle(cornerRadius: s * 0.008).fill(gearGrad3(0x4A5157, 0x2E3338, 0x1A1D20))
                .gearAt(s, 0.04, 0.074, 0.12, -0.066)
            RoundedRectangle(cornerRadius: s * 0.003).fill(Color(hex: 0x9BC2A4).opacity(0.8))
                .gearAt(s, 0.024, 0.012, 0.12, -0.084)
            keypad
            RoundedRectangle(cornerRadius: s * 0.006).fill(gearGrad(0x9A7B50, 0x6E5636))
                .gearAt(s, 0.05, 0.018, 0.12, -0.034)
        }
        .frame(width: s * 0.34, height: s * 0.46)
    }

    private var keypad: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                key(i)
            }
        }
    }

    private func key(_ i: Int) -> some View {
        let col: CGFloat = CGFloat(i % 3)
        let row: CGFloat = CGFloat(i / 3)
        let x: CGFloat = 0.11 + col * 0.01
        let y: CGFloat = -0.068 + row * 0.01
        return Circle().fill(Color(hex: 0x6A737C)).gearAt(s, 0.006, 0.006, x, y)
    }
}

// MARK: - Patches

/// Patch-grund: afrundet rektangel med stikninger. Indhold placeres relativt til patchens centrum.
struct GearPatchFrame<Content: View>: View {
    let s: CGFloat
    let bg: LinearGradient
    let stitch: Color
    let content: Content

    init(s: CGFloat, bg: LinearGradient, stitch: Color, @ViewBuilder content: () -> Content) {
        self.s = s
        self.bg = bg
        self.stitch = stitch
        self.content = content()
    }

    var body: some View {
        let r: CGFloat = s * 0.008
        return ZStack {
            RoundedRectangle(cornerRadius: r).fill(bg)
            content
            RoundedRectangle(cornerRadius: r * 0.7)
                .strokeBorder(stitch, style: StrokeStyle(lineWidth: s * 0.0022, dash: [s * 0.004, s * 0.0025]))
                .padding(s * 0.0035)
            RoundedRectangle(cornerRadius: r).strokeBorder(Color.black.opacity(0.35), lineWidth: s * 0.0015)
        }
        .frame(width: s * 0.07, height: s * 0.05)
        .clipShape(RoundedRectangle(cornerRadius: r))
        .frame(width: s * 0.09, height: s * 0.07)
    }
}

struct GearPatchDKView: View {
    let s: CGFloat

    var body: some View {
        GearPatchFrame(s: s, bg: gearGrad(0xD6203A, 0xA8102A), stitch: Color.white.opacity(0.6)) {
            Rectangle().fill(Color.white).gearAt(s, 0.08, 0.009, 0, 0)
            Rectangle().fill(Color.white).gearAt(s, 0.009, 0.06, -0.01, 0)
        }
    }
}

struct GearPatchSwatView: View {
    let s: CGFloat

    var body: some View {
        GearPatchFrame(s: s, bg: gearGrad(0x2A2E33, 0x101215), stitch: Color.white.opacity(0.5)) {
            Text("SWAT")
                .font(.system(size: s * 0.022, weight: .heavy, design: .monospaced))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .fixedSize()
        }
    }
}

struct GearPatchBloodView: View {
    let s: CGFloat

    var body: some View {
        GearPatchFrame(s: s, bg: gearGrad(0x4A5434, 0x2F3520), stitch: Color(hex: 0xC8D0B0).opacity(0.6)) {
            Circle().fill(Color(hex: 0xD9433B)).gearAt(s, 0.008, 0.008, -0.024, 0)
            Text("O POS")
                .font(.system(size: s * 0.016, weight: .heavy, design: .monospaced))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .fixedSize()
                .offset(x: s * 0.005)
        }
    }
}

struct GearPatchIRView: View {
    let s: CGFloat

    var body: some View {
        GearPatchFrame(s: s, bg: gearGrad(0x7D8388, 0x6A7075), stitch: Color(hex: 0x3E4247).opacity(0.7)) {
            ForEach(0..<7, id: \.self) { i in
                stripe(i)
            }
            Rectangle().fill(Color(hex: 0x41464B)).gearAt(s, 0.032, 0.028, -0.019, -0.011)
            ForEach(0..<6, id: \.self) { i in
                star(i)
            }
        }
    }

    private func stripe(_ i: Int) -> some View {
        let h: CGFloat = 0.05 / 7.0
        let y: CGFloat = -0.025 + h * (CGFloat(i) + 0.5)
        let c: Color = (i % 2 == 0) ? Color(hex: 0x5A5F64) : Color(hex: 0x8E9398)
        return Rectangle().fill(c).gearAt(s, 0.07, h, 0, y)
    }

    private func star(_ i: Int) -> some View {
        let x: CGFloat = -0.028 + CGFloat(i % 3) * 0.009
        let y: CGFloat = -0.018 + CGFloat(i / 3) * 0.009
        return Circle().fill(Color(hex: 0x8E9398)).gearAt(s, 0.003, 0.003, x, y)
    }
}

struct GearPatchSealView: View {
    let s: CGFloat

    var body: some View {
        GearPatchFrame(s: s, bg: gearGrad(0xC4E8F8, 0x8CC6E8), stitch: Color.white.opacity(0.8)) {
            Capsule().fill(Color.white.opacity(0.5)).gearAt(s, 0.07, 0.006, 0, 0.021)
            Ellipse().fill(gearGrad(0xB2BBC4, 0x7C8792)).gearAt(s, 0.042, 0.034, 0, 0.004)
            Circle().fill(Color(hex: 0x1E2328)).gearAt(s, 0.007, 0.007, -0.009, -0.001)
            Circle().fill(Color(hex: 0x1E2328)).gearAt(s, 0.007, 0.007, 0.009, -0.001)
            Circle().fill(Color.white).gearAt(s, 0.0025, 0.0025, -0.008, -0.002)
            Circle().fill(Color.white).gearAt(s, 0.0025, 0.0025, 0.01, -0.002)
            Ellipse().fill(Color(hex: 0xD3D9DE)).gearAt(s, 0.011, 0.008, -0.004, 0.011)
            Ellipse().fill(Color(hex: 0xD3D9DE)).gearAt(s, 0.011, 0.008, 0.004, 0.011)
            Ellipse().fill(Color(hex: 0x2A2E33)).gearAt(s, 0.007, 0.004, 0, 0.007)
            Circle().fill(Color(hex: 0xF2A7B0).opacity(0.7)).gearAt(s, 0.006, 0.004, -0.015, 0.008)
            Circle().fill(Color(hex: 0xF2A7B0).opacity(0.7)).gearAt(s, 0.006, 0.004, 0.015, 0.008)
            Capsule().fill(Color(hex: 0x4A525A)).gearAt(s, 0.012, 0.0012, -0.016, 0.012, 10)
            Capsule().fill(Color(hex: 0x4A525A)).gearAt(s, 0.012, 0.0012, 0.016, 0.012, -10)
        }
    }
}

struct GearPatchKbhView: View {
    let s: CGFloat

    private var tower: Color { Color(hex: 0xB03A2E) }

    var body: some View {
        GearPatchFrame(s: s, bg: gearGrad(0xF4D266, 0xD9A93A), stitch: Color(hex: 0x8A6A1E).opacity(0.7)) {
            Rectangle().fill(gearGrad(0x3E7DC4, 0x245A99)).gearAt(s, 0.07, 0.012, 0, 0.02)
            Rectangle().fill(tower).gearAt(s, 0.05, 0.009, 0, 0.011)
            Rectangle().fill(tower).gearAt(s, 0.012, 0.03, 0, -0.004)
            GearTriangleShape().fill(tower).gearAt(s, 0.016, 0.01, 0, -0.023)
            Rectangle().fill(tower).gearAt(s, 0.011, 0.022, -0.018, 0.0)
            GearTriangleShape().fill(tower).gearAt(s, 0.015, 0.009, -0.018, -0.0155)
            Rectangle().fill(tower).gearAt(s, 0.011, 0.022, 0.018, 0.0)
            GearTriangleShape().fill(tower).gearAt(s, 0.015, 0.009, 0.018, -0.0155)
            Rectangle().fill(Color(hex: 0x3A1410)).gearAt(s, 0.005, 0.008, 0, 0.008)
        }
    }
}

struct GearPatchStarView: View {
    let s: CGFloat

    var body: some View {
        GearPatchFrame(s: s, bg: gearGrad(0x24303B, 0x12181E), stitch: Theme.gold.opacity(0.7)) {
            GearStarShape().fill(gearGoldGrad()).gearAt(s, 0.036, 0.036, 0, 0)
            GearShine(alpha: 0.5).gearAt(s, 0.008, 0.003, -0.004, -0.006, -30)
        }
    }
}
