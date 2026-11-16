import SwiftUI

// MARK: - Opgave-række med afkrydsning

struct HabitRow: View {
    @Environment(GameStore.self) private var store
    let habit: Habit
    var index: Int = 0
    var onEdit: () -> Void
    @State private var burst = 0

    var body: some View {
        let done = store.count(habit)
        let complete = done >= habit.timesPerDay
        HStack(spacing: 12) {
            Button(action: onEdit) {
                HStack(spacing: 12) {
                    Text(habit.icon)
                        .font(.system(size: 26))
                        .frame(width: 50, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(complete ? Theme.ready.opacity(0.18) : Theme.panelHigh)
                        )
                    VStack(alignment: .leading, spacing: 3) {
                        Text(String(format: "OPG. %02d · %@", index + 1, habit.category.title.uppercased()))
                            .font(.stencil(10, .bold))
                            .foregroundStyle(Theme.textSoft)
                        Text(habit.name)
                            .font(.tac(17, .bold))
                            .foregroundStyle(complete ? Theme.textSoft : Theme.text)
                            .strikethrough(complete, color: Theme.textSoft.opacity(0.6))
                            .lineLimit(2)
                        HStack(spacing: 8) {
                            if habit.timesPerDay > 1 {
                                Text("\(done)/\(habit.timesPerDay)")
                                    .contentTransition(.numericText(value: Double(done)))
                            }
                            if habit.reminderEnabled {
                                Label(habit.reminderText, systemImage: "bell.fill")
                            }
                            Text("+\(Tuning.creditsPerCompletion) cr · +\(Tuning.xpPerCompletion) xp")
                        }
                        .font(.stencil(11, .semibold))
                        .foregroundStyle(Theme.textSoft)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            ZStack {
                CheckButton(done: done, target: habit.timesPerDay) {
                    if store.tap(habit) { burst += 1 }
                }
                BurstView(trigger: burst, emojis: ["✨", "⭐️"], count: 5)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(complete ? Theme.ready.opacity(0.45) : Theme.line, lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: complete)
        .contextMenu {
            if done > 0 {
                Button { store.undo(habit) } label: { Label("Fortryd én", systemImage: "arrow.uturn.backward") }
            }
            Button(action: onEdit) { Label("Redigér", systemImage: "pencil") }
        }
    }
}

struct CheckButton: View {
    var done: Int
    var target: Int
    var action: () -> Void

    var body: some View {
        let complete = done >= target
        let progress = target > 0 ? Double(done) / Double(target) : 0
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(complete ? Theme.ready : Theme.panelHigh)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(complete ? Theme.ready : Theme.line, lineWidth: 2)
                if target > 1 && !complete {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Theme.tan, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .padding(12)
                    Text("\(done)")
                        .font(.stencil(14, .heavy))
                        .foregroundStyle(Theme.text)
                        .contentTransition(.numericText(value: Double(done)))
                }
                CheckMarkShape()
                    .trim(from: 0, to: complete ? 1 : 0)
                    .stroke(Theme.night, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    .padding(14)
                if target == 1 && !complete {
                    CheckMarkShape()
                        .stroke(Theme.line, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                        .padding(14)
                }
            }
            .frame(width: 54, height: 54)
        }
        .buttonStyle(BouncyStyle(scale: 0.86))
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: done)
        .sensoryFeedback(trigger: done) { old, new in
            if new > old {
                return new >= target ? SensoryFeedback.success : SensoryFeedback.impact(weight: .medium)
            }
            return SensoryFeedback.impact(weight: .light)
        }
    }
}

struct RestingHabitRow: View {
    let habit: Habit
    var onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                Text(habit.icon).font(.system(size: 20))
                    .frame(width: 38, height: 38)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.panelHigh))
                Text(habit.name)
                    .font(.tac(15, .semibold))
                    .foregroundStyle(Theme.textSoft)
                Spacer()
                Text(WeekdayPicker.summary(habit.weekdays))
                    .font(.stencil(11, .semibold))
                    .foregroundStyle(Theme.textSoft)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.panel.opacity(0.6)))
        }
        .buttonStyle(BouncyStyle(scale: 0.97))
    }
}

// MARK: - Opret / redigér opgave

struct HabitEditorView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let habit: Habit?

    @State private var name = ""
    @State private var icon = "🏃"
    @State private var category: HabitCategory = .exercise
    @State private var weekdays: Set<Int> = Set(1...7)
    @State private var times = 1
    @State private var reminder = false
    @State private var time = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var confirmRemove = false

    static let icons = ["🏃", "🏋️", "🚴", "🧘", "🛏️", "🌙", "📚", "🧠", "✍️", "🎓", "👨‍👩‍👦‍👦", "🍽️",
                        "💧", "🥦", "🦷", "💊", "🧹", "📵", "🚿", "🎵", "🐕", "☀️", "🧺", "❤️"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Text(icon)
                        .font(.system(size: 54))
                        .frame(width: 96, height: 96)
                        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.panelHigh))
                        .padding(.top, 6)

                    TextField("Opgave, fx '20 min. træning'", text: $name)
                        .font(.tac(19, .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.text)
                        .padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.panel))

                    section("Kategori") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                            ForEach(HabitCategory.allCases) { c in
                                Button {
                                    category = c
                                } label: {
                                    Label(c.title, systemImage: c.symbol)
                                        .font(.tac(13, .bold))
                                        .foregroundStyle(category == c ? Theme.night : Theme.text)
                                        .frame(maxWidth: .infinity, minHeight: 38)
                                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(category == c ? Theme.tan : Theme.panelHigh))
                                }
                                .buttonStyle(BouncyStyle())
                            }
                        }
                        Text("Balance mellem søvn, motion, læring og familie giver højere loadout-score.")
                            .font(.tac(11, .medium))
                            .foregroundStyle(Theme.textSoft)
                    }

                    section("Ikon") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                            ForEach(Self.icons, id: \.self) { e in
                                Button { icon = e } label: {
                                    Text(e).font(.system(size: 24))
                                        .frame(maxWidth: .infinity, minHeight: 42)
                                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(icon == e ? Theme.tan.opacity(0.35) : Theme.panelHigh))
                                }
                                .buttonStyle(BouncyStyle())
                            }
                        }
                    }

                    section("Hvilke dage?") {
                        WeekdayPicker(selection: $weekdays)
                        Text("Straf gælder kun planlagte dage – ikke fridage eller orlov.")
                            .font(.tac(11, .medium))
                            .foregroundStyle(Theme.textSoft)
                    }

                    section("Gange om dagen") {
                        HStack {
                            stepButton("minus") { times = max(1, times - 1) }
                            Text("\(times)")
                                .font(.stencil(28, .heavy))
                                .foregroundStyle(Theme.text)
                                .frame(minWidth: 60)
                                .contentTransition(.numericText(value: Double(times)))
                            stepButton("plus") { times = min(12, times + 1) }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    section("Påmindelse") {
                        Toggle(isOn: $reminder.animation(.spring)) {
                            Text("Radio-påmindelse").font(.tac(15, .semibold)).foregroundStyle(Theme.text)
                        }
                        .tint(Theme.tan)
                        if reminder {
                            DatePicker("Tidspunkt", selection: $time, displayedComponents: .hourAndMinute)
                                .font(.tac(15, .semibold))
                            Text("Højst \(NotificationScheduler.maxPerDay) påmindelser om dagen i alt.")
                                .font(.tac(11, .medium))
                                .foregroundStyle(Theme.textSoft)
                        }
                    }

                    Button(habit == nil ? "Tilføj opgave" : "Gem") { saveHabit() }
                        .buttonStyle(SoftButtonStyle(color: canSave ? Theme.tan : Theme.line))
                        .disabled(!canSave)

                    if habit != nil {
                        Button("Fjern opgaven") { confirmRemove = true }
                            .font(.tac(14, .semibold))
                            .foregroundStyle(Theme.textSoft)
                            .padding(.bottom, 20)
                    }
                }
                .padding(16)
            }
            .background(Theme.night.ignoresSafeArea())
            .navigationTitle(habit == nil ? "Ny opgave" : "Redigér opgave")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Luk") { dismiss() } }
            }
            .confirmationDialog("Fjern opgaven?", isPresented: $confirmRemove, titleVisibility: .visible) {
                Button("Ja, fjern den", role: .destructive) {
                    if let habit { store.archive(habit) }
                    dismiss()
                }
            } message: {
                Text("Den forsvinder fra listen. Historikken bevares.")
            }
        }
        .onAppear(perform: load)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !weekdays.isEmpty
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: title)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(Theme.night)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.tan))
        }
        .buttonStyle(BouncyStyle(scale: 0.85))
    }

    private func load() {
        guard let h = habit else { return }
        name = h.name
        icon = h.icon
        category = h.category
        weekdays = Set(h.weekdays)
        times = h.timesPerDay
        reminder = h.reminderEnabled
        time = Calendar.current.date(bySettingHour: h.reminderMinutes / 60, minute: h.reminderMinutes % 60, second: 0, of: Date()) ?? Date()
    }

    private func saveHabit() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let minutes = (comps.hour ?? 9) * 60 + (comps.minute ?? 0)
        let cleanName = name.trimmingCharacters(in: .whitespaces)
        if let h = habit {
            h.name = cleanName
            h.icon = icon
            h.category = category
            h.weekdays = weekdays.sorted()
            h.timesPerDay = times
            h.reminderEnabled = reminder
            h.reminderMinutes = minutes
            store.updated(h)
        } else {
            store.addHabit(name: cleanName, icon: icon, category: category, weekdays: weekdays.sorted(),
                           times: times, reminder: reminder, minutes: minutes)
        }
        dismiss()
    }
}

struct WeekdayPicker: View {
    @Binding var selection: Set<Int>

    static let days: [(Int, String)] = [(2, "M"), (3, "T"), (4, "O"), (5, "T"), (6, "F"), (7, "L"), (1, "S")]

    static func summary(_ weekdays: [Int]) -> String {
        let set = Set(weekdays)
        if set.count == 7 { return "Hver dag" }
        if set == Set([2, 3, 4, 5, 6]) { return "Hverdage" }
        if set == Set([1, 7]) { return "Weekend" }
        let names = [2: "man", 3: "tir", 4: "ons", 5: "tor", 6: "fre", 7: "lør", 1: "søn"]
        return days.filter { set.contains($0.0) }.compactMap { names[$0.0] }.joined(separator: ", ")
    }

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<Self.days.count, id: \.self) { i in
                let d = Self.days[i]
                let on = selection.contains(d.0)
                Button {
                    if on { selection.remove(d.0) } else { selection.insert(d.0) }
                } label: {
                    Text(d.1)
                        .font(.stencil(15, .heavy))
                        .foregroundStyle(on ? Theme.night : Theme.textSoft)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(on ? Theme.tan : Theme.panelHigh))
                }
                .buttonStyle(BouncyStyle(scale: 0.85))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selection)
    }
}

// MARK: - Dagsrapport (check-in)

struct ReportView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var choice: ReportChoice?
    @State private var note = ""
    @State private var saved = false

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Theme.line).frame(width: 44, height: 5).padding(.top, 10)
            Text(saved ? (choice?.reply ?? "") : "Dagsrapport: hvordan står det til?")
                .font(.tac(saved ? 17 : 22, .heavy))
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if saved {
                OperatorFigure(camo: store.profile.camo, skin: store.profile.skin, state: .ready,
                               equipped: store.service.equipped, condition: store.service.condition)
                    .frame(width: 150, height: 150)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            } else {
                HStack(spacing: 6) {
                    ForEach(ReportChoice.allCases) { m in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { choice = m }
                        } label: {
                            VStack(spacing: 4) {
                                Text(m.emoji).font(.system(size: choice == m ? 40 : 32))
                                Text(m.label)
                                    .font(.tac(11, .bold))
                                    .foregroundStyle(choice == m ? Theme.night : Theme.textSoft)
                            }
                            .frame(maxWidth: .infinity, minHeight: 80)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(choice == m ? Theme.tan : Theme.panel))
                        }
                        .buttonStyle(BouncyStyle())
                    }
                }
                .padding(.horizontal)
                .sensoryFeedback(.selection, trigger: choice)

                TextField("Valgfri note…", text: $note, axis: .vertical)
                    .font(.tac(15, .medium))
                    .lineLimit(1...4)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.panel))
                    .padding(.horizontal)
            }

            Spacer(minLength: 0)

            Button(saved ? "Modtaget" : "Send rapport (+\(Tuning.creditsCheckIn) cr)") {
                if saved {
                    dismiss()
                } else if let c = choice {
                    store.saveReport(c, note: note)
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { saved = true }
                }
            }
            .buttonStyle(SoftButtonStyle(color: choice == nil ? Theme.line : Theme.tan))
            .disabled(choice == nil)
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .background(Theme.night.ignoresSafeArea())
        .onAppear {
            if let m = store.todayReport {
                choice = ReportChoice(rawValue: m.mood)
                note = m.note
            }
        }
    }
}

// MARK: - Mission complete

struct MissionCompleteView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var shown = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x16301F), Theme.night], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Spacer()
                Text(store.operation.uppercased())
                    .font(.stencil(13, .bold))
                    .tracking(2)
                    .foregroundStyle(Theme.ready)
                Text("MISSION COMPLETE")
                    .font(.stencil(30, .black))
                    .foregroundStyle(Theme.text)
                    .scaleEffect(shown ? 1 : 0.6)
                    .opacity(shown ? 1 : 0)
                OperatorFigure(camo: store.profile.camo, skin: store.profile.skin, state: .ready,
                               equipped: store.service.equipped, condition: store.service.condition)
                    .frame(width: 220, height: 220)
                    .scaleEffect(shown ? 1 : 0.6)
                if shown {
                    VStack(spacing: 8) {
                        rewardLine("creditcard.fill", "+\(Tuning.creditsAllDoneBonus) credits bonus")
                        rewardLine("star.fill", "+\(Tuning.xpAllDoneBonus) tjenestepoint")
                        rewardLine("bolt.fill", "+\(Int(Tuning.readinessAllDoneBonus)) readiness")
                        if store.service.demotedFrom != nil {
                            rewardLine("arrow.uturn.up", "Comeback-dag \(store.service.comebackStreak + 1)/\(Tuning.Penalty.comebackDays) ved dagens afslutning")
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                Spacer()
                Button("Afslut debrief") {
                    store.markMissionCompleteSeen()
                    dismiss()
                }
                .buttonStyle(SoftButtonStyle(color: Theme.ready))
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.15)) { shown = true }
        }
        .onDisappear { store.markMissionCompleteSeen() }
        .sensoryFeedback(.success, trigger: shown)
    }

    private func rewardLine(_ symbol: String, _ text: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.tac(15, .bold))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Theme.panelHigh))
    }
}

// MARK: - Debrief (straf og hændelser siden sidst)

struct DebriefView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var events: [ServiceEvent] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    summary
                    SectionLabel(text: "Hændelser siden sidst", symbol: "list.bullet.clipboard")
                    ForEach(events) { e in
                        EventRow(event: e)
                    }
                    if events.contains(where: \.isPenalty) {
                        Text("Sådan kommer du tilbage: Løs alle dagens opgaver. \(Tuning.Penalty.comebackDays) missioner i træk giver en mistet rank tilbage, og slidt udstyr kan repareres i Loadout.")
                            .font(.tac(13, .medium))
                            .foregroundStyle(Theme.textSoft)
                            .card()
                    }
                }
                .padding(16)
            }
            .background(Theme.night.ignoresSafeArea())
            .navigationTitle("Debrief")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Forstået") { close() }.bold()
                }
            }
        }
        .onAppear { events = store.unseenEvents.reversed() }
        .onDisappear { store.markLogSeen() }
    }

    private var summary: some View {
        let lostR = events.reduce(0.0) { $0 + min(0, $1.readinessDelta) }
        let lostC = events.reduce(0) { $0 + min(0, $1.creditsDelta) }
        return HStack(spacing: 10) {
            stat("Readiness", lostR == 0 ? "±0" : Discipline.fmt(lostR), lostR < 0 ? Theme.alert : Theme.ready)
            stat("Credits", lostC == 0 ? "±0" : "\(lostC)", lostC < 0 ? Theme.alert : Theme.ready)
            stat("Rank", store.rank.short, Theme.tan)
        }
    }

    private func stat(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.stencil(20, .heavy)).foregroundStyle(color)
            Text(title.uppercased()).font(.stencil(10, .bold)).foregroundStyle(Theme.textSoft)
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    private func close() {
        store.markLogSeen()
        dismiss()
    }
}

struct EventRow: View {
    let event: ServiceEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(color.opacity(0.15)))
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title).font(.tac(15, .bold)).foregroundStyle(Theme.text)
                Text(event.detail).font(.tac(13, .regular)).foregroundStyle(Theme.textSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text(event.dayKey).font(.stencil(10, .medium)).foregroundStyle(Theme.textSoft.opacity(0.7))
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.panel))
    }

    private var symbol: String {
        switch event.kind {
        case .lostDay: return "xmark.octagon.fill"
        case .partialDay: return "circle.lefthalf.filled"
        case .fine: return "creditcard.trianglebadge.exclamationmark"
        case .wear: return "wrench.adjustable.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .demotion: return "chevron.down.2"
        case .demotionBlocked: return "arrow.down.to.line"
        case .grace: return "hand.raised.fill"
        case .promotion: return "chevron.up.2"
        case .comebackProgress: return "arrow.uturn.up"
        case .comeback: return "arrow.uturn.up.circle.fill"
        case .leaveStart: return "airplane.departure"
        case .leaveEnd: return "airplane.arrival"
        case .cardUsed: return "ticket.fill"
        case .suspended: return "exclamationmark.octagon.fill"
        case .merit: return "rosette"
        case .repair: return "wrench.and.screwdriver.fill"
        case .mission: return "flag.checkered"
        }
    }

    private var color: Color {
        switch event.kind {
        case .lostDay, .fine, .demotion, .suspended: return Theme.alert
        case .partialDay, .wear, .warning, .leaveStart: return Theme.amber
        case .promotion, .comeback, .comebackProgress, .merit, .leaveEnd, .mission: return Theme.ready
        default: return Theme.steady
        }
    }
}

struct BackOnDutyView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 14) {
            OperatorFigure(camo: store.profile.camo, skin: store.profile.skin, state: .ready,
                           equipped: store.service.equipped, condition: store.service.condition)
                .frame(width: 170, height: 170)
                .padding(.top, 24)
            Text("Tilbage i tjeneste")
                .font(.stencil(24, .heavy))
                .foregroundStyle(Theme.text)
            Text("Orloven er slut. Readiness er mindst \(Int(Tuning.readinessAfterLeave)), og holdet er glad for at se dig.")
                .font(.tac(15, .medium))
                .foregroundStyle(Theme.textSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Meld klar") { dismiss() }
                .buttonStyle(SoftButtonStyle(color: Theme.ready))
                .padding(.horizontal, 24)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Theme.night.ignoresSafeArea())
    }
}
