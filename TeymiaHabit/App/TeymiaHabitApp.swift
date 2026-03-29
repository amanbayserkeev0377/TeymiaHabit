import SwiftUI
import SwiftData
import UserNotifications
import RevenueCat

@main
struct TeymiaHabitApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    let container: ModelContainer
    
    @State private var weekdayPrefs = WeekdayPreferences.shared
    @State private var timerService = TimerService.shared
    @State private var pendingDeeplink: Habit? = nil
    
    init() {
        RevenueCatConfig.configure()
        
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
            let schema = Schema([
                Habit.self,
                HabitCompletion.self,
                TodoTask.self,
                Subtask.self,
                TaskList.self,
                TaskGroup.self
            ])

            guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.amanbayserkeev.teymiahabit") else {
                fatalError("Could not find App Group container.")
            }

            let appSupportURL = groupURL.appendingPathComponent("Library/Application Support", isDirectory: true)
            try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            let storeURL = appSupportURL.appendingPathComponent("default.store")
            
            let modelConfiguration = ModelConfiguration(
                "Default",
                schema: schema,
                url: storeURL,
                allowsSave: true,
                cloudKitDatabase: .private("iCloud.com.amanbayserkeev.teymiahabit")
            )
        
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            print("DEBUG: SwiftData successfully initialized at \(storeURL.path)")
            
        } catch {
            print("DEBUG: CoreData/SwiftData Error: \(error)")
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(weekdayPrefs)
                .environment(ProManager.shared)
                .environment(timerService)
                .fontDesign(.rounded)
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
            
        case .inactive:
            try? container.mainContext.save()
            
        case .active:
            handleAppForeground()
            
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
            openHabitDirectly(foundHabit)
        }
    }
    
    private func handlePendingDeeplink() {
        guard let habit = pendingDeeplink else { return }
        
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
}
