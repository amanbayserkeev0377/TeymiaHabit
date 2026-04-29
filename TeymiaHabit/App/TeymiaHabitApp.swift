import SwiftUI
import SwiftData
import UserNotifications

@main
struct TeymiaHabitApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let modelContainer: ModelContainer
    @State private var habitService: HabitService
    @State private var widgetService = WidgetService()
    @State private var notificationManager = NotificationManager()
    @State private var soundManager = SoundManager()
    @State private var timerService = TimerService()
    @State private var navManager = NavigationManager()
    @State private var habitLiveActivityManager = HabitLiveActivityManager()
    
    init() {
        #if os(iOS)
        AppFont.configureAppearance()
        #endif
        
        let schema = Schema([Habit.self, HabitCompletion.self])
        let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.amanbayserkeev.teymiahabit")!
        let storeURL = groupURL.appendingPathComponent("Library/Application Support/default.store")
        let config = ModelConfiguration(schema: schema, url: storeURL)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            self.modelContainer = container
            let widgetSvc = WidgetService()
            self._widgetService = State(initialValue: widgetSvc)
            self._habitService = State(initialValue: HabitService(
                modelContext: container.mainContext,
                widgetService: widgetSvc
            ))
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .fontDesign(.rounded)
                .tint(DS.Colors.appPrimary)
                .environment(habitService)
                .environment(widgetService)
                .environment(notificationManager)
                .environment(soundManager)
                .environment(timerService)
                .environment(navManager)
                .environment(habitLiveActivityManager)
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
            timerService.handleAppDidEnterBackground()
            
        case .inactive:
            try? modelContainer.mainContext.save()
            
        case .active:
            timerService.handleAppWillEnterForeground()
            widgetService.reloadWidgets()
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
                navManager.openHabit(foundHabit)
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
            await habitLiveActivityManager.restoreActiveActivitiesIfNeeded()
        }
    }
}
