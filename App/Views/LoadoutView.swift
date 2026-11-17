import SwiftUI

/// Loadout: hvad operatøren har på, i hvilken rækkefølge (lag), stand og score.
struct LoadoutView: View {
    @Environment(GameStore.self) private var store
    @State private var fitting = false
    @State private var category: GearCategory? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                HStack {
                    Text("Loadout").font(.tac(28, .heavy)).foregroundStyle(Theme.text)
                    Spacer()
                    CreditsBadge(credits: store.service.credits)
                }
                .padding(.top, 8)

                preview
                scoreCard
                equippedCard
                lockerCard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.night.ignoresSafeArea())
        .sheet(isPresented: $fitting) {
            FitEditorView(itemIDs: store.service.equipped)
        }
    }

    private var preview: some View {
        ZStack {
            SceneBackground(id: store.service.background)
            OperatorFigure(camo: store.profile.camo, skin: store.profile.skin, state: .steady,
                           equipped: store.service.equipped, condition: store.service.condition)
                .frame(width: 250, height: 250)
                .offset(y: 16)
            VStack {
                Spacer()
                HStack {
                    Text("\(store.service.equipped.count) stk. på")
                        .font(.stencil(12, .bold)).foregroundStyle(Theme.text)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Capsule().fill(.white))
                    Spacer()
                    Button { fitting = true } label: {
                        Label("Tilpas", systemImage: "slider.horizontal.3")
                            .font(.tac(13, .heavy)).foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(Capsule().fill(Theme.tan))
                    }
                    .buttonStyle(BouncyStyle())
                    .disabled(store.service.equipped.isEmpty)
                }
                .padding(10)
            }
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    // MARK: Score

    private var scoreCard: some View {
        let rates = store.categoryRates()
        let balance = store.balance
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                SectionLabel(text: "Loadout-score", symbol: "gauge.with.dots.needle.67percent")
                Text("\(store.loadoutScore)").font(.stencil(28, .black)).foregroundStyle(Theme.tan)
            }
            HStack(spacing: 8) {
                mini("Udstyr", "\(Int(store.gearScore.rounded()))")
                mini("Balance", "\(Int((balance * 100).rounded())) %")
                mini("Readiness", "\(Int(store.service.readiness.rounded()))")
            }
            ForEach(HabitCategory.balanced) { c in
                let r = rates[c] ?? -1
                HStack(spacing: 8) {
                    Image(systemName: c.symbol).frame(width: 20).foregroundStyle(Theme.textSoft)
                    Text(c.title).font(.tac(13, .semibold)).foregroundStyle(Theme.text).frame(width: 64, alignment: .leading)
                    if r < 0 {
                        Text("ingen opgaver").font(.tac(12, .medium)).foregroundStyle(Theme.textSoft)
                        Spacer()
                    } else {
                        SegmentBar(progress: r, tint: r >= 0.8 ? Theme.ready : (r >= 0.5 ? Theme.tan : Theme.amber), segments: 14, height: 8)
                        Text("\(Int((r * 100).rounded()))%").font(.stencil(11, .bold)).foregroundStyle(Theme.textSoft).frame(width: 40, alignment: .trailing)
                    }
                }
            }
            Text("Scoren stiger med udstyrets sjældenhed og stand – og med balance mellem søvn, motion, læring og familie de sidste \(Tuning.Loadout.balanceDays) dage.")
                .font(.tac(11, .medium)).foregroundStyle(Theme.textSoft)
        }
        .card()
    }

    private func mini(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.stencil(16, .heavy)).foregroundStyle(Theme.text)
            Text(title).font(.stencil(11, .bold)).foregroundStyle(Theme.textSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.panelHigh))
    }

    // MARK: Påtaget (lag)

    private var equippedCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionLabel(text: "Påtaget · øverste lag først", symbol: "square.3.layers.3d")
                if store.totalRepairCost > 0 {
                    Button {
                        repairAll()
                    } label: {
                        Label("Reparér alt \(store.totalRepairCost)", systemImage: "wrench.and.screwdriver.fill")
                            .font(.tac(11, .heavy)).foregroundStyle(.white)
                            .padding(.horizontal, 8).padding(.vertical, 5)
                            .background(Capsule().fill(Theme.amber))
                    }
                    .buttonStyle(BouncyStyle())
                }
            }
            if store.service.equipped.isEmpty {
                Text("Intet påtaget. Vælg udstyr i skabet herunder.")
                    .font(.tac(13, .medium)).foregroundStyle(Theme.textSoft)
            }
            ForEach(Array(store.service.equipped.enumerated().reversed()), id: \.element) { i, id in
                if let item = GearCatalog.item(id) {
                    EquippedRow(item: item, index: i, count: store.service.equipped.count)
                }
            }
        }
        .card()
    }

    private func repairAll() {
        var fixed = 0
        for id in store.service.equipped where store.repairCost(id) > 0 {
            if store.repair(id) { fixed += 1 }
        }
        store.flash(fixed > 0 ? "🔧 \(fixed) stk. repareret" : "For få credits til reparation")
    }

    // MARK: Skab (ejet udstyr)

    private var lockerCard: some View {
        let owned = store.service.owned.compactMap { GearCatalog.item($0) }.filter { $0.category != .background }
        let cats = GearCategory.allCases.filter { c in owned.contains { $0.category == c } }
        return VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Skab · tryk for at tage på/af (flere må stables)", symbol: "cabinet.fill")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    chip("Alt", selected: category == nil) { category = nil }
                    ForEach(cats) { c in chip(c.title, selected: category == c) { category = c } }
                }
            }
            let list = owned.filter { category == nil || $0.category == category }
            if list.isEmpty {
                Text("Skabet er tomt. Køb udstyr i Depot.").font(.tac(13, .medium)).foregroundStyle(Theme.textSoft)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(list) { item in
                    let on = store.isEquipped(item)
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { store.equip(item) }
                    } label: {
                        VStack(spacing: 4) {
                            ItemThumb(item: item, size: 64)
                            Text(item.name).font(.tac(11, .bold)).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .padding(6)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.panelHigh))
                        .overlay(alignment: .topTrailing) {
                            if on {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.ready).padding(4)
                            }
                        }
                    }
                    .buttonStyle(BouncyStyle())
                }
            }
        }
        .card()
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.tac(12, .bold))
                .foregroundStyle(selected ? Color.white : Theme.text)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().fill(selected ? Theme.tan : Theme.panelHigh))
        }
        .buttonStyle(BouncyStyle())
    }
}

struct EquippedRow: View {
    @Environment(GameStore.self) private var store
    let item: GearItem
    let index: Int
    let count: Int

    var body: some View {
        let cond = store.condition(item.id)
        let cost = store.repairCost(item.id)
        HStack(spacing: 10) {
            ItemThumb(item: item, size: 44)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Theme.panelHigh))
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(item.name).font(.tac(14, .bold)).foregroundStyle(Theme.text).lineLimit(1)
                    Circle().fill(item.rarity.color).frame(width: 6, height: 6)
                }
                HStack(spacing: 6) {
                    SegmentBar(progress: cond / 100, tint: cond >= 80 ? Theme.ready : (cond >= 50 ? Theme.amber : Theme.alert),
                               segments: 10, height: 5)
                        .frame(width: 70)
                    Text("\(Int(cond)) %").font(.stencil(12, .bold)).foregroundStyle(Theme.textSoft)
                }
            }
            Spacer(minLength: 4)
            if cost > 0 {
                Button { if !store.repair(item.id) { store.flash("Du mangler credits") } } label: {
                    Label("\(cost)", systemImage: "wrench.fill")
                        .font(.stencil(11, .heavy)).foregroundStyle(.white)
                        .padding(.horizontal, 7).padding(.vertical, 5)
                        .background(Capsule().fill(Theme.amber))
                }
                .buttonStyle(BouncyStyle())
            }
            layerButton("chevron.up", enabled: index < count - 1) { store.moveLayer(item.id, by: 1) }
            layerButton("chevron.down", enabled: index > 0) { store.moveLayer(item.id, by: -1) }
            layerButton("xmark", enabled: true) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { store.equip(item) }
            }
        }
    }

    private func layerButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(enabled ? Theme.text : Theme.line)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Theme.panelHigh))
        }
        .buttonStyle(BouncyStyle())
        .disabled(!enabled)
    }
}

// MARK: - Tilpas (placering, størrelse, rotation og lag)

struct FitEditorView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let itemIDs: [String]

    @State private var draft: [String: ItemFit] = [:]
    @State private var selected: String = ""
    @State private var dragStart: ItemFit?
    @State private var pinchStart: ItemFit?
    @State private var rotateStart: ItemFit?

    private let previewSize: CGFloat = 290
    private typealias A = Tuning.Anchor

    private var items: [GearItem] { itemIDs.compactMap { GearCatalog.item($0) }.reversed() }
    private var current: ItemFit { draft[selected] ?? .identity }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    if items.isEmpty {
                        Text("Tag noget udstyr på først – så kan du tilpasse det her.")
                            .font(.tac(15, .semibold)).foregroundStyle(Theme.textSoft)
                            .multilineTextAlignment(.center).card()
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.panel)
                            OperatorFigure(camo: store.profile.camo, skin: store.profile.skin, state: .steady,
                                           equipped: store.service.equipped, animated: false, fits: draft,
                                           condition: store.service.condition, highlight: selected)
                                .frame(width: previewSize, height: previewSize)
                        }
                        .frame(height: previewSize + 20)
                        .contentShape(Rectangle())
                        .gesture(dragGesture)
                        .simultaneousGesture(pinchGesture)
                        .simultaneousGesture(rotateGesture)

                        Text("Træk for at flytte · knib for størrelse · drej med to fingre")
                            .font(.tac(12, .semibold)).foregroundStyle(Theme.textSoft)

                        picker
                        sliders
                    }
                }
                .padding(16)
            }
            .background(Theme.night.ignoresSafeArea())
            .navigationTitle("Tilpas udstyr")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annullér") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Gem") { saveAndClose() }.bold() }
            }
        }
        .onAppear {
            var d: [String: ItemFit] = [:]
            for id in itemIDs { d[id] = FitStore.shared.fit(id) }
            draft = d
            if selected.isEmpty { selected = items.first?.id ?? "" }
        }
    }

    private var picker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items) { item in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selected = item.id }
                    } label: {
                        VStack(spacing: 2) {
                            ItemThumb(item: item, size: 40)
                            Text(item.name).font(.tac(11, .bold)).lineLimit(1)
                        }
                        .foregroundStyle(selected == item.id ? Color.white : Theme.text)
                        .frame(width: 78)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(selected == item.id ? Theme.tan : Theme.panel))
                    }
                    .buttonStyle(BouncyStyle())
                }
            }
        }
    }

    private var sliders: some View {
        VStack(alignment: .leading, spacing: 12) {
            fitSlider("Vandret", value: binding(\.dx), range: -A.maxOffset...A.maxOffset, step: 0.005,
                      label: String(format: "%.0f", current.dx * 100))
            fitSlider("Lodret", value: binding(\.dy), range: -A.maxOffset...A.maxOffset, step: 0.005,
                      label: String(format: "%.0f", current.dy * 100))
            fitSlider("Størrelse", value: binding(\.scale), range: A.minScale...A.maxScale, step: 0.01,
                      label: String(format: "%.0f%%", current.scale * 100))
            fitSlider("Rotation", value: binding(\.rotation), range: -180...180, step: 1,
                      label: String(format: "%.0f°", current.rotation))

            HStack(spacing: 8) {
                nudge("arrow.left") { change { $0.dx -= 0.005 } }
                nudge("arrow.right") { change { $0.dx += 0.005 } }
                nudge("arrow.up") { change { $0.dy -= 0.005 } }
                nudge("arrow.down") { change { $0.dy += 0.005 } }
                Spacer()
                Button("Nulstil") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { draft[selected] = .identity }
                }
                .font(.tac(14, .bold)).foregroundStyle(Theme.text)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Capsule().fill(Theme.panelHigh))
            }
            HStack(spacing: 8) {
                Text("Lag").font(.tac(14, .bold)).foregroundStyle(Theme.text)
                Spacer()
                Button { store.moveLayer(selected, by: 1) } label: {
                    Label("Frem", systemImage: "square.2.layers.3d.top.filled")
                }
                Button { store.moveLayer(selected, by: -1) } label: {
                    Label("Tilbage", systemImage: "square.2.layers.3d.bottom.filled")
                }
            }
            .font(.tac(13, .bold))
            .buttonStyle(.bordered)
        }
        .card()
    }

    private func fitSlider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title).font(.tac(14, .bold)).foregroundStyle(Theme.text)
                Spacer()
                Text(label).font(.stencil(12, .heavy)).foregroundStyle(Theme.tan).monospacedDigit()
            }
            Slider(value: value, in: range, step: step).tint(Theme.tan)
        }
    }

    private func nudge(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(Theme.text)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Theme.panelHigh))
        }
        .buttonStyle(BouncyStyle())
    }

    private func binding(_ key: WritableKeyPath<ItemFit, Double>) -> Binding<Double> {
        Binding(get: { current[keyPath: key] }, set: { v in change { $0[keyPath: key] = v } })
    }

    private func change(_ f: (inout ItemFit) -> Void) {
        guard !selected.isEmpty else { return }
        var fit = current
        f(&fit)
        fit.dx = min(A.maxOffset, max(-A.maxOffset, fit.dx))
        fit.dy = min(A.maxOffset, max(-A.maxOffset, fit.dy))
        fit.scale = min(A.maxScale, max(A.minScale, fit.scale))
        if fit.rotation > 180 { fit.rotation -= 360 }
        if fit.rotation < -180 { fit.rotation += 360 }
        draft[selected] = fit
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { v in
                if dragStart == nil { dragStart = current }
                guard let start = dragStart else { return }
                change {
                    $0.dx = start.dx + Double(v.translation.width / previewSize)
                    $0.dy = start.dy + Double(v.translation.height / previewSize)
                }
            }
            .onEnded { _ in dragStart = nil }
    }

    private var pinchGesture: some Gesture {
        MagnifyGesture()
            .onChanged { v in
                if pinchStart == nil { pinchStart = current }
                guard let start = pinchStart else { return }
                change { $0.scale = start.scale * Double(v.magnification) }
            }
            .onEnded { _ in pinchStart = nil }
    }

    private var rotateGesture: some Gesture {
        RotateGesture()
            .onChanged { v in
                if rotateStart == nil { rotateStart = current }
                guard let start = rotateStart else { return }
                change { $0.rotation = start.rotation + v.rotation.degrees }
            }
            .onEnded { _ in rotateStart = nil }
    }

    private func saveAndClose() {
        let fs = FitStore.shared
        for (id, fit) in draft { fs.set(fit, for: id) }
        fs.save()
        store.syncOutside()
        dismiss()
    }
}
