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
    
    // MARK: - State
        private(set) var localUpdateTrigger: Int = 0
        private var updateTimer: Timer?
    
    // MARK: - UI State
    var alertState = AlertState()
    var isTimeInputPresented: Bool = false
    var isCountInputPresented: Bool = false
    var onHabitDeleted: (() -> Void)?
    var hasActiveLiveActivity: Bool = false
    
    
    
    // MARK: - Computed Properties
    
    var currentProgress: Int {
        // Подписываемся на localUpdateTrigger для UI обновлений
        _ = localUpdateTrigger
        
        let dbProgress = habit.progressForDate(date)
        
        // Если сегодня и таймер активен - берем live прогресс
        if isToday && habit.type == .time {
            let habitId = habit.uuid.uuidString
            if let liveProgress = timerService.getLiveProgress(for: habitId) {
                return liveProgress
            }
        }
        
        return dbProgress
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
        
        let habitId = habit.uuid.uuidString
        
        print("🚀 HabitDetailViewModel init for habit: \(habit.title)")
        print("   habitId: \(habitId)")
        
        // ✅ Инициализируем прогресс в TimerService если сегодня
        if isToday {
            // ✅ КРИТИЧНО: Берем прогресс ТОЛЬКО из базы данных, избегая циклической зависимости
            let dbProgress = habit.progressForDate(date) // ← Берем напрямую из БД!
            
            if timerService.isTimerRunning(for: habitId) {
                startLocalUpdates()
            }
        }
        
        // Setup Live Activities для time привычек
        if habit.type == .time && isToday {
            setupLiveActivities()
        }
    }
    
    // MARK: - Public UI Update Method
    func forceUIUpdate() {
        localUpdateTrigger += 1
    }
    
    // MARK: - Progress Methods
    
    func incrementProgress() {
        let incrementValue = habit.type == .count ? 1 : 60
        
        // 1. Добавляем к существующему прогрессу в базе
        habit.addToProgress(incrementValue, for: date, modelContext: modelContext)
        
        // 2. Обновляем TimerService если сегодня
        if isToday {
            let habitId = habit.uuid.uuidString
            forceUIUpdate()        }
    }
    
    func decrementProgress() {
        guard currentProgress > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            return
        }
        
        let decrementValue = habit.type == .count ? -1 : -60
        
        // 1. Добавляем к существующему прогрессу в базе
        habit.addToProgress(decrementValue, for: date, modelContext: modelContext)
        
        // 2. Обновляем TimerService если сегодня
        if isToday {
            let habitId = habit.uuid.uuidString
            forceUIUpdate()        }
    }
    
    func handleCustomCountInput(count: Int) {
        habit.addToProgress(count, for: date, modelContext: modelContext)
        
        if isToday {
            let habitId = habit.uuid.uuidString
            forceUIUpdate()        }
        
        alertState.successFeedbackTrigger.toggle()
    }

    func handleCustomTimeInput(hours: Int, minutes: Int) {
        let totalSeconds = (hours * 3600) + (minutes * 60)
        
        guard totalSeconds > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            return
        }
        
        habit.addToProgress(totalSeconds, for: date, modelContext: modelContext)
        
        if isToday {
            let habitId = habit.uuid.uuidString
            forceUIUpdate()        }
        
        alertState.successFeedbackTrigger.toggle()
    }
    
    func completeHabit() {
        guard !isAlreadyCompleted else { return }
        
        habit.complete(for: date, modelContext: modelContext)
        
        if isToday {
            let habitId = habit.uuid.uuidString
            forceUIUpdate()        }
        
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
        
        if isToday {
            let habitId = habit.uuid.uuidString
            forceUIUpdate()        }
    }
    
    // MARK: - Timer Management
    
    private func startLocalUpdates() {
            guard habit.type == .time && isToday else { return }
            
            updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    let habitId = self.habit.uuid.uuidString
                    
                    // Обновляем только если наш таймер активен
                    if self.timerService.isTimerRunning(for: habitId) {
                        self.localUpdateTrigger += 1
                    }
                }
            }
            print("⏱️ Started local updates for: \(habit.title)")
        }
        
        private func stopLocalUpdates() {
            updateTimer?.invalidate()
            updateTimer = nil
            print("⏱️ Stopped local updates for: \(habit.title)")
        }
    
    func toggleTimer() {
        guard habit.type == .time && isToday else { return }
        
        let habitId = habit.uuid.uuidString
        
        if timerService.isTimerRunning(for: habitId) {
            // Stop timer
            print("🛑 Stopping timer for: \(habit.title)")
            
            // ✅ Останавливаем локальные обновления
            stopLocalUpdates()
            
            // ✅ Останавливаем таймер и получаем финальный прогресс
            if let finalProgress = timerService.stopTimer(for: habitId) {
                habit.updateProgress(to: finalProgress, for: date, modelContext: modelContext)
                print("   Saved final progress to DB: \(finalProgress)")
                
                // ✅ Обновляем Live Activity
                Task {
                    await liveActivityManager.updateActivity(
                        for: habitId,
                        currentProgress: finalProgress,
                        isTimerRunning: false,
                        timerStartTime: nil
                    )
                    print("🔄 Live Activity updated: timer stopped")
                }
            }
            
        } else {
            // Start timer
            guard timerService.canStartNewTimer else {
                alertState.errorFeedbackTrigger.toggle()
                print("❌ Cannot start timer - limit reached")
                return
            }
            
            let dbProgress = habit.progressForDate(date)
            let success = timerService.startTimer(for: habitId, baseProgress: dbProgress)

            if !success {
                alertState.errorFeedbackTrigger.toggle()
                print("❌ Failed to start timer")
                return
            }
            
            // ✅ Запускаем локальные обновления
            startLocalUpdates()
            
            print("✅ Timer started for: \(habit.title), initial progress: \(dbProgress)")
            
            // ✅ Запускаем Live Activity
            Task {
                await startLiveActivity()
            }
        }
    }
    
    // MARK: - Live Activities
    
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
        print("🎬 Live Activity started for: \(habit.title)")
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
        print("🛑 Live Activity ended for: \(habit.title)")
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
        // SwiftData автоматически сохраняет
    }
    
    func cleanup() {
        stopLocalUpdates()
        widgetActionTask?.cancel()
        widgetActionTask = nil
        onHabitDeleted = nil
    }
}
