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
    var hasActiveLiveActivity: Bool {
        let habitId = habit.uuid.uuidString
        return liveActivityManager.hasActiveActivity(for: habitId)
    }
    
    // MARK: - Computed Properties
    
    var currentProgress: Int {
        let habitId = habit.uuid.uuidString
        
        // Если сегодня и таймер активен - берем live прогресс И подписываемся на обновления
        if isToday && habit.type == .time && timerService.isTimerRunning(for: habitId) {
            _ = localUpdateTrigger
            
            if let liveProgress = timerService.getLiveProgress(for: habitId) {
                return liveProgress
            }
        }
        
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
        
        // ✅ Инициализируем кэшированный прогресс из БД
        self.cachedProgress = habit.progressForDate(date)
        print("   initial cached progress: \(cachedProgress)")
        
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
            cachedProgress = habit.progressForDate(date)
            localUpdateTrigger += 1
            print("🔄 UI updated for \(habit.title): cached progress = \(cachedProgress)")
        }
    
    // MARK: - Progress Methods
    
    func incrementProgress() {
            let incrementValue = habit.type == .count ? 1 : 60
            habit.addToProgress(incrementValue, for: date, modelContext: modelContext)
            forceUIUpdate()
        }
    
    func decrementProgress() {
            guard currentProgress > 0 else {
                alertState.errorFeedbackTrigger.toggle()
                return
            }
            
            let decrementValue = habit.type == .count ? -1 : -60
            habit.addToProgress(decrementValue, for: date, modelContext: modelContext)
            forceUIUpdate()
        }
    
    func handleCustomCountInput(count: Int) {
            habit.addToProgress(count, for: date, modelContext: modelContext)
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
            forceUIUpdate()
            alertState.successFeedbackTrigger.toggle()
        }
    
    func completeHabit() {
            guard !isAlreadyCompleted else { return }
            
            habit.complete(for: date, modelContext: modelContext)
            forceUIUpdate()
            alertState.successFeedbackTrigger.toggle()
            
            // Завершаем Live Activity если это time привычка сегодня
            if habit.type == .time && isToday && hasActiveLiveActivity {
                Task {
                    await liveActivityManager.endActivity(for: habit.uuid.uuidString)
                }
            }
        }
    
    func resetProgress() {
            habit.resetProgress(for: date, modelContext: modelContext)
            forceUIUpdate()
        }
    
    // MARK: - Timer Management
    
    private func startLocalUpdates() {
            guard habit.type == .time && isToday else { return }
            
            updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    let habitId = self.habit.uuid.uuidString
                    
                    if self.timerService.isTimerRunning(for: habitId) {
                        self.localUpdateTrigger += 1
                        
                        // ✅ НОВОЕ: Обновляем Live Activity каждые 30 секунд для синхронизации
                        let elapsed = Int(Date().timeIntervalSince(self.timerService.getTimerStartTime(for: habitId) ?? Date()))
                        
                        if elapsed % 30 == 0 && self.hasActiveLiveActivity {
                            await self.liveActivityManager.updateActivity(
                                for: habitId,
                                currentProgress: self.currentProgress,
                                isTimerRunning: true,
                                timerStartTime: self.timerStartTime
                            )
                            print("🔄 Live Activity synced at \(elapsed)s")
                        }
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
            
            stopLocalUpdates()
            
            if let finalProgress = timerService.stopTimer(for: habitId) {
                habit.updateProgress(to: finalProgress, for: date, modelContext: modelContext)
                
                // ✅ КРИТИЧНО: Обновляем кэш ПЕРЕД отправкой в Live Activity
                cachedProgress = finalProgress
                
                print("   Saved final progress to DB: \(finalProgress)")
                
                // ✅ ИСПРАВЛЕНО: Используем обновленный cachedProgress
                Task {
                    await liveActivityManager.updateActivity(
                        for: habitId,
                        currentProgress: cachedProgress, // ✅ Теперь правильное значение!
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
            
            let success = timerService.startTimer(for: habitId, baseProgress: cachedProgress)

            if !success {
                alertState.errorFeedbackTrigger.toggle()
                print("❌ Failed to start timer")
                return
            }
            
            startLocalUpdates()
            
            print("✅ Timer started for: \(habit.title), initial progress: \(cachedProgress)")
            
            Task {
                await startLiveActivity()
            }
        }
    }
    
    // MARK: - Live Activities
    
    private func setupLiveActivities() {
            let habitId = habit.uuid.uuidString
            let habitTitle = habit.title
            
            NotificationCenter.default.addObserver(
                forName: .widgetActionReceived,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self = self,
                      let actionNotification = notification.object as? WidgetActionNotification,
                      actionNotification.habitId == habitId else { return }
                
                print("🔔 Widget action received: \(actionNotification.action) for \(habitTitle)")
                
                Task { @MainActor in
                    await self.handleWidgetAction(actionNotification.action)
                }
            }
            
            print("🔧 Started observing widget actions for: \(habitTitle)")
        }
        
        private func handleWidgetAction(_ action: WidgetAction) async {
            switch action {
            case .toggleTimer:
                toggleTimer()
            case .dismissActivity:
                await liveActivityManager.endActivity(for: habit.uuid.uuidString)
            }
        }
        
        private func startLiveActivity() async {
            guard let startTime = timerStartTime else {
                print("⚠️ Cannot start Live Activity: no timer start time")
                return
            }
            
            print("🎬 Starting Live Activity for: \(habit.title)")
            
            await liveActivityManager.startActivity(
                for: habit,
                currentProgress: currentProgress,
                timerStartTime: startTime
            )
            
            print("✅ Live Activity started for: \(habit.title)")
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
        NotificationCenter.default.removeObserver(self, name: .widgetActionReceived, object: nil)
        onHabitDeleted = nil
        print("🧹 Cleaned up HabitDetailViewModel for: \(habit.title)")
    }
    
}
