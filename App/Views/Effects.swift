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
    var foreground: Color = Theme.night

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.tac(17, .heavy))
            .textCase(.uppercase)
            .tracking(1)
            .foregroundStyle(foreground)
            .padding(.vertical, 15)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.45))
                        .offset(y: 4)
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
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
            .offset(y: shown ? 0 : 18)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) { shown = true }
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

    /// Mørkt panel med tynd kant.
    func card(_ color: Color = Theme.panel, radius: CGFloat = 16) -> some View {
        self
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(color)
                    .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Theme.line, lineWidth: 1))
            )
    }
}

// MARK: - Skrivemaskine-tekst (radiobesked)

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
                try? await Task.sleep(nanoseconds: 18_000_000)
            }
        }
    }
}

struct RadioBubble: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.ready)
                .padding(.top, 2)
            TypewriterText(text: text, font: .stencil(13, .semibold), color: Theme.text)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.black.opacity(0.55)))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Theme.ready.opacity(0.35), lineWidth: 1))
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

// MARK: - Segmenteret bjælke (readiness, stand, fremdrift)

struct SegmentBar: View {
    var progress: Double
    var tint: Color = Theme.ready
    var segments: Int = 20
    var height: CGFloat = 12

    var body: some View {
        let filled = Int((min(1, max(0, progress)) * Double(segments)).rounded())
        HStack(spacing: 2) {
            ForEach(0..<segments, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(i < filled ? tint : Theme.panelHigh)
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: filled)
    }
}

/// Lille sektionsoverskrift i stencil-stil.
struct SectionLabel: View {
    let text: String
    var symbol: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let symbol { Image(systemName: symbol) }
            Text(text.uppercased()).tracking(1.5)
        }
        .font(.stencil(12, .bold))
        .foregroundStyle(Theme.textSoft)
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
        .font(.stencil(15, .heavy))
        .foregroundStyle(Theme.text)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(Capsule().fill(Theme.panelHigh))
        .overlay(Capsule().stroke(Theme.amber.opacity(0.4), lineWidth: 1))
        .scaleEffect(bump % 2 == 1 ? 1.12 : 1)
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
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(Theme.panelHigh)
                .overlay(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous).stroke(Theme.tan.opacity(0.6), lineWidth: 1))
            if rank == .recruit {
                Circle().fill(Theme.tan).frame(width: size * 0.22)
            } else if rank.isOfficer {
                HStack(spacing: size * 0.04) {
                    ForEach(0..<rank.chevrons, id: \.self) { _ in
                        Image(systemName: "star.fill").font(.system(size: size * 0.32, weight: .black))
                    }
                }
                .foregroundStyle(Theme.gold)
            } else {
                VStack(spacing: -size * 0.12) {
                    ForEach(0..<rank.chevrons, id: \.self) { _ in
                        Image(systemName: "chevron.up").font(.system(size: size * 0.42, weight: .black))
                    }
                }
                .foregroundStyle(Theme.tan)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Lille "toast" øverst.
struct ToastView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.tac(14, .bold))
            .foregroundStyle(Theme.night)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(Theme.tan))
            .shadow(color: .black.opacity(0.4), radius: 8, y: 3)
    }
}
