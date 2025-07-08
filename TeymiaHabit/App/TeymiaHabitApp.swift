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
    
    // MARK: - App Lifecycle Methods

    private func handleAppBackground() {
        print("📱 App going to background")
        saveDataContext()
        
        // ✅ ДОБАВЛЕНО: Сообщаем TimerService о переходе в фон
        TimerService.shared.handleAppDidEnterBackground()
        
        // Note: Live Activities continue running in background automatically
    }
    
    private func handleAppForeground() {
        print("📱 App will enter foreground")
        
        // ✅ ДОБАВЛЕНО: Сообщаем TimerService о возврате на передний план
        TimerService.shared.handleAppWillEnterForeground()
        
        // Live Activities will automatically sync when app becomes active
        // TimerService continues running, no need to restore
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
