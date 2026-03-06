import SwiftUI
import SwiftData
import UserNotifications
import RevenueCat
import LocalAuthentication

@main
struct TeymiaHabitApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    let container: ModelContainer
    
    @State private var themeManager = ThemeManager.shared
    @State private var colorManager = AppColorManager.shared
    @State private var weekdayPrefs = WeekdayPreferences.shared
    @State private var privacyManager = PrivacyManager.shared
    @State private var timerService = TimerService.shared
    @State private var pendingDeeplink: Habit? = nil
    @State private var showingGlobalPinView = false
    @State private var globalPinTitle = ""
    @State private var globalPinCode = ""
    @State private var globalPinAction: ((String) -> Void)?
    @State private var globalPinDismiss: (() -> Void)?
    @State private var showingBiometricPromo = false
    @State private var globalBiometricType: LABiometryType = .none
    @State private var globalBiometricDisplayName = ""
    @State private var globalBiometricEnable: (() -> Void)?
    @State private var globalBiometricDismiss: (() -> Void)?
    
    init() {
        RevenueCatConfig.configure()
        PrivacyManager.shared.checkAndLockOnAppStart()
        
        let titleFont = UIFont.rounded(ofSize: 18, weight: .semibold)
        let largeTitleFont = UIFont.rounded(ofSize: 34, weight: .bold)

        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.titleTextAttributes = [.font: titleFont]
        standardAppearance.largeTitleTextAttributes = [.font: largeTitleFont]

        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        scrollEdgeAppearance.titleTextAttributes = [.font: titleFont]
        scrollEdgeAppearance.largeTitleTextAttributes = [.font: largeTitleFont]

        UINavigationBar.appearance().standardAppearance = standardAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearance
        
        do {
            let schema = Schema([Habit.self, HabitCompletion.self])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.amanbayserkeev.teymiahabit")
            )
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .environment(themeManager)
                    .environment(colorManager)
                    .environment(weekdayPrefs)
                    .environment(privacyManager)
                    .environment(ProManager.shared)
                    .environment(timerService)
                    .environment(\.globalPin, globalPinEnvironment)
                    .onAppear {
                        setupLiveActivities()
                        AppModelContext.shared.setModelContext(container.mainContext)
                    }
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                        try? container.mainContext.save()
                    }
                
                if privacyManager.isAppLocked {
                    AppLockView()
                        .transition(.opacity)
                        .zIndex(10000)
                        .allowsHitTesting(true)
                }
                
                if showingGlobalPinView {
                    GlobalPinView(
                        title: globalPinTitle,
                        pin: $globalPinCode,
                        onPinComplete: { pin in
                            globalPinAction?(pin)
                        },
                        onDismiss: {
                            globalPinDismiss?()
                        }
                    )
                    .transition(.opacity)
                    .zIndex(2000)
                }
                
                if showingBiometricPromo {
                    BiometricPromoView(
                        onEnable: {
                            globalBiometricEnable?()
                        },
                        onDismiss: {
                            globalBiometricDismiss?()
                        }
                    )
                    .transition(.opacity)
                    .zIndex(2500)
                }
            }
            .onChange(of: privacyManager.isAppLocked) { _, newValue in
                if !newValue && pendingDeeplink != nil {
                    handlePendingDeeplink()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: privacyManager.isAppLocked)
            .animation(.easeInOut(duration: 0.3), value: showingGlobalPinView)
            .animation(.easeInOut(duration: 0.3), value: showingBiometricPromo)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // MARK: - Scene Phase Management
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            handleAppBackground()
            privacyManager.handleAppWillResignActive()
            
        case .inactive:
            try? container.mainContext.save()
            
        case .active:
            handleAppForeground()
            privacyManager.handleAppDidBecomeActive()
            
        @unknown default:
            break
        }
    }
    
    // MARK: - DeepLink Handling
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "teymiahabit",
              url.host == "habit",
              let habitId = url.pathComponents.last,
              let habitUUID = UUID(uuidString: habitId) else {
            return
        }
        
        Task { @MainActor in
            let descriptor = FetchDescriptor<Habit>(
                predicate: #Predicate<Habit> { habit in
                    habit.uuid == habitUUID && !habit.isArchived
                }
            )
            
            guard let foundHabit = try? container.mainContext.fetch(descriptor).first else {
                return
            }
            
            if privacyManager.isAppLocked {
                pendingDeeplink = foundHabit
            } else {
                openHabitDirectly(foundHabit)
            }
        }
    }
    
    private func handlePendingDeeplink() {
        guard let habit = pendingDeeplink else { return }
        
        NotificationCenter.default.post(name: .dismissAllSheets, object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.openHabitDirectly(habit)
            self.pendingDeeplink = nil
        }
    }
    
    private func openHabitDirectly(_ habit: Habit) {
        NotificationCenter.default.post(
            name: .openHabitFromDeeplink,
            object: habit
        )
    }
    
    // MARK: - Live Activities Setup
    
    private func setupLiveActivities() {
        Task {
            await HabitLiveActivityManager.shared.restoreActiveActivitiesIfNeeded()
        }
    }
    
    // MARK: - App Lifecycle Methods
    
    private func handleAppBackground() {
        try? container.mainContext.save()
        
        if privacyManager.isPrivacyEnabled {
            NotificationCenter.default.post(name: .dismissAllSheets, object: nil)
        }
        
        TimerService.shared.handleAppDidEnterBackground()
    }
    
    private func handleAppForeground() {
        WidgetUpdateService.shared.reloadWidgets()
        TimerService.shared.handleAppWillEnterForeground()
        
        // Check for pending habit from widget
        checkPendingHabitFromWidget()
        
        Task {
            await HabitLiveActivityManager.shared.restoreActiveActivitiesIfNeeded()
        }
    }
    
    // MARK: - Widget Deep Link Handling

    private func checkPendingHabitFromWidget() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.amanbayserkeev.teymiahabit"),
              let habitIdString = sharedDefaults.string(forKey: "pendingHabitIdFromWidget"),
              UUID(uuidString: habitIdString) != nil else {
            return
        }
        
        // Clear the flag immediately
        sharedDefaults.removeObject(forKey: "pendingHabitIdFromWidget")
        sharedDefaults.synchronize()
        
        // Create deep link URL and handle it
        if let url = URL(string: "teymiahabit://habit/\(habitIdString)") {
            handleDeepLink(url)
        }
    }
    
    // MARK: - Global PIN Environment
    
    private var globalPinEnvironment: GlobalPinEnvironment {
        GlobalPinEnvironment(
            showPin: { title, onComplete, onDismiss in
                globalPinTitle = title
                globalPinCode = ""
                globalPinAction = onComplete
                globalPinDismiss = onDismiss
                showingGlobalPinView = true
            },
            hidePin: {
                showingGlobalPinView = false
                globalPinCode = ""
                globalPinAction = nil
                globalPinDismiss = nil
            },
            showBiometricPromo: { biometricType, displayName, onEnable, onDismiss in
                globalBiometricType = biometricType
                globalBiometricDisplayName = displayName
                globalBiometricEnable = onEnable
                globalBiometricDismiss = onDismiss
                showingBiometricPromo = true
            },
            hideBiometricPromo: {
                showingBiometricPromo = false
                globalBiometricType = .none
                globalBiometricDisplayName = ""
                globalBiometricEnable = nil
                globalBiometricDismiss = nil
            }
        )
    }
}

// MARK: - Global PIN Environment

struct GlobalPinEnvironment {
    let showPin: (String, @escaping (String) -> Void, @escaping () -> Void) -> Void
    let hidePin: () -> Void
    let showBiometricPromo: (LABiometryType, String, @escaping () -> Void, @escaping () -> Void) -> Void
    let hideBiometricPromo: () -> Void
}

struct GlobalPinEnvironmentKey: EnvironmentKey {
   static let defaultValue = GlobalPinEnvironment(
       showPin: { _, _, _ in },
       hidePin: { },
       showBiometricPromo: { _, _, _, _ in },
       hideBiometricPromo: { }
   )
}

extension EnvironmentValues {
   var globalPin: GlobalPinEnvironment {
       get { self[GlobalPinEnvironmentKey.self] }
       set { self[GlobalPinEnvironmentKey.self] = newValue }
   }
}
