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
                .onAppear {
                    setupLiveActivities()
                    AppModelContext.shared.setModelContext(container.mainContext)
                }
            // ✅ ДОБАВИТЬ: Обработчик принудительного завершения приложения (редко)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                    handleAppTermination()
                }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                handleAppBackground()
                
            case .inactive:
                print("📱 App becoming inactive")
                // ✅ НЕ ОЧИЩАЕМ HabitManager - только сохраняем данные
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
        
        // ✅ НОВОЕ: Используем HabitWidgetService вместо прямого HabitLiveActivityManager
        HabitWidgetService.shared.startListening()
        
        // ✅ Восстанавливаем существующие Live Activities при запуске
        Task {
            await HabitLiveActivityManager.shared.restoreActiveActivitiesIfNeeded()
        }
        
        print("✅ Live Activities setup completed")
    }
    
    // MARK: - App Lifecycle Methods (ОБНОВИТЬ СУЩЕСТВУЮЩИЕ МЕТОДЫ)
    
    private func handleAppBackground() {
        print("📱 App going to background")
        saveDataContext()
        
        // ✅ Сообщаем TimerService о переходе в фон
        TimerService.shared.handleAppDidEnterBackground()
        
        // ✅ НОВОЕ: Очищаем только действительно неактивные ViewModel
        HabitManager.shared.cleanupInactiveViewModels()
        
        print("📱 Background transition completed")
    }
    
    private func handleAppForeground() {
        print("📱 App will enter foreground")
        
        // ✅ Сообщаем TimerService о возврате на передний план
        TimerService.shared.handleAppWillEnterForeground()
        
        // ✅ ИСПРАВЛЕНО: Используем правильное свойство
        if !HabitWidgetService.shared.isCurrentlyListening {
            print("🔄 Restarting HabitWidgetService")
            HabitWidgetService.shared.startListening()
        }
        
        // ✅ Синхронизируем состояние Live Activities
        Task {
            await HabitLiveActivityManager.shared.restoreActiveActivitiesIfNeeded()
        }
        
        print("📱 Foreground transition completed")
    }
    
    // ✅ НОВОЕ: Обработка принудительного завершения приложения
    private func handleAppTermination() {
        print("💀 App is being terminated - cleaning up")
        
        // ✅ Останавливаем все сервисы
        HabitWidgetService.shared.stopListening()
        
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
}
