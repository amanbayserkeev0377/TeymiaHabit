import SwiftUI
import SwiftData
import UserNotifications
import RevenueCat

@main
struct TeymiaHabitApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    
    let container: ModelContainer
    
    @State private var weekdayPrefs = WeekdayPreferences.shared
    
    init() {
        // Configure RevenueCat FIRST
        RevenueCatConfig.configure()
        
        // Print current app configuration
        print("🚀 Starting Teymia Habit")
        print("📦 Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        print("☁️ CloudKit Container: iCloud.com.amanbayserkeev.teymiahabit")
        
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
            MainTabView()
                .environment(weekdayPrefs)
                .environment(ProManager.shared)
                // ✅ КРИТИЧНО: Добавляем инициализацию Live Activity listener'а
                .onAppear {
                    setupLiveActivities()
                }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                handleAppBackground()
                
            case .inactive:
                print("📱 App becoming inactive")
                // Save data when app becomes inactive
                saveDataContext()
                
            case .active:
                print("📱 App became active")
                handleAppForeground()
                
            @unknown default:
                print("📱 Unknown scene phase")
                break
            }
        }
    }
    
    // MARK: - Live Activities Setup
    
    private func setupLiveActivities() {
        print("🎬 Setting up Live Activities...")
        
        // ✅ КРИТИЧНО: Запускаем listener для Widget Actions
        HabitLiveActivityManager.shared.startListeningForWidgetActions()
        
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
        
        // ✅ Сообщаем TimerService о переходе в фон
        TimerService.shared.handleAppDidEnterBackground()
        
        // ✅ НЕ останавливаем Live Activity listener в фоне - он должен работать!
        // HabitLiveActivityManager продолжает слушать Widget Actions в фоне
    }
    
    private func handleAppForeground() {
        print("📱 App will enter foreground")
        
        // ✅ Сообщаем TimerService о возврате на передний план
        TimerService.shared.handleAppWillEnterForeground()
        
        // ✅ Убеждаемся что Live Activity listener работает
        if !HabitLiveActivityManager.shared.isListeningForWidgetActions {
            print("🔄 Restarting Live Activity listener")
            HabitLiveActivityManager.shared.startListeningForWidgetActions()
        }
        
        // ✅ Синхронизируем состояние Live Activities
        Task {
            await HabitLiveActivityManager.shared.restoreActiveActivitiesIfNeeded()
        }
    }
    
    private func saveDataContext() {
        do {
            try container.mainContext.save()
            print("✅ Data saved on background")
        } catch {
            print("❌ Failed to save on background: \(error)")
        }
    }
}
