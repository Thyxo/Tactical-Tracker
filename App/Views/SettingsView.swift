import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var notifications = NotificationScheduler.enabled
    @State private var maxPerDay = NotificationScheduler.maxPerDay
    @State private var liveActivity = LiveActivityManager.enabled
    @State private var autoCard = true
    @State private var shareFile: ShareFile?
    @State private var importing = false
    @State private var status: String?
    @State private var confirmImportURL: URL?
    @State private var developer = false

    var body: some View {
        let p = store.profile
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    VStack(spacing: 10) {
                        OperatorFigure(camo: p.camo, skin: p.skin, state: store.displayState,
                                       equipped: store.service.equipped, condition: store.service.condition)
                            .frame(width: 140, height: 140)
                        TextField("Kaldesignal", text: $name)
                            .font(.tac(20, .heavy))
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 9)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.panelHigh))
                            .onSubmit { saveName() }
                        SectionLabel(text: "Uniform")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(Camo.allCases) { c in
                                    swatch(c.main, c.displayName, selected: p.camo == c) {
                                        p.camo = c
                                        store.save()
                                        store.syncOutside()
                                    }
                                }
                            }
                        }
                        SectionLabel(text: "Hudfarve")
                        HStack(spacing: 6) {
                            ForEach(SkinTone.allCases) { t in
                                swatch(t.main, t.displayName, selected: p.skin == t) {
                                    p.skin = t
                                    store.save()
                                    store.syncOutside()
                                }
                            }
                        }
                    }
                    .card()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "Figur", symbol: "figure.stand")
                        Text("Vælg hvordan din operatør ser ud. Udstyret tilpasser sig automatisk.")
                            .font(.tac(13, .medium)).foregroundStyle(Theme.textSoft)
                        ModelPicker()
                    }
                    .card()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "Påmindelser", symbol: "bell.fill")
                        Toggle(isOn: $notifications) { rowText("Radio-påmindelser") }
                            .tint(Theme.tan)
                            .onChange(of: notifications) { _, v in
                                NotificationScheduler.enabled = v
                                if v { NotificationScheduler.requestAuthorization() }
                                store.syncOutside()
                            }
                        HStack {
                            rowText("Maks. pr. dag")
                            Spacer()
                            Picker("", selection: $maxPerDay) {
                                Text("1").tag(1)
                                Text("2").tag(2)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 110)
                            .onChange(of: maxPerDay) { _, v in
                                NotificationScheduler.maxPerDay = v
                                store.syncOutside()
                            }
                        }
                        Toggle(isOn: $liveActivity) { rowText("Dagens mission på låseskærmen") }
                            .tint(Theme.tan)
                            .onChange(of: liveActivity) { _, v in
                                LiveActivityManager.enabled = v
                                store.syncOutside()
                            }
                    }
                    .card()

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: "Disciplin", symbol: "scale.3d")
                        Toggle(isOn: $autoCard) { rowText("Brug orlovskort automatisk") }
                            .tint(Theme.tan)
                            .onChange(of: autoCard) { _, v in
                                store.service.autoLeaveCard = v
                                store.save()
                            }
                        Text("Første tabte dag hver uge dækkes automatisk. Slå fra, hvis du vil spare kortet til manuel brug.")
                            .font(.tac(12, .medium)).foregroundStyle(Theme.textSoft)
                    }
                    .card()

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: "Backup", symbol: "externaldrive.fill")
                        Text("Sideloadede apps udløber efter 7 dage. Gem en backup, så du altid kan hente \(p.callsign) tilbage.")
                            .font(.tac(13, .medium)).foregroundStyle(Theme.textSoft)
                        if let last = p.lastBackup {
                            Text("Sidste backup: \(last.formatted(date: .abbreviated, time: .shortened))")
                                .font(.stencil(12, .semibold)).foregroundStyle(Theme.tan)
                        }
                        Button("Eksportér backup") { exportBackup() }
                            .buttonStyle(SoftButtonStyle())
                        Button("Importér backup") { importing = true }
                            .buttonStyle(SoftButtonStyle(color: Theme.panelHigh, foreground: Theme.text))
                        if let status {
                            Text(status).font(.tac(13, .semibold)).foregroundStyle(Theme.text)
                        }
                    }
                    .card()

                    VStack(alignment: .leading, spacing: 6) {
                        SectionLabel(text: "Om appen", symbol: "info.circle")
                        Text("Alt ligger lokalt på telefonen. Ingen konto, ingen server, ingen iCloud. Våben er kosmetiske samleobjekter – der skydes ikke i appen.")
                            .font(.tac(13, .medium)).foregroundStyle(Theme.textSoft)
                        Text(AppGroup.isShared ? "Widget-deling: aktiv ✓" : "Widget-deling: ikke tilgængelig (App Group mangler)")
                            .font(.tac(11, .semibold)).foregroundStyle(Theme.textSoft)
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                            .font(.tac(11, .semibold)).foregroundStyle(Theme.textSoft)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()

                    Button { developer = true } label: {
                        HStack {
                            Image(systemName: "hammer.fill")
                            Text("Udviklermenu")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.tac(14, .bold)).foregroundStyle(Theme.textSoft)
                        .card()
                    }
                    .buttonStyle(BouncyStyle(scale: 0.97))
                }
                .padding(16)
            }
            .background(Theme.night.ignoresSafeArea())
            .navigationTitle("Operatør")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Luk") { saveName(); dismiss() } } }
        }
        .onAppear {
            name = store.profile.callsign
            autoCard = store.service.autoLeaveCard
        }
        .onDisappear { saveName() }
        .sheet(item: $shareFile) { f in ActivityView(items: [f.url]) }
        .sheet(isPresented: $developer) { DeveloperView() }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result { confirmImportURL = url }
        }
        .confirmationDialog("Importér backup?", isPresented: Binding(get: { confirmImportURL != nil }, set: { if !$0 { confirmImportURL = nil } }), titleVisibility: .visible) {
            Button("Ja, erstat mine data", role: .destructive) {
                if let url = confirmImportURL { importBackup(url) }
                confirmImportURL = nil
            }
        } message: {
            Text("Det, der ligger i appen nu, bliver erstattet af backuppen.")
        }
    }

    private func swatch(_ color: Color, _ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Circle().fill(color).frame(width: 30, height: 30)
                    .padding(3)
                    .background(Circle().fill(selected ? Theme.tan : Color.clear))
                Text(title).font(.tac(10, .bold)).foregroundStyle(selected ? Theme.text : Theme.textSoft).lineLimit(1)
            }
            .frame(minWidth: 62)
        }
        .buttonStyle(BouncyStyle())
    }

    private func rowText(_ t: String) -> some View {
        Text(t).font(.tac(15, .semibold)).foregroundStyle(Theme.text)
    }

    private func saveName() {
        let clean = name.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty, clean != store.profile.callsign else { return }
        store.profile.callsign = clean
        store.save()
        store.syncOutside()
    }

    private func exportBackup() {
        do {
            let url = try BackupManager.makeFile(store: store)
            shareFile = ShareFile(url: url)
            store.didExportBackup()
            withAnimation { status = "Backup klar – gem den i Filer 💾" }
        } catch {
            withAnimation { status = "Backuppen fejlede. Prøv igen." }
        }
    }

    private func importBackup(_ url: URL) {
        do {
            try BackupManager.restore(from: url, store: store)
            name = store.profile.callsign
            withAnimation { status = "Backup hentet. Velkommen tilbage." }
        } catch {
            withAnimation { status = error.localizedDescription }
        }
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    @Environment(GameStore.self) private var store
    @State private var step = 0
    @State private var callsign = ""
    @State private var camo: Camo = .black
    @State private var skin: SkinTone = .light

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 10)
            OperatorFigure(camo: camo, skin: skin, state: step == 0 ? .steady : .ready,
                           equipped: step >= 2 ? ["vest_police", "cap_swat"] : [])
                .frame(width: 230, height: 230)
            switch step {
            case 0:
                text("Velkommen, rekrut",
                     "Dine vaner bliver til daglige missioner. Løs dem, og din operatør stiger i readiness, credits og rank. Spring dem over, og der er konsekvenser.")
            case 1:
                VStack(spacing: 12) {
                    text("Dit kaldesignal", "Hvad skal holdet kalde dig?")
                    TextField("Fx Ulv, Falk, Viking", text: $callsign)
                        .font(.tac(22, .heavy))
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.panel))
                        .padding(.horizontal, 24)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(Camo.allCases) { c in
                                option(c.displayName, c.main, selected: camo == c) { camo = c }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    HStack(spacing: 6) {
                        ForEach(SkinTone.allCases) { t in
                            option(t.displayName, t.main, selected: skin == t) { skin = t }
                        }
                    }
                    .padding(.horizontal, 24)
                    HStack(spacing: 6) {
                        ForEach(BodyModel.allCases) { m in
                            Button(m.displayName) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { store.bodyModel = m }
                            }
                            .font(.tac(12, .bold))
                            .foregroundStyle(store.bodyModel == m ? .white : Theme.text)
                            .padding(.horizontal, 10).padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Capsule().fill(store.bodyModel == m ? Theme.tan : Theme.panel))
                        }
                    }
                    .padding(.horizontal, 24)
                }
            default:
                text("Regler i korte træk",
                     "• Under halvdelen løst = tabt dag: −\(Int(Tuning.Penalty.readinessMissedDay)) readiness, bøde og slid.\n• \(Tuning.Penalty.warningAfterLostDays) i træk = advarsel, \(Tuning.Penalty.demoteAfterLostDays) = nedrykning.\n• 1 orlovskort pr. uge. Fridage straffes aldrig.\n• \(Tuning.Penalty.comebackDays) missioner i træk giver en mistet rank tilbage.")
            }
            Spacer(minLength: 10)
            Button(step < 2 ? "Videre" : "Meld klar") {
                if step < 2 {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { step += 1 }
                } else {
                    NotificationScheduler.requestAuthorization()
                    store.finishOnboarding(callsign: callsign, camo: camo, skin: skin)
                }
            }
            .buttonStyle(SoftButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(Theme.night.ignoresSafeArea())
    }

    private func text(_ title: String, _ body: String) -> some View {
        VStack(spacing: 10) {
            Text(title).font(.tac(26, .heavy)).foregroundStyle(Theme.text).multilineTextAlignment(.center)
            Text(body).font(.tac(15, .medium)).foregroundStyle(Theme.textSoft)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 28)
        }
    }

    private func option(_ title: String, _ color: Color, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 16, height: 16)
                Text(title).font(.tac(12, .bold)).lineLimit(1)
            }
            .foregroundStyle(selected ? Color.white : Theme.text)
            .padding(.horizontal, 10).padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(selected ? Theme.tan : Theme.panel))
        }
        .buttonStyle(BouncyStyle())
    }
}

// MARK: - Udviklermenu (test af straf og tilstande)

struct DeveloperView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var readiness: Double = 70

    var body: some View {
        NavigationStack {
            List {
                Section("Simulér dage (regelmotoren)") {
                    Button("Tabt dag (0 % løst)") { store.debugSimulateDay(ratio: 0) }
                    Button("Tabt dag (25 % løst)") { store.debugSimulateDay(ratio: 0.25) }
                    Button("Delvis dag (60 % løst)") { store.debugSimulateDay(ratio: 0.6) }
                    Button("Mission complete-dag") { store.debugSimulateDay(ratio: 1) }
                    Button("Nulstil ugens orlovskort") { store.debugResetLeaveCard() }
                }
                Section("Readiness") {
                    Slider(value: $readiness, in: 0...100, step: 1) { Text("Readiness") }
                    Button("Sæt readiness til \(Int(readiness))") { store.debugSetReadiness(readiness) }
                    Button("2 dage på 0 (suspenderet)") { store.debugSetDaysAtZero(2) }
                }
                Section("Vis tilstand") {
                    ForEach(ReadinessState.allCases, id: \.self) { s in
                        Button(s.displayName) { store.debugStateOverride = s }
                    }
                    Button("Normal visning") { store.debugStateOverride = nil }
                }
                Section("Ressourcer") {
                    Button("+100 credits") { store.debugAddCredits(100) }
                    Button("+1000 credits") { store.debugAddCredits(1000) }
                    Button("+300 xp") { store.debugAddXP(300) }
                }
                Section("Orlov") {
                    Button("Start orlov") { store.debugStartLeave() }
                    Button("Afslut orlov") { store.debugEndLeave() }
                }
                Section {
                    Button("Nulstil onboarding", role: .destructive) { store.debugResetOnboarding() }
                }
            }
            .navigationTitle("Udviklermenu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Luk") { dismiss() } } }
        }
        .onAppear { readiness = store.service.readiness }
    }
}

// MARK: - Vælg figur-model

struct ModelPicker: View {
    @Environment(GameStore.self) private var store
    var camo: Camo? = nil
    var skin: SkinTone? = nil

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(BodyModel.allCases) { m in
                let on = store.bodyModel == m
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { store.bodyModel = m }
                } label: {
                    VStack(spacing: 4) {
                        OperatorFigure(camo: camo ?? store.profile.camo, skin: skin ?? store.profile.skin,
                                       state: .ready, equipped: store.service.equipped,
                                       animated: false, model: m)
                            .frame(height: 130)
                        Text(m.displayName).font(.tac(15, .bold)).foregroundStyle(Theme.text)
                        Text(m.subtitle).font(.tac(11, .medium)).foregroundStyle(Theme.textSoft)
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(on ? Theme.tanLight : Theme.panelHigh))
                    .overlay(alignment: .topTrailing) {
                        if on {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Theme.tan)
                                .padding(8)
                        }
                    }
                }
                .buttonStyle(BouncyStyle(scale: 0.96))
            }
        }
    }
}
