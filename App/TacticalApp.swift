import SwiftUI
import UserNotifications

@main
struct TacticalApp: App {
    @State private var store = GameStore()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .tint(Theme.tan)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { store.onForeground() }
                }
        }
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

struct RootView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ZStack {
            Theme.night.ignoresSafeArea()
            if store.profile.onboarded {
                MainView().transition(.opacity)
            } else {
                OnboardingView().transition(.opacity)
            }
        }
        .environment(\.operatorModel, store.bodyModel)
        .animation(.easeInOut(duration: 0.5), value: store.profile.onboarded)
        .preferredColorScheme(.light)
    }
}

// MARK: - Fanebjælke

enum AppTab: String, CaseIterable, Identifiable {
    case mission, loadout, armory, shop, rank
    var id: String { rawValue }
    var title: String {
        switch self {
        case .mission: return "Mission"
        case .loadout: return "Loadout"
        case .armory: return "Våbenskab"
        case .shop: return "Depot"
        case .rank: return "Rank"
        }
    }
    var icon: String {
        switch self {
        case .mission: return "scope"
        case .loadout: return "figure.stand"
        case .armory: return "lock.shield.fill"
        case .shop: return "cart.fill"
        case .rank: return "chevron.up.2"
        }
    }
}

struct MainView: View {
    @Environment(GameStore.self) private var store
    @State private var tab: AppTab = .mission
    @Namespace private var ns

    var body: some View {
        @Bindable var store = store
        ZStack(alignment: .top) {
            Group {
                switch tab {
                case .mission: MissionView()
                case .loadout: LoadoutView()
                case .armory: ArmoryView()
                case .shop: ShopView()
                case .rank: RankView()
                }
            }
            .transition(.opacity)

            if let t = store.toast {
                ToastView(text: t)
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.toast)
        .safeAreaInset(edge: .bottom, spacing: 0) { tabBar }
        .sheet(isPresented: $store.showMissionComplete) {
            MissionCompleteView().presentationDetents([.large])
        }
        .sheet(isPresented: $store.showDebrief) {
            DebriefView().presentationDetents([.large])
        }
        .sheet(isPresented: $store.showBackOnDuty) {
            BackOnDutyView().presentationDetents([.medium])
        }
    }

    private var tabBar: some View {
        HStack(spacing: 2) {
            ForEach(AppTab.allCases) { t in
                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) { tab = t }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: t.icon)
                            .font(.system(size: 18, weight: .bold))
                            .symbolEffect(.bounce, value: tab == t)
                        Text(t.title)
                            .font(.tac(11, .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(tab == t ? Theme.tan : Theme.textSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        if tab == t {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Theme.tanLight)
                                .matchedGeometryEffect(id: "tabPill", in: ns)
                        }
                    }
                }
                .buttonStyle(BouncyStyle())
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 14, y: 4)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
}
