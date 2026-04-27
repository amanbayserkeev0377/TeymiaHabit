import SwiftUI
import SwiftData

@Observable @MainActor
final class HabitDetailViewModel {
    
    // MARK: - Dependencies
    private let habit: Habit
    private let habitService: any HabitServiceProtocol
    private let timerService: TimerService
    private let widgetService: any WidgetServiceProtocol
    private let notificationManager: NotificationManager
    private let soundManager: SoundManager
    private let habitLiveActivityManager: HabitLiveActivityManager
    private let cachedHabitId: String
    
    // MARK: - Timer / Save debounce
    private var saveTask: Task<Void, Never>?
    private var goalSoundPlayed = false
    private var goalNotificationSent = false
    
    // MARK: - UI State
    var alertState = AlertState()
    
    // MARK: - Displayed date
    private(set) var currentDisplayedDate: Date
    
    // MARK: - Computed Properties
    var isTimerRunning: Bool { timerService.isTimerRunning(for: cachedHabitId) }
    var timerStartTime: Date? { timerService.getTimerStartTime(for: cachedHabitId) }
    var formattedGoal: String { habit.formattedGoal }
    var hasActiveLiveActivity: Bool { habitLiveActivityManager.hasActiveActivity(for: cachedHabitId) }
    
    private var isToday: Bool { Calendar.current.isDateInToday(currentDisplayedDate) }
    private var isTimeHabitToday: Bool { habit.type == .time && isToday }
    
    private var uiProgressOverride: Int?
    
    var currentProgress: Int {
        if let override = uiProgressOverride { return override }
        _ = timerService.updateTrigger
        if isTimeHabitToday, let live = timerService.getLiveProgress(for: cachedHabitId) {
            return live
        }
        return habit.progressForDate(currentDisplayedDate)
    }
    
    var completionPercentage: Double {
        habit.goal > 0 ? Double(currentProgress) / Double(habit.goal) : 0
    }
    
    var isAlreadyCompleted: Bool { currentProgress >= habit.goal }
    
    // MARK: - Init
    init(
        habit: Habit,
        initialDate: Date,
        habitService: any HabitServiceProtocol,
        timerService: TimerService,
        widgetService: any WidgetServiceProtocol,
        notificationManager: NotificationManager,
        soundManager: SoundManager,
        habitLiveActivityManager: HabitLiveActivityManager
    ) {
        self.habit = habit
        self.currentDisplayedDate = initialDate
        self.habitService = habitService
        self.timerService = timerService
        self.widgetService = widgetService
        self.notificationManager = notificationManager
        self.soundManager = soundManager
        self.habitLiveActivityManager = habitLiveActivityManager
        self.cachedHabitId = habit.uuid.uuidString
    }
    
    // MARK: - Date Management
    func updateDisplayedDate(_ newDate: Date) {
        currentDisplayedDate = newDate
        uiProgressOverride = nil
        goalSoundPlayed = false
        goalNotificationSent = false
    }
    
    // MARK: - Goal Progress
    func checkGoalProgress(_ current: Int) {
        guard current >= habit.goal, !goalSoundPlayed else { return }
        goalSoundPlayed = true
        soundManager.playCompletionSound()
        
        if !goalNotificationSent {
            goalNotificationSent = true
            Task { await notificationManager.sendGoalAchievedNotification(for: habit) }
        }
    }
    
    // MARK: - Progress Actions
    func incrementProgress() {
        stopTimerIfNeeded()
        let step = habit.type == .count ? 1 : 60
        let maxVal = habit.type == .count ? 999_999 : 86_400
        let new = min(currentProgress + step, maxVal)
        uiProgressOverride = new
        saveProgress(new)
        updateLiveActivityIfNeeded(progress: new, timerRunning: false)
    }
    
    func decrementProgress() {
        let current = currentProgress
        stopTimerIfNeeded()
        let step = habit.type == .count ? 1 : 60
        let new = max(current - step, 0)
        uiProgressOverride = new
        saveProgress(new)
        updateLiveActivityIfNeeded(progress: new, timerRunning: false)
    }
    
    func completeHabit() {
        guard !isAlreadyCompleted else { return }
        stopTimerAndEndActivity()
        uiProgressOverride = habit.goal
        saveProgress(habit.goal)
        soundManager.playCompletionSound()
    }
    
    func resetProgress() {
        stopTimerAndEndActivity()
        uiProgressOverride = 0
        habitService.resetProgress(for: habit, date: currentDisplayedDate)
        updateLiveActivityIfNeeded(progress: 0, timerRunning: false)
    }
    
    // MARK: - Timer Actions
    func toggleTimer() {
        guard isTimeHabitToday else { return }
        if isTimerRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        let base = habit.progressForDate(currentDisplayedDate)
        goalSoundPlayed = false
        goalNotificationSent = false
        _ = timerService.startTimer(for: cachedHabitId, baseProgress: base)
        
        Task {
            guard let start = timerStartTime else { return }
            await habitLiveActivityManager.startActivity(
                for: habit,
                currentProgress: base,
                timerStartTime: start
            )
        }
    }
    
    private func stopTimer() {
        guard let final = timerService.stopTimer(for: cachedHabitId) else { return }
        saveProgress(final)
        Task {
            await habitLiveActivityManager.updateActivity(
                for: cachedHabitId,
                currentProgress: final,
                isTimerRunning: false,
                timerStartTime: nil
            )
        }
    }
    
    // MARK: - Private Helpers
    
    private func saveProgress(_ value: Int) {
        habitService.saveProgress(value, for: habit, date: currentDisplayedDate)
        
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .seconds(0.8))
            guard !Task.isCancelled else { return }
            uiProgressOverride = nil
            widgetService.reloadWidgetsAfterDataChange()
        }
    }
    
    private func stopTimerIfNeeded() {
        guard isTimerRunning else { return }
        stopTimer()
    }
    
    private func stopTimerAndEndActivity() {
        _ = timerService.stopTimer(for: cachedHabitId)
        Task { await habitLiveActivityManager.endActivity(for: cachedHabitId) }
    }
    
    private func updateLiveActivityIfNeeded(progress: Int, timerRunning: Bool) {
        guard isTimeHabitToday, hasActiveLiveActivity else { return }
        Task {
            await habitLiveActivityManager.updateActivity(
                for: cachedHabitId,
                currentProgress: progress,
                isTimerRunning: timerRunning,
                timerStartTime: timerRunning ? timerStartTime : nil
            )
        }
    }
    
    func prepareForDeletion() {
        saveTask?.cancel()
    }
    
    // MARK: - Delete and Archive
    
    func deleteHabit() {
        prepareForDeletion()
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            habitService.delete(habit)
        }
    }
    
    func archiveHabit() {
        habitService.archive(habit)
    }
}
