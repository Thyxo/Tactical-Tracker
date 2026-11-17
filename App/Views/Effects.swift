import SwiftUI

// Fælles effekter, knapper og små byggeklodser (overført fra Sælliv, nyt tema).

struct BurstParticle: Identifiable {
    let id = UUID()
    let angle: Double
    let distance: CGFloat
    let emoji: String
    let spin: Double
    let size: CGFloat
}

struct BurstView: View {
    var trigger: Int
    var emojis: [String] = ["✨", "⭐️", "🎖️", "✨"]
    var count = 10

    @State private var particles: [BurstParticle] = []
    @State private var fired = false

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Text(p.emoji)
                    .font(.system(size: p.size))
                    .rotationEffect(.degrees(fired ? p.spin : 0))
                    .offset(x: fired ? CGFloat(cos(p.angle)) * p.distance : 0,
                            y: fired ? CGFloat(sin(p.angle)) * p.distance - 20 : 0)
                    .scaleEffect(fired ? 1.1 : 0.2)
                    .opacity(fired ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in fire() }
    }

    private func fire() {
        fired = false
        particles = (0..<count).map { i in
            BurstParticle(angle: Double(i) / Double(count) * 2 * .pi + Double.random(in: -0.3...0.3),
                          distance: CGFloat.random(in: 35...70),
                          emoji: emojis.randomElement() ?? "✨",
                          spin: Double.random(in: -200...200),
                          size: CGFloat.random(in: 14...22))
        }
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 1.3)) { fired = true }
        }
    }
}

// MARK: - Knapper

struct SoftButtonStyle: ButtonStyle {
    var color: Color = Theme.tan
    var foreground: Color = Theme.onAccent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.tac(17, .bold))
            .foregroundStyle(foreground)
            .padding(.vertical, 15)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(color.opacity(0.5))
                        .offset(y: 4)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(color)
                        .offset(y: configuration.isPressed ? 3 : 0)
                }
            )
            .offset(y: configuration.isPressed ? 3 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct BouncyStyle: ButtonStyle {
    var scale: CGFloat = 0.93
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

// MARK: - Modifiers

struct AppearIn: ViewModifier {
    var delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(delay)) { shown = true }
            }
    }
}

struct Wiggle: ViewModifier {
    var active: Bool
    @ViewBuilder func body(content: Content) -> some View {
        if active {
            content.phaseAnimator([0.0, -5.0, 5.0, -3.0, 0.0]) { view, angle in
                view.rotationEffect(.degrees(angle))
            } animation: { _ in .easeInOut(duration: 0.1) }
        } else {
            content
        }
    }
}

extension View {
    func appearIn(_ delay: Double = 0) -> some View { modifier(AppearIn(delay: delay)) }

    /// Hvidt kort med blød skygge – ingen kanter.
    func card(_ color: Color = Theme.panel, radius: CGFloat = 22) -> some View {
        self
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(color)
                    .shadow(color: Theme.shadow.opacity(0.05), radius: 10, x: 0, y: 4)
            )
    }
}

// MARK: - Skrivemaskine-tekst

struct TypewriterText: View {
    let text: String
    var font: Font = .tac(15, .medium)
    var color: Color = Theme.text
    @State private var shown = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(text).opacity(0)
            Text(String(text.prefix(shown)))
        }
        .font(font)
        .foregroundStyle(color)
        .task(id: text) {
            shown = 0
            for i in 0...text.count {
                shown = i
                try? await Task.sleep(nanoseconds: 20_000_000)
            }
        }
    }
}

/// Taleboble fra operatøren (som Sællivs boble).
struct RadioBubble: View {
    let text: String

    var body: some View {
        VStack(spacing: 0) {
            TypewriterText(text: text, font: .tac(15, .semibold), color: Theme.text)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
            BubbleTail()
                .fill(Theme.surface)
                .frame(width: 16, height: 9)
        }
        .shadow(color: Theme.shadow.opacity(0.10), radius: 8, x: 0, y: 3)
    }
}

struct BubbleTail: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Flueben

struct CheckMarkShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * 0.18, y: r.minY + r.height * 0.55))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.42, y: r.minY + r.height * 0.78))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.84, y: r.minY + r.height * 0.26))
        return p
    }
}

// MARK: - Fremgangsbjælke (blød, uden segmenter)

struct SegmentBar: View {
    var progress: Double
    var tint: Color = Theme.ready
    /// Bevaret for kompatibilitet – bjælken er nu glat.
    var segments: Int = 20
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.panelHigh)
                Capsule()
                    .fill(tint)
                    .frame(width: max(progress > 0 ? height : 0, g.size.width * min(1, max(0, progress))))
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
    }
}

/// Sektionsoverskrift.
struct SectionLabel: View {
    let text: String
    var symbol: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let symbol { Image(systemName: symbol).font(.system(size: 14, weight: .semibold)) }
            Text(text)
        }
        .font(.tac(16, .bold))
        .foregroundStyle(Theme.text)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Credits-tæller.
struct CreditsBadge: View {
    let credits: Int
    @State private var bump = 0

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "creditcard.fill").foregroundStyle(Theme.amber)
            Text("\(credits)")
                .contentTransition(.numericText(value: Double(credits)))
                .monospacedDigit()
        }
        .font(.tac(16, .bold))
        .foregroundStyle(Theme.text)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(Theme.surface).shadow(color: Theme.shadow.opacity(0.06), radius: 6, y: 2))
        .scaleEffect(bump % 2 == 1 ? 1.1 : 1)
        .onChange(of: credits) { old, new in
            guard new > old else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { bump += 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { bump += 1 }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: credits)
    }
}

/// Rank-distinktion (vinkler for menige/underofficerer, stjerner for officerer).
struct RankInsignia: View {
    let rank: Rank
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .fill(Theme.tanLight)
            if rank == .recruit {
                Circle().fill(Theme.tan).frame(width: size * 0.22)
            } else if rank.isOfficer {
                HStack(spacing: size * 0.04) {
                    ForEach(0..<rank.chevrons, id: \.self) { _ in
                        Image(systemName: "star.fill").font(.system(size: size * 0.3, weight: .bold))
                    }
                }
                .foregroundStyle(Theme.goldDark)
            } else {
                VStack(spacing: -size * 0.12) {
                    ForEach(0..<rank.chevrons, id: \.self) { _ in
                        Image(systemName: "chevron.up").font(.system(size: size * 0.4, weight: .heavy))
                    }
                }
                .foregroundStyle(Theme.tan)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Lille besked øverst.
struct ToastView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.tac(14, .bold))
            .foregroundStyle(Theme.onAccent)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(Theme.tan))
            .shadow(color: Theme.shadow.opacity(0.15), radius: 8, y: 3)
    }
}
