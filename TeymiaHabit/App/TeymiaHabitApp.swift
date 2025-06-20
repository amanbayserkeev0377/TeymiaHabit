import SwiftUI
import SwiftData
import UserNotifications
import RevenueCat

@main
struct TeymiaHabitApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    
    let container: ModelContainer
    let habitsUpdateService = HabitsUpdateService()
    
    @State private var weekdayPrefs = WeekdayPreferences.shared
    
    init() {
        // Configure RevenueCat FIRST
        RevenueCatConfig.configure()
        
        // Print current app configuration
        let appVersion = AppConfig.current
        print("🚀 Starting \(appVersion.displayName) version")
        print("📦 Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        print("☁️ CloudKit Container: \(appVersion.cloudKitContainerID)")
        
        do {
            let schema = Schema([Habit.self, HabitCompletion.self, HabitFolder.self])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private(appVersion.cloudKitContainerID)
            )
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            print("✅ Local storage initialized successfully")
            print("✅ CloudKit container initialized: \(appVersion.cloudKitContainerID)")
        } catch {
            print("❌ ModelContainer initialization error: \(error)")
            fatalError("Не удалось создать ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(habitsUpdateService)
                .environment(weekdayPrefs)
                .environment(ProManager.shared)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                handleAppBackground()
                
            case .active:
                handleAppActive()
                
            case .inactive:
                handleAppInactive()
                
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - App Lifecycle Methods

    private func handleAppBackground() {
        print("📱 App going to background")
        
        // ✅ ONLY save current progress to SwiftData
        // DON'T stop timers - let them continue in background
        Task {
            await saveTimerStates()
        }
        
        // Save SwiftData
        do {
            try container.mainContext.save()
            print("✅ Data saved on background")
        } catch {
            print("❌ Failed to save on background: \(error)")
        }
    }

    private func handleAppActive() {
        print("📱 App became active")
        
        // ✅ НОВОЕ: Проверяем смену дня при активации приложения
        checkDayChangeOnAppActive()
        
        // Just update UI - timers should still be running
        habitsUpdateService.triggerUpdate()
        print("✅ App became active, triggering UI update")
    }
    
    private func checkDayChangeOnAppActive() {
        // Force day change check in services
        // Services will automatically clear progress if day changed
        _ = HabitTimerService.shared.getCurrentProgress(for: "dummy") // This triggers checkDayChange
        _ = HabitCounterService.shared.getCurrentProgress(for: "dummy") // This triggers checkDayChange
        
        print("✅ Day change check completed")
    }

    private func handleAppInactive() {
        print("📱 App became inactive")
        
        // Save current state without stopping timers
        Task {
            await saveTimerStates()
        }
    }
    
    // MARK: - Helper Methods
    
    private func saveTimerStates() async {
        // Save all active timer states to SwiftData (but don't stop them)
        HabitTimerService.shared.persistAllCompletionsToSwiftData(modelContext: container.mainContext)
        HabitCounterService.shared.persistAllCompletionsToSwiftData(modelContext: container.mainContext)
        
        // Save SwiftData context
        do {
            try container.mainContext.save()
            print("✅ Timer states saved to SwiftData")
        } catch {
            print("❌ Failed to save timer states: \(error)")
        }
    }
}
