import Foundation
import SwiftData

@MainActor
protocol HabitViewModelFactoryProtocol {
    func makeHabitsViewModel(modelContext: ModelContext) -> HabitsViewModel
    func makeNewHabitViewModel(modelContext: ModelContext, habit: Habit?, onSaveCompletion: (() -> Void)?) -> NewHabitViewModel
    func makeHabitDetailViewModel(habit: Habit, initialDate: Date) -> HabitDetailViewModel
}

@MainActor
final class HabitViewModelFactory: HabitViewModelFactoryProtocol {
    private let habitService: any HabitServiceProtocol
    private let widgetService: any WidgetServiceProtocol
    private let notificationManager: NotificationManager
    private let soundManager: SoundManager
    private let timerService: TimerService
    private let habitLiveActivityManager: HabitLiveActivityManager
    
    init(
        habitService: any HabitServiceProtocol,
        widgetService: any WidgetServiceProtocol,
        notificationManager: NotificationManager,
        soundManager: SoundManager,
        timerService: TimerService,
        habitLiveActivityManager: HabitLiveActivityManager
    ) {
        self.habitService = habitService
        self.widgetService = widgetService
        self.notificationManager = notificationManager
        self.soundManager = soundManager
        self.timerService = timerService
        self.habitLiveActivityManager = habitLiveActivityManager
    }
    
    func makeHabitsViewModel(modelContext: ModelContext) -> HabitsViewModel {
        HabitsViewModel(
            dataSource: HabitLocalDataSource(modelContext: modelContext),
            habitService: habitService,
            notificationManager: notificationManager,
            soundManager: soundManager,
            widgetService: widgetService,
            timerService: timerService
        )
    }
    
    func makeNewHabitViewModel(
        modelContext: ModelContext,
        habit: Habit? = nil,
        onSaveCompletion: (() -> Void)? = nil
    ) -> NewHabitViewModel {
        NewHabitViewModel(
            dataSource: HabitLocalDataSource(modelContext: modelContext),
            notificationManager: notificationManager,
            widgetService: widgetService,
            habit: habit,
            onSaveCompletion: onSaveCompletion
        )
    }
    
    func makeHabitDetailViewModel(habit: Habit, initialDate: Date) -> HabitDetailViewModel {
        HabitDetailViewModel(
            habit: habit,
            initialDate: initialDate,
            habitService: habitService,
            timerService: timerService,
            widgetService: widgetService,
            notificationManager: notificationManager,
            soundManager: soundManager,
            habitLiveActivityManager: habitLiveActivityManager
        )
    }
}
