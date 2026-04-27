import SwiftUI
import SwiftData
import UserNotifications

@main
struct TeymiaHabitApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let modelContainer: ModelContainer
    @State private var appContainer: AppDependencyContainer
    
    init() {
        let schema = Schema([
            Habit.self, HabitCompletion.self
        ])
        
        let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.amanbayserkeev.teymiahabit")!
        let storeURL = groupURL.appendingPathComponent("Library/Application Support/default.store")
        let config = ModelConfiguration(schema: schema, url: storeURL)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            self.modelContainer = container
            
            self._appContainer = State(initialValue: AppDependencyContainer(modelContext: container.mainContext))
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(appContainer)
                .environment(appContainer.navManager)
                .environment(appContainer.notificationManager)
                .environment(appContainer.soundManager)
                .environment(appContainer.iconManager)
                .environment(appContainer.timerService)
                .environment(\.habitService, appContainer.habitService)
                .fontDesign(.rounded)
                .tint(Color.primary)
                .onAppear {
                    setupLiveActivities()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // MARK: - Lifecycle & Scene Phase
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            try? modelContainer.mainContext.save()
            appContainer.timerService.handleAppDidEnterBackground()
            
        case .inactive:
            try? modelContainer.mainContext.save()
            
        case .active:
            appContainer.timerService.handleAppWillEnterForeground()
            appContainer.widgetService.reloadWidgets()
            checkPendingHabitFromWidget()
            setupLiveActivities()
            
        @unknown default: break
        }
    }
    
    // MARK: - DeepLink Handling
    
    private func handleDeepLink(_ url: URL) {
        // Parse URL: teymiahabit://habit/UUID
        guard url.scheme == "teymiahabit", url.host == "habit",
              let habitId = url.pathComponents.last,
              let habitUUID = UUID(uuidString: habitId) else { return }
        
        Task { @MainActor in
            let descriptor = FetchDescriptor<Habit>(
                predicate: #Predicate<Habit> { habit in
                    habit.uuid == habitUUID && !habit.isArchived
                }
            )
            
            if let foundHabit = try? modelContainer.mainContext.fetch(descriptor).first {
                appContainer.navManager.openHabit(foundHabit)
            }
        }
    }
    
    // MARK: - Widget & Live Activities
    
    private func checkPendingHabitFromWidget() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.amanbayserkeev.teymiahabit"),
              let habitIdString = sharedDefaults.string(forKey: "pendingHabitIdFromWidget") else {
            return
        }
        
        sharedDefaults.removeObject(forKey: "pendingHabitIdFromWidget")
        
        if let url = URL(string: "teymiahabit://habit/\(habitIdString)") {
            handleDeepLink(url)
        }
    }

    private func setupLiveActivities() {
        Task {
            await appContainer.habitLiveActivityManager.restoreActiveActivitiesIfNeeded()
        }
    }
}
