import Foundation
import SwiftData

@Observable
@MainActor
final class AppDependencyContainer {
    // MARK: - Managers (shared, app-wide)
    let navManager = NavigationManager()
    let notificationManager = NotificationManager()
    let timerService = TimerService()
    let habitLiveActivityManager = HabitLiveActivityManager()
    let soundManager = SoundManager()
    let iconManager = AppIconManager()
    
    // MARK: - Services (protocol types for testability)
    private(set) var widgetService: any WidgetServiceProtocol
    private(set) var habitService: any HabitServiceProtocol
    private(set) var habitWidgetService: HabitWidgetService
    
    // MARK: - Factories
    private(set) var habitFactory: HabitViewModelFactory
    
    // MARK: - Init
    init(modelContext: ModelContext) {
        let widgetServiceInstance = WidgetService()
        self.widgetService = widgetServiceInstance
        
        let dataSource = HabitLocalDataSource(modelContext: modelContext)
        let habitServiceInstance = HabitService(
            dataSource: dataSource,
            widgetService: widgetServiceInstance
        )
        self.habitService = habitServiceInstance
        self.habitWidgetService = HabitWidgetService(
            modelContext: modelContext,
            habitService: habitServiceInstance
        )
        self.habitFactory = HabitViewModelFactory(
            habitService: habitServiceInstance,
            widgetService: widgetServiceInstance,
            notificationManager: notificationManager,
            soundManager: soundManager,
            timerService: timerService,
            habitLiveActivityManager: habitLiveActivityManager
        )
    }
}
