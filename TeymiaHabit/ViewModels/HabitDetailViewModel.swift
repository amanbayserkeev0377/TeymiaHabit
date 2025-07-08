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
    
    // ✅ НОВОЕ: отдельное хранение прогресса для ЭТОЙ привычки
    private(set) var cachedProgress: Int = 0
    
    // MARK: - UI State
    var alertState = AlertState()
    var isTimeInputPresented: Bool = false
    var isCountInputPresented: Bool = false
    var onHabitDeleted: (() -> Void)?
    var hasActiveLiveActivity: Bool = false
    
    // MARK: - Computed Properties
    
    var currentProgress: Int {
        // ✅ ИСПРАВЛЕНО: Подписываемся на localUpdateTrigger только если таймер активен
        let habitId = habit.uuid.uuidString
        
        // Если сегодня и таймер активен - берем live прогресс И подписываемся на обновления
        if isToday && habit.type == .time && timerService.isTimerRunning(for: habitId) {
            // ✅ КРИТИЧНО: Подписываемся на обновления только для активного таймера
            _ = localUpdateTrigger
            
            if let liveProgress = timerService.getLiveProgress(for: habitId) {
                return liveProgress
            }
        }
        
        // ✅ Для всех остальных случаев - кэшированный прогресс без подписки на обновления
        return cachedProgress
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
        print("   habit.uuid: \(habit.uuid)")

        // ✅ КРИТИЧНО: Инициализируем кэшированный прогресс из БД
        self.cachedProgress = habit.progressForDate(date)
        print("   initial cached progress: \(cachedProgress)")

        // ✅ ДОБАВЛЯЕМ ДЕТАЛЬНУЮ ОТЛАДКУ
        print("   habit completions count: \(habit.completions?.count ?? 0)")
        if let completions = habit.completions {
            for completion in completions {
                print("     completion: date=\(completion.date), value=\(completion.value)")
            }
        }

        // ✅ Проверяем прогресс из БД еще раз для уверенности
        let directProgress = habit.progressForDate(date)
        print("   direct progress check: \(directProgress)")

        if cachedProgress != directProgress {
            print("   ⚠️ ПРОБЛЕМА: cachedProgress != directProgress!")
        }
        
        // ✅ Для сегодняшних time привычек запускаем локальные обновления если таймер активен
        if isToday && habit.type == .time {
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
        // ✅ ИСПРАВЛЕНО: обновляем кэш И триггер
        cachedProgress = habit.progressForDate(date)
        localUpdateTrigger += 1
        print("🔄 UI updated for \(habit.title): cached progress = \(cachedProgress)")
    }
    
    // MARK: - Progress Methods
    
    func incrementProgress() {
        print("🔄 incrementProgress called for: \(habit.title)")
        print("   habit.uuid: \(habit.uuid)")
        
        let incrementValue = habit.type == .count ? 1 : 60
        habit.addToProgress(incrementValue, for: date, modelContext: modelContext)
        
        print("   after addToProgress, direct check: \(habit.progressForDate(date))")
        
        forceUIUpdate()
    }
    
    func decrementProgress() {
        guard currentProgress > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            return
        }
        
        let decrementValue = habit.type == .count ? -1 : -60
        
        // 1. Добавляем к существующему прогрессу в базе
        habit.addToProgress(decrementValue, for: date, modelContext: modelContext)
        
        // 2. ✅ КРИТИЧНО: Обновляем кэш сразу после изменения БД
        forceUIUpdate()
    }
    
    func handleCustomCountInput(count: Int) {
        habit.addToProgress(count, for: date, modelContext: modelContext)
        
        // ✅ КРИТИЧНО: Обновляем кэш сразу после изменения БД
        forceUIUpdate()
        
        alertState.successFeedbackTrigger.toggle()
    }

    func handleCustomTimeInput(hours: Int, minutes: Int) {
        let totalSeconds = (hours * 3600) + (minutes * 60)
        
        guard totalSeconds > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            return
        }
        
        habit.addToProgress(totalSeconds, for: date, modelContext: modelContext)
        
        // ✅ КРИТИЧНО: Обновляем кэш сразу после изменения БД
        forceUIUpdate()
        
        alertState.successFeedbackTrigger.toggle()
    }
    
    func completeHabit() {
        guard !isAlreadyCompleted else { return }
        
        habit.complete(for: date, modelContext: modelContext)
        
        // ✅ КРИТИЧНО: Обновляем кэш сразу после изменения БД
        forceUIUpdate()
        
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
        
        // ✅ КРИТИЧНО: Обновляем кэш сразу после изменения БД
        forceUIUpdate()
    }
    
    // MARK: - Timer Management
    
    private func startLocalUpdates() {
        guard habit.type == .time && isToday else { return }
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let habitId = self.habit.uuid.uuidString
                
                // ✅ ИСПРАВЛЕНО: Обновляем UI только если ЭТОТ таймер активен
                if self.timerService.isTimerRunning(for: habitId) {
                    // ✅ НЕ обновляем кэш здесь - live прогресс берется из TimerService
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
                
                // ✅ КРИТИЧНО: Обновляем кэш после сохранения в БД
                forceUIUpdate()
                
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
            
            // ✅ ИСПРАВЛЕНО: используем кэшированный прогресс
            let success = timerService.startTimer(for: habitId, baseProgress: cachedProgress)

            if !success {
                alertState.errorFeedbackTrigger.toggle()
                print("❌ Failed to start timer")
                return
            }
            
            // ✅ Запускаем локальные обновления
            startLocalUpdates()
            
            print("✅ Timer started for: \(habit.title), initial progress: \(cachedProgress)")
            
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
