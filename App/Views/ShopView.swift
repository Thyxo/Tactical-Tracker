import SwiftUI

// MARK: - Depot (butik)

struct ShopView: View {
    @Environment(GameStore.self) private var store
    enum Section: String, CaseIterable, Identifiable {
        case gear, weapons, bases
        var id: String { rawValue }
        var title: String {
            switch self {
            case .gear: return "Udstyr"
            case .weapons: return "Våben"
            case .bases: return "Baser"
            }
        }
    }

    @State private var section: Section = .gear
    @State private var category: GearCategory = .helmet
    @State private var tryOn: GearItem?
    @State private var celebrate = 0
    @State private var shake = 0
    @State private var message: String?

    private var categories: [GearCategory] {
        switch section {
        case .gear: return GearCategory.gear
        case .weapons: return GearCategory.weapons
        case .bases: return [.background]
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                HStack {
                    Text("Depot").font(.tac(28, .heavy)).foregroundStyle(Theme.text)
                    Spacer()
                    CreditsBadge(credits: store.service.credits)
                }
                .padding(.top, 8)

                preview

                Picker("Afdeling", selection: $section) {
                    ForEach(Section.allCases) { s in Text(s.title).tag(s) }
                }
                .pickerStyle(.segmented)
                .onChange(of: section) { _, _ in
                    category = categories.first ?? .helmet
                    tryOn = nil
                }

                if categories.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(categories) { c in
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { category = c; tryOn = nil }
                                } label: {
                                    Label(c.title, systemImage: c.symbol)
                                        .font(.tac(12, .bold))
                                        .foregroundStyle(category == c ? Theme.onAccent : Theme.text)
                                        .padding(.horizontal, 10).padding(.vertical, 7)
                                        .background(Capsule().fill(category == c ? Theme.tan : Theme.panel))
                                }
                                .buttonStyle(BouncyStyle())
                            }
                        }
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(Array(GearCatalog.items(in: category).enumerated()), id: \.element.id) { i, item in
                        ShopItemCard(item: item, selected: tryOn?.id == item.id) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { tryOn = item }
                        } onAction: {
                            act(on: item)
                        }
                        .appearIn(Double(i) * 0.04)
                    }
                }
                .id(category)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.night.ignoresSafeArea())
    }

    private var previewEquipped: [String] {
        var list = store.service.equipped
        if let t = tryOn, t.category != .background, !list.contains(t.id) { list.append(t.id) }
        return list
    }

    private var preview: some View {
        let bg = tryOn?.category == .background ? (tryOn?.id ?? store.service.background) : store.service.background
        return ZStack {
            SceneBackground(id: bg).id(bg).transition(.opacity)
            OperatorFigure(camo: store.profile.camo, skin: store.profile.skin, state: .ready,
                           equipped: previewEquipped, condition: store.service.condition, highlight: tryOn?.id)
                .frame(width: 190, height: 190)
                .offset(y: 18)
                .modifier(Wiggle(active: shake % 2 == 1))
            BurstView(trigger: celebrate, emojis: ["✨", "⭐️", "🎖️"], count: 10)
            if let message {
                Text(message)
                    .font(.tac(14, .bold)).foregroundStyle(Theme.onAccent)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Capsule().fill(Theme.tan))
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .animation(.easeInOut(duration: 0.4), value: bg)
    }

    private var rankHint: some View {
        HStack(spacing: 6) {
            ForEach(Rarity.allCases) { r in
                let open = store.service.rank >= r.minRank
                HStack(spacing: 3) {
                    Circle().fill(r.color).frame(width: 7, height: 7)
                    Text(open ? r.displayName : (Rank(rawValue: r.minRank)?.short ?? "") + " 🔒")
                        .font(.tac(10, .bold))
                        .foregroundStyle(open ? Theme.text : Theme.textSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.panel))
    }

    private func act(on item: GearItem) {
        if store.owns(item) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                store.equip(item)
                tryOn = nil
            }
            return
        }
        switch store.buy(item) {
        case .bought:
            celebrate += 1
            tryOn = nil
            flash("Udleveret: \(item.name)")
        case .notEnough(let missing):
            shake += 1
            flash("Du mangler \(missing) credits")
        case .rankLocked(let r):
            shake += 1
            flash("Kræver rank \(r.displayName)")
        case .outOfSeason:
            flash("Kun i \(item.seasonName.lowercased())")
        case .alreadyOwned:
            break
        }
    }

    private func flash(_ text: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { message = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            if message == text { withAnimation(.easeOut) { message = nil } }
            shake = 0
        }
    }
}

struct ShopItemCard: View {
    @Environment(GameStore.self) private var store
    let item: GearItem
    let selected: Bool
    var onTry: () -> Void
    var onAction: () -> Void

    var body: some View {
        let owned = store.owns(item)
        let equipped = store.isEquipped(item)
        let locked = !owned && !store.rankAllows(item)
        VStack(spacing: 6) {
            Button(action: onTry) {
                ZStack(alignment: .topLeading) {
                    ItemThumb(item: item, size: 110)
                        .frame(maxWidth: .infinity)
                        .frame(height: 96)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.panelHigh))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .opacity(locked ? 0.45 : 1)
                    Circle()
                        .fill(item.rarity.color)
                        .frame(width: 9, height: 9)
                        .padding(9)
                    if item.isSeasonal {
                        Text(item.isInSeason ? "Sæson" : item.seasonName)
                            .font(.stencil(11, .heavy)).foregroundStyle(Theme.onAccent)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Capsule().fill(item.isInSeason ? Theme.alert : Theme.line))
                            .padding(5)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .buttonStyle(BouncyStyle(scale: 0.96))

            VStack(spacing: 1) {
                Text(item.name).font(.tac(14, .heavy)).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.8)
                Text(item.model).font(.tac(10, .medium)).foregroundStyle(Theme.textSoft).lineLimit(1).minimumScaleFactor(0.7)
            }

            Button(action: onAction) {
                Group {
                    if owned {
                        Text(equipped ? (item.category == .background ? "Valgt" : "Tag af") : (item.category == .background ? "Vælg" : "Tag på"))
                    } else if locked {
                        Label(Rank(rawValue: item.rarity.minRank)?.displayName ?? "", systemImage: "lock.fill")
                    } else {
                        Label("\(item.price)", systemImage: "creditcard.fill")
                    }
                }
                .font(.tac(13, .heavy))
                .foregroundStyle(owned && equipped ? Theme.text : Theme.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Capsule().fill(buttonColor(owned: owned, equipped: equipped, locked: locked)))
            }
            .buttonStyle(BouncyStyle())
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Theme.panel)
                .shadow(color: Theme.shadow.opacity(0.05), radius: 8, y: 3)
        )
        .scaleEffect(selected ? 1.02 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selected)
    }

    private func buttonColor(owned: Bool, equipped: Bool, locked: Bool) -> Color {
        if owned { return equipped ? Theme.panelHigh : Theme.ready }
        if locked || !item.isInSeason { return Theme.line }
        return store.service.credits >= item.price ? Theme.tan : Theme.textSoft.opacity(0.5)
    }
}

// MARK: - Våbenskab (galleri)

struct ArmoryView: View {
    @Environment(GameStore.self) private var store
    @State private var detail: GearItem?

    var body: some View {
        let weapons = GearCatalog.items.filter { $0.category.isWeapon }
        let owned = weapons.filter { store.owns($0) }.count
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Våbenskab").font(.tac(28, .heavy)).foregroundStyle(Theme.text)
                        Text("Samling: \(owned)/\(weapons.count) skins · kun til udstilling")
                            .font(.stencil(11, .bold)).foregroundStyle(Theme.textSoft)
                    }
                    Spacer()
                    CreditsBadge(credits: store.service.credits)
                }
                .padding(.top, 8)

                SegmentBar(progress: Double(owned) / Double(max(1, weapons.count)), tint: Theme.tan, segments: weapons.count, height: 8)

                ForEach(GearCategory.weapons) { c in
                    SectionLabel(text: c.title, symbol: "lock.shield")
                    VStack(spacing: 10) {
                        ForEach(GearCatalog.items(in: c)) { item in
                            Button { detail = item } label: { ArmoryRack(item: item) }
                                .buttonStyle(BouncyStyle(scale: 0.97))
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.night.ignoresSafeArea())
        .sheet(item: $detail) { item in
            WeaponDetailView(item: item).presentationDetents([.large])
        }
    }
}

/// Én hylde i våbenskabet. Ikke-ejede vises som mørk silhuet.
struct ArmoryRack: View {
    @Environment(GameStore.self) private var store
    let item: GearItem

    var body: some View {
        let owned = store.owns(item)
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.panelHigh, Theme.panel], startPoint: .top, endPoint: .bottom))
                WeaponDisplayView(id: item.id, size: 130)
                    .colorMultiply(owned ? Theme.onAccent : .black)
                    .opacity(owned ? 1 : 0.55)
                if !owned {
                    Image(systemName: "lock.fill").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.textSoft)
                }
            }
            .frame(width: 140, height: 86)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Circle().fill(item.rarity.color).frame(width: 7, height: 7)
                    Text(item.rarity.displayName).font(.stencil(11, .heavy)).foregroundStyle(item.rarity.color)
                }
                Text(item.name).font(.tac(16, .heavy)).foregroundStyle(Theme.text)
                Text(item.model).font(.tac(11, .medium)).foregroundStyle(Theme.textSoft).lineLimit(2)
                if owned {
                    Text(store.isEquipped(item) ? "Bæres" : "I skabet")
                        .font(.stencil(12, .bold)).foregroundStyle(store.isEquipped(item) ? Theme.ready : Theme.textSoft)
                } else {
                    Label("\(item.price)", systemImage: "creditcard.fill")
                        .font(.stencil(11, .bold)).foregroundStyle(Theme.amber)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.panel))
    }
}

struct WeaponDetailView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let item: GearItem
    @State private var spin = 0.0
    @State private var celebrate = 0

    var body: some View {
        let owned = store.owns(item)
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(RadialGradient(colors: [item.rarity.color.opacity(0.25), Theme.panel], center: .center, startRadius: 10, endRadius: 220))
                        WeaponDisplayView(id: item.id, size: 320)
                            .colorMultiply(owned ? Theme.onAccent : .black)
                            .rotation3DEffect(.degrees(spin), axis: (x: 0, y: 1, z: 0))
                        BurstView(trigger: celebrate, emojis: ["✨", "⭐️"], count: 10)
                    }
                    .frame(height: 240)
                    .onTapGesture { withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) { spin += 360 } }

                    VStack(spacing: 6) {
                        Text(item.rarity.displayName).font(.stencil(11, .heavy)).foregroundStyle(item.rarity.color)
                        Text(item.name).font(.tac(28, .heavy)).foregroundStyle(Theme.text)
                        Text(item.model).font(.tac(15, .semibold)).foregroundStyle(Theme.tan)
                        Text(item.blurb).font(.tac(14, .medium)).foregroundStyle(Theme.textSoft).multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    HStack(spacing: 8) {
                        info("Kategori", item.category.title)
                        info("Score", "+\(item.rarity.rating)")
                        info("Kræver", Rank(rawValue: item.rarity.minRank)?.displayName ?? "")
                    }

                    if owned {
                        Button(store.isEquipped(item) ? "Læg i skabet" : "Bær på figuren") { store.equip(item) }
                            .buttonStyle(SoftButtonStyle(color: store.isEquipped(item) ? Theme.panelHigh : Theme.ready,
                                                         foreground: store.isEquipped(item) ? Theme.text : Theme.onAccent))
                    } else {
                        Button("Køb for \(item.price) credits") { buy() }
                            .buttonStyle(SoftButtonStyle(color: store.rankAllows(item) && store.service.credits >= item.price ? Theme.tan : Theme.line))
                    }
                    Text("Kosmetisk skin til samlingen. Ingen skydning i appen.")
                        .font(.tac(11, .medium)).foregroundStyle(Theme.textSoft)
                }
                .padding(16)
            }
            .background(Theme.night.ignoresSafeArea())
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Luk") { dismiss() } } }
        }
    }

    private func info(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.tac(14, .heavy)).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.7)
            Text(title).font(.stencil(11, .bold)).foregroundStyle(Theme.textSoft)
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    private func buy() {
        switch store.buy(item) {
        case .bought:
            celebrate += 1
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) { spin += 360 }
        case .notEnough(let m): store.flash("Du mangler \(m) credits")
        case .rankLocked(let r): store.flash("Kræver rank \(r.displayName)")
        case .outOfSeason: store.flash("Ikke i sæson")
        case .alreadyOwned: break
        }
    }
}
