import SwiftUI
import SwiftData

@Observable @MainActor
final class HabitDetailViewModel {
    // MARK: - Dependencies
    private let habit: Habit
    private let date: Date
    private let modelContext: ModelContext
    private let timerService = TimerService.shared
    private let liveActivityManager = HabitLiveActivityManager.shared
    private var widgetActionTask: Task<Void, Never>?
    
    // MARK: - UI State
    var alertState = AlertState()
    var isTimeInputPresented: Bool = false
    var isCountInputPresented: Bool = false
    var onHabitDeleted: (() -> Void)?
    var hasActiveLiveActivity: Bool = false
    
    // MARK: - Computed Properties
    
    var currentProgress: Int {
        habit.getCurrentProgress(for: date)
    }
    
    var completionPercentage: Double {
        habit.goal > 0 ? Double(currentProgress) / Double(habit.goal) : 0
    }
    
    var isAlreadyCompleted: Bool {
        currentProgress >= habit.goal
    }
    
    var formattedGoal: String {
        habit.formattedGoal
    }
    
    var isTimerRunning: Bool {
        let habitId = habit.uuid.uuidString
        return timerService.isTimerRunning(for: habitId)
    }
    
    var canStartTimer: Bool {
        timerService.canStartNewTimer || isTimerRunning
    }
    
    var timerStartTime: Date? {
        let habitId = habit.uuid.uuidString
        return timerService.getTimerStartTime(for: habitId)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    // MARK: - Initialization
    init(habit: Habit, date: Date, modelContext: ModelContext) {
        self.habit = habit
        self.date = date
        self.modelContext = modelContext
        
        // Initialize progress in TimerService if today but no active timer
        if isToday {
            let habitId = habit.uuid.uuidString
            let dbProgress = habit.progressForDate(date)
            
            // Only set if no current live progress
            if timerService.liveProgress[habitId] == nil {
                timerService.setProgress(dbProgress, for: habitId)
            }
        }
        
        // Setup Live Activities for time habits
        if habit.type == .time && isToday {
            setupLiveActivities()
        }
    }
    
    // MARK: - ✅ НАТИВНЫЕ методы работы с прогрессом (упрощенные!)
    
    func incrementProgress() {
        let incrementValue = habit.type == .count ? 1 : 60
        
        // 1. Добавляем к существующему прогрессу в базе
        habit.addToProgress(incrementValue, for: date, modelContext: modelContext)
        
        // 2. Обновляем TimerService если сегодня (читаем из БАЗЫ, не из TimerService)
        if isToday {
            let habitId = habit.uuid.uuidString
            let newProgress = habit.progressForDate(date) // ✅ Читаем из БАЗЫ
            timerService.setProgress(newProgress, for: habitId)
        }
    }
    
    func decrementProgress() {
        guard currentProgress > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            return
        }
        
        let decrementValue = habit.type == .count ? -1 : -60
        
        // 1. Добавляем к существующему прогрессу в базе
        habit.addToProgress(decrementValue, for: date, modelContext: modelContext)
        
        // 2. Обновляем TimerService если сегодня (читаем из БАЗЫ, не из TimerService)
        if isToday {
            let habitId = habit.uuid.uuidString
            let newProgress = habit.progressForDate(date) // ✅ Читаем из БАЗЫ
            timerService.setProgress(newProgress, for: habitId)
        }
    }
    
    func handleCustomCountInput(count: Int) {
        // 1. Добавляем к существующему прогрессу в базе
        habit.addToProgress(count, for: date, modelContext: modelContext)
        
        // 2. Обновляем TimerService если сегодня (читаем из БАЗЫ, не из TimerService)
        if isToday {
            let habitId = habit.uuid.uuidString
            let newProgress = habit.progressForDate(date) // ✅ Читаем из БАЗЫ
            timerService.setProgress(newProgress, for: habitId)
        }
        
        alertState.successFeedbackTrigger.toggle()
    }

    func handleCustomTimeInput(hours: Int, minutes: Int) {
        let totalSeconds = (hours * 3600) + (minutes * 60)
        
        guard totalSeconds > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            return
        }
        
        // 1. Добавляем к существующему прогрессу в базе
        habit.addToProgress(totalSeconds, for: date, modelContext: modelContext)
        
        // 2. Обновляем TimerService если сегодня (читаем из БАЗЫ, не из TimerService)
        if isToday {
            let habitId = habit.uuid.uuidString
            let newProgress = habit.progressForDate(date) // ✅ Читаем из БАЗЫ
            timerService.setProgress(newProgress, for: habitId)
        }
        
        alertState.successFeedbackTrigger.toggle()
    }
    
    func completeHabit() {
        guard !isAlreadyCompleted else { return }
        
        // 1. Завершаем привычку в базе
        habit.complete(for: date, modelContext: modelContext)
        
        // 2. Обновляем TimerService если сегодня
        if isToday {
            let habitId = habit.uuid.uuidString
            timerService.setProgress(habit.goal, for: habitId) // ✅ Прямо goal, не читаем
        }
        
        alertState.successFeedbackTrigger.toggle()
        
        // Завершаем Live Activity если это time привычка сегодня
        if habit.type == .time && isToday {
            Task {
                await liveActivityManager.endActivity(for: habit.uuid.uuidString)
                hasActiveLiveActivity = false
            }
        }
    }
    
    func resetProgress() {
        habit.resetProgress(for: date, modelContext: modelContext)
        
        // Обновляем TimerService если сегодня
        if isToday {
            let habitId = habit.uuid.uuidString
            timerService.setProgress(0, for: habitId)
        }
    }
    
    // MARK: - Timer Management (оставляем как есть - нужен для time привычек)
    
    func toggleTimer() {
        guard habit.type == .time && isToday else { return }
        
        let habitId = habit.uuid.uuidString
        
        if timerService.isTimerRunning(for: habitId) {
            timerService.stopTimer(for: habitId)
            // Сохраняем текущий прогресс в базу
            habit.updateProgress(to: timerService.getCurrentProgress(for: habitId), for: date, modelContext: modelContext)
        } else {
            guard timerService.canStartNewTimer else {
                alertState.errorFeedbackTrigger.toggle()
                return
            }
            
            let dbProgress = habit.progressForDate(date)
            let success = timerService.startTimer(for: habitId, initialProgress: dbProgress)
            
            if !success {
                alertState.errorFeedbackTrigger.toggle()
                return
            }
        }
        
        // Обновляем Live Activity
        if isTimerRunning {
            Task {
                await startLiveActivity()
            }
        }
    }
    
    // MARK: - Live Activities (упрощенные)
    
    private func setupLiveActivities() {
        startObservingWidgetActions()
    }
    
    private func startObservingWidgetActions() {
        let habitId = habit.uuid.uuidString
        
        widgetActionTask = Task { [weak self] in
            for await action in WidgetActionService.shared.observeActions(for: habitId) {
                guard let self = self else { break }
                await self.handleWidgetAction(action)
            }
        }
    }
    
    private func handleWidgetAction(_ action: WidgetAction) async {
        switch action {
        case .toggleTimer:
            toggleTimer()
        case .dismissActivity:
            await liveActivityManager.endActivity(for: habit.uuid.uuidString)
            hasActiveLiveActivity = false
        }
    }
    
    private func startLiveActivity() async {
        guard let startTime = timerStartTime else { return }
        
        await liveActivityManager.startActivity(
            for: habit,
            currentProgress: currentProgress,
            timerStartTime: startTime
        )
        
        hasActiveLiveActivity = true
    }
    
    func startLiveActivityManually() async {
        guard habit.type == .time, isToday else { return }
        
        if !isTimerRunning {
            toggleTimer()
        }
        
        await startLiveActivity()
    }
    
    func endLiveActivityManually() async {
        await liveActivityManager.endActivity(for: habit.uuid.uuidString)
        hasActiveLiveActivity = false
    }
    
    // MARK: - Delete Operations
    
    func deleteHabit() {
        if habit.type == .time && isToday && hasActiveLiveActivity {
            Task {
                await liveActivityManager.endActivity(for: habit.uuid.uuidString)
            }
        }
        
        cleanup()
        modelContext.delete(habit)
        try? modelContext.save()
    }
    
    // MARK: - Cleanup
    
    func saveIfNeeded() {
        // SwiftData автоматически сохраняет, ничего не нужно
    }
    
    func cleanup() {
        widgetActionTask?.cancel()
        widgetActionTask = nil
        onHabitDeleted = nil
    }
}
