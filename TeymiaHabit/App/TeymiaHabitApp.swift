import SwiftUI
import SwiftData
import UserNotifications
import RevenueCat
import LocalAuthentication

@main
struct TeymiaHabitApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    
    let container: ModelContainer
    
    @State private var weekdayPrefs = WeekdayPreferences.shared
    @State private var privacyManager = PrivacyManager.shared
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
        // Configure RevenueCat FIRST
        RevenueCatConfig.configure()
        
        // Print current app configuration
        print("🚀 Starting Teymia Habit")
        print("📦 Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        print("☁️ CloudKit Container: iCloud.com.amanbayserkeev.teymiahabit")
        PrivacyManager.shared.checkAndLockOnAppStart()

        
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
            
            print("✅ Local storage initialized successfully")
            print("✅ CloudKit container initialized: iCloud.com.amanbayserkeev.teymiahabit")
        } catch {
            print("❌ ModelContainer initialization error: \(error)")
            fatalError("Не удалось создать ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .environment(weekdayPrefs)
                    .environment(ProManager.shared)
                    .environment(\.globalPin, globalPinEnvironment)
                    .onAppear {
                        setupLiveActivities()
                        AppModelContext.shared.setModelContext(container.mainContext)
                        ProDowngradeCoordinator.shared.setModelContext(container.mainContext)
                    }
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                        handleAppTermination()
                    }
                
                let _ = print("🔐 TeymiaHabitApp: Checking isAppLocked = \(privacyManager.isAppLocked)")
                
                // ✅ ИСПРАВЛЕНИЕ 1: Проверяем блокировку и обрабатываем pending deeplink
                if privacyManager.isAppLocked {
                    PrivacyLockView()
                        .transition(.opacity)
                        .zIndex(10000)
                        .allowsHitTesting(true)
                        .onAppear {
                            print("🔐 TeymiaHabitApp: PrivacyLockView appeared")
                        }
                        .onDisappear {
                            print("🔐 TeymiaHabitApp: PrivacyLockView disappeared")
                        }
                }
                
                // ✅ Глобальный PIN overlay
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
                
                // ✅ Биометрический промо overlay
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
                    .zIndex(2500) // Выше чем PIN
                }
            }
            .environment(privacyManager)
            .onChange(of: privacyManager.isAppLocked) { _, newValue in
                if !newValue && pendingDeeplink != nil {
                    print("🔓 App unlocked at APP LEVEL - processing pending deeplink")
                    if let habit = pendingDeeplink {
                        NotificationCenter.default.post(name: .dismissAllSheets, object: nil)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            openHabitDirectly(habit)
                            pendingDeeplink = nil
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: privacyManager.isAppLocked)
            .animation(.easeInOut(duration: 0.3), value: showingGlobalPinView)
            .animation(.easeInOut(duration: 0.3), value: showingBiometricPromo)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                handleAppBackground()
                privacyManager.handleAppWillResignActive()
                
            case .inactive:
                print("📱 App becoming inactive")
                saveDataContext()
                
            case .active:
                print("📱 App became active")
                handleAppForeground()
                privacyManager.handleAppDidBecomeActive()
                
            @unknown default:
                print("📱 Unknown scene phase")
                break
            }
        }
    }
    
    // MARK: - DeepLink Handler
    
    private func handleDeepLink(_ url: URL) {
        print("🔗 Received deeplink: \(url)")
        
        guard url.scheme == "teymiahabit" else {
            print("⚠️ Unknown URL scheme: \(url.scheme ?? "nil")")
            return
        }
        
        guard url.host == "habit" else {
            print("⚠️ Unknown URL host: \(url.host ?? "nil")")
            return
        }
        
        let pathComponents = url.pathComponents
        guard pathComponents.count >= 2,
              let habitId = pathComponents.last else {
            print("⚠️ Invalid URL path: \(url.path)")
            return
        }
        
        print("✅ Deeplink to habit: \(habitId)")
        
        // ✅ ИСПРАВЛЕНИЕ: Ищем привычку и проверяем блокировку
        Task { @MainActor in
            do {
                guard let habitUUID = UUID(uuidString: habitId) else {
                    print("❌ Invalid habit UUID: \(habitId)")
                    return
                }
                
                let descriptor = FetchDescriptor<Habit>(
                    predicate: #Predicate<Habit> { habit in
                        habit.uuid == habitUUID && !habit.isArchived
                    }
                )
                
                let habits = try container.mainContext.fetch(descriptor)
                
                if let foundHabit = habits.first {
                    print("✅ Found habit for deeplink: \(foundHabit.title)")
                    
                    // ✅ ИСПРАВЛЕНИЕ: Проверяем блокировку
                    if privacyManager.isAppLocked {
                        print("🔐 App is locked - storing deeplink for later")
                        pendingDeeplink = foundHabit
                    } else {
                        print("🔗 App unlocked - processing deeplink immediately")
                        openHabitDirectly(foundHabit)
                    }
                } else {
                    print("❌ Habit not found for ID: \(habitId)")
                }
                
            } catch {
                print("❌ Error fetching habit for deeplink: \(error)")
            }
        }
    }
    
    // ✅ ДОБАВЛЕНО: Отдельная функция для открытия привычки
    private func openHabitDirectly(_ habit: Habit) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NotificationCenter.default.post(
                name: .openHabitFromDeeplink,
                object: habit
            )
        }
    }
    
    // MARK: - Live Activities Setup
    
    private func setupLiveActivities() {
        print("🎬 Setting up Live Activities...")
        
        // ✅ Восстанавливаем существующие Live Activities при запуске
        Task {
            await HabitLiveActivityManager.shared.restoreActiveActivitiesIfNeeded()
        }
        
        print("✅ Live Activities setup completed")
    }
    
    // MARK: - App Lifecycle Methods
    
    private func handleAppBackground() {
        print("📱 App going to background")
        saveDataContext()
        
        if privacyManager.isPrivacyEnabled {
                NotificationCenter.default.post(name: .dismissAllSheets, object: nil)
            }
        
        // ✅ Сообщаем TimerService о переходе в фон
        TimerService.shared.handleAppDidEnterBackground()
        
        // ✅ Очищаем только действительно неактивные ViewModel
        HabitManager.shared.cleanupInactiveViewModels()
        
        print("📱 Background transition completed")
    }
    
    private func handleAppForeground() {
        print("📱 App will enter foreground")
        
        WidgetUpdateService.shared.reloadWidgets()
        TimerService.shared.handleAppWillEnterForeground()
        
        // ✅ Синхронизируем состояние Live Activities
        Task {
            await HabitLiveActivityManager.shared.restoreActiveActivitiesIfNeeded()
        }
        
        print("📱 Foreground transition completed")
    }
    
    private func handleAppTermination() {
        print("💀 App is being terminated - cleaning up")
        
        // ✅ Очищаем ViewModel'ы
        HabitManager.shared.cleanupAllViewModels()
        
        // ✅ Сохраняем данные последний раз
        saveDataContext()
        
        print("💀 App termination cleanup completed")
    }
    
    private func saveDataContext() {
        do {
            try container.mainContext.save()
            print("✅ Data saved on background")
        } catch {
            print("❌ Failed to save on background: \(error)")
        }
    }
    
    // ✅ Обновляем globalPinEnvironment с биометрическим промо
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
                print("🔐 TeymiaHabitApp: Showing biometric promo for \(displayName)")
                globalBiometricType = biometricType
                globalBiometricDisplayName = displayName
                globalBiometricEnable = onEnable
                globalBiometricDismiss = onDismiss
                showingBiometricPromo = true
            },
            hideBiometricPromo: {
                print("🔐 TeymiaHabitApp: Hiding biometric promo")
                showingBiometricPromo = false
                globalBiometricType = .none
                globalBiometricDisplayName = ""
                globalBiometricEnable = nil
                globalBiometricDismiss = nil
            }
        )
    }
}

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
