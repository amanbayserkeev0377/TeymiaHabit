import SwiftUI
import SwiftData

@Observable @MainActor
final class HabitDetailViewModel {
    // MARK: - Constants
    private enum Constants {
        static let incrementTimeValue = 60 // seconds
        static let decrementTimeValue = -60 // seconds
        static let liveActivitySyncInterval = 10 // seconds
    }
    
    // MARK: - Dependencies
    private let habit: Habit
    private let modelContext: ModelContext
    private let timerService = TimerService.shared
    private let liveActivityManager = HabitLiveActivityManager.shared
    
    // MARK: - State
    private var currentDisplayedDate: Date
    private var updateTimer: Timer?
    private(set) var localUpdateTrigger: Int = 0
    private var progressCache: [String: Int] = [:]
    private var baseProgressWhenTimerStarted: Int?

    
    // ✅ КРИТИЧНО: Кэшируем habitId один раз при инициализации
    private let cachedHabitId: String
    
    // MARK: - Static Properties
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // MARK: - UI State
    var alertState = AlertState()
    var onHabitDeleted: (() -> Void)?
    
    // MARK: - Computed Properties
    
    var hasActiveLiveActivity: Bool {
        liveActivityManager.hasActiveActivity(for: cachedHabitId)
    }
    
    var currentProgress: Int {
        let dateKey = dateToKey(currentDisplayedDate)
        
        // Live progress for active timers today
        if isTimeHabitToday && timerService.isTimerRunning(for: cachedHabitId) {
            _ = localUpdateTrigger // Subscribe to updates
            
            if let liveProgress = timerService.getLiveProgress(for: cachedHabitId) {
                return liveProgress
            }
        }
        
        // Return cached or load from DB
        if let cached = progressCache[dateKey] {
            return cached
        }
        
        let progress = habit.progressForDate(currentDisplayedDate)
        progressCache[dateKey] = progress
        return progress
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
        timerService.isTimerRunning(for: cachedHabitId)
    }
    
    var canStartTimer: Bool {
        timerService.canStartNewTimer || isTimerRunning
    }
    
    var timerStartTime: Date? {
        timerService.getTimerStartTime(for: cachedHabitId)
    }
    
    // MARK: - Computed Properties
    
    var habitId: String {
        cachedHabitId
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(currentDisplayedDate)
    }
    
    private var isTimeHabitToday: Bool {
        habit.type == .time && isToday
    }
    
    // MARK: - Helper Methods
    
    private func dateToKey(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }
    
    // MARK: - Initialization
    
    init(habit: Habit, initialDate: Date, modelContext: ModelContext) {
        self.habit = habit
        self.currentDisplayedDate = initialDate
        self.modelContext = modelContext
        self.cachedHabitId = habit.uuid.uuidString
        
        print("🚀 HabitDetailViewModel init for habit: \(habit.title)")
        print("   cachedHabitId: \(cachedHabitId)")
        print("   initialDate: \(initialDate)")
        
        // Load initial progress
        let initialProgress = habit.progressForDate(initialDate)
        progressCache[dateToKey(initialDate)] = initialProgress
        print("   initial progress: \(initialProgress)")
        
        setupStableSubscriptions()
        
        // Start local updates if needed
        if isTimeHabitToday && timerService.isTimerRunning(for: cachedHabitId) {
            // ✅ ВАЖНО: Восстанавливаем baseProgressWhenTimerStarted для уже запущенного таймера
            baseProgressWhenTimerStarted = habit.progressForDate(initialDate)
            print("🔄 Restored baseProgressWhenTimerStarted: \(baseProgressWhenTimerStarted!)")
            
            startLocalUpdates()
        }
    }
    
    // MARK: - Date Management
    
    func updateDisplayedDate(_ newDate: Date) {
        currentDisplayedDate = newDate
        
        // Load progress for new date
        let dateKey = dateToKey(newDate)
        if progressCache[dateKey] == nil {
            let progress = habit.progressForDate(newDate)
            progressCache[dateKey] = progress
        }
        
        // Update local timer updates
        if Calendar.current.isDateInToday(newDate) && habit.type == .time {
            if timerService.isTimerRunning(for: cachedHabitId) && updateTimer == nil {
                startLocalUpdates()
            }
        } else {
            stopLocalUpdates()
        }
        
        localUpdateTrigger += 1
    }
    
    // MARK: - Subscriptions
        
        private func setupStableSubscriptions() {
            let habitTitle = habit.title
            let habitId = cachedHabitId
            
            print("🔧 Setting up STABLE subscriptions for: \(habitTitle)")
            print("   cachedHabitId: \(habitId)")
            
            // ✅ УПРОЩЕНО: Убираем сложную логику Widget Actions
            // Теперь HabitWidgetService обрабатывает все Widget Actions централизованно
            // ViewModel фокусируется только на UI состоянии
            
            print("✅ STABLE subscriptions setup completed for: \(habitTitle)")
        }
    
    // MARK: - Progress Management
    
    private func updateProgressInCacheAndDB(_ newProgress: Int) {
        let dateKey = dateToKey(currentDisplayedDate)
        progressCache[dateKey] = newProgress
        habit.updateProgress(to: newProgress, for: currentDisplayedDate, modelContext: modelContext)
        
        // ✅ КРИТИЧНО: Явное сохранение для CloudKit
        do {
            try modelContext.save()
            print("🔄 Progress updated and saved for \(habit.title): \(newProgress)")
        } catch {
            print("❌ Error saving progress: \(error.localizedDescription)")
            alertState.errorFeedbackTrigger.toggle()
        }
        
        localUpdateTrigger += 1
    }
    
    // MARK: - Progress Methods
    
    func incrementProgress() {
        let incrementValue = habit.type == .count ? 1 : Constants.incrementTimeValue
        stopTimerAndSaveLiveProgressIfNeeded()
        
        let newProgress = currentProgress + incrementValue
        updateProgressInCacheAndDB(newProgress)
        updateLiveActivityAfterManualChange()
    }

    func decrementProgress() {
        guard currentProgress > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            return
        }
        
        let decrementValue = habit.type == .count ? -1 : Constants.decrementTimeValue
        stopTimerAndSaveLiveProgressIfNeeded()
        
        let newProgress = max(0, currentProgress + decrementValue)
        updateProgressInCacheAndDB(newProgress)
        updateLiveActivityAfterManualChange()
    }

    func handleCustomCountInput(count: Int) {
        stopTimerAndSaveLiveProgressIfNeeded()
        updateProgressInCacheAndDB(currentProgress + count)
        alertState.successFeedbackTrigger.toggle()
        updateLiveActivityAfterManualChange()
    }

    func handleCustomTimeInput(hours: Int, minutes: Int) {
        let totalSeconds = (hours * 3600) + (minutes * 60)
        
        guard totalSeconds > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            return
        }
        
        stopTimerAndSaveLiveProgressIfNeeded()
        updateProgressInCacheAndDB(currentProgress + totalSeconds)
        alertState.successFeedbackTrigger.toggle()
        updateLiveActivityAfterManualChange()
    }
    
    func completeHabit() {
        guard !isAlreadyCompleted else { return }
        
        if isTimeHabitToday && isTimerRunning {
            stopTimerAndEndActivity()
        }
        
        updateProgressInCacheAndDB(habit.goal)
        alertState.successFeedbackTrigger.toggle()
        endLiveActivityIfNeeded()
    }
    
    func resetProgress() {
        if isTimeHabitToday && isTimerRunning {
            stopTimerAndEndActivity()
        }
        
        updateProgressInCacheAndDB(0)
        updateLiveActivityIfActive(progress: 0, isTimerRunning: false)
    }
    
    // MARK: - Timer Management
    
    private func startLocalUpdates() {
        guard isTimeHabitToday else { return }
        
        // ✅ Timer каждую секунду для точности UI
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.handleTimerTick()
            }
        }
        
        print("⏱️ Started precise 1-second timer updates for \(habit.title)")
    }
    
    private func handleTimerTick() async {
        guard timerService.isTimerRunning(for: cachedHabitId) else {
            print("⚠️ Timer stopped, ending local updates")
            stopLocalUpdates()
            return
        }
        
        // Check if goal reached
        if currentProgress >= habit.goal {
            await handleGoalReached()
            return
        }
        
        // ✅ ОБНОВЛЕНИЕ UI каждую секунду
        localUpdateTrigger += 1
        
        // ✅ Синхронизация Live Activity каждые 5 секунд (батарея + производительность)
        await syncLiveActivityIfNeeded()
    }
    
    private func forceSyncLiveActivity() async {
        guard hasActiveLiveActivity,
              let startTime = timerStartTime else { return }
        
        await liveActivityManager.updateActivity(
            for: cachedHabitId,
            currentProgress: currentProgress,
            isTimerRunning: true,
            timerStartTime: startTime
        )
    }
    
    private func handleGoalReached() async {
        _ = timerService.stopTimer(for: cachedHabitId)
        updateProgressInCacheAndDB(habit.goal)
        
        await liveActivityManager.updateActivity(
            for: cachedHabitId,
            currentProgress: habit.goal,
            isTimerRunning: false,
            timerStartTime: nil
        )
        
        stopLocalUpdates()
        alertState.successFeedbackTrigger.toggle()
    }
    
    private func syncLiveActivityIfNeeded() async {
        guard hasActiveLiveActivity,
              let startTime = timerStartTime,
              let baseProgress = baseProgressWhenTimerStarted else { return }
        
        let elapsed = Int(Date().timeIntervalSince(startTime))
        
        if elapsed % Constants.liveActivitySyncInterval == 0 {
            await liveActivityManager.updateActivity(
                for: cachedHabitId,
                currentProgress: baseProgress, // ✅ Используем сохраненный базовый прогресс!
                isTimerRunning: true,
                timerStartTime: startTime
            )
            
            print("🔄 Live Activity synced:")
            print("   elapsed: \(elapsed)s")
            print("   baseProgress (saved): \(baseProgress)")
            print("   Live Activity shows: \(baseProgress + elapsed)")
        }
    }
    
    private func stopLocalUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    func toggleTimer() {
        guard isTimeHabitToday else { return }
        
        if isTimerRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        guard timerService.canStartNewTimer else {
            alertState.errorFeedbackTrigger.toggle()
            return
        }
        
        print("🚀 Starting timer for \(habit.title) with habitId: \(cachedHabitId)")
        
        let baseProgress = currentProgress
        baseProgressWhenTimerStarted = baseProgress
        
        let success = timerService.startTimer(for: cachedHabitId, baseProgress: baseProgress)
        
        if success {
            startLocalUpdates()
            
            Task {
                await startLiveActivity()
                if let startTime = timerService.getTimerStartTime(for: cachedHabitId) {
                    await liveActivityManager.updateActivity(
                        for: cachedHabitId,
                        currentProgress: baseProgress,
                        isTimerRunning: true,
                        timerStartTime: startTime
                    )
                }
            }
            
            print("✅ Timer started successfully for \(habit.title)")
            print("   baseProgress saved: \(baseProgress)")
        } else {
            alertState.errorFeedbackTrigger.toggle()
            print("❌ Failed to start timer for \(habit.title)")
        }
    }
    
    private func stopTimer() {
        print("🛑 Stopping timer for \(habit.title) with habitId: \(cachedHabitId)")
        stopLocalUpdates()
        
        if let finalProgress = timerService.stopTimer(for: cachedHabitId) {
            updateProgressInCacheAndDB(finalProgress)
            
            // ✅ НЕМЕДЛЕННО обновляем Live Activity с финальным прогрессом
            Task {
                await liveActivityManager.updateActivity(
                    for: cachedHabitId,
                    currentProgress: finalProgress,
                    isTimerRunning: false,
                    timerStartTime: nil
                )
            }
            
            print("✅ Timer stopped for \(habit.title), final progress: \(finalProgress)")
        }
        
        // ✅ Очищаем сохраненный базовый прогресс
        baseProgressWhenTimerStarted = nil
    }
    
    // MARK: - Live Activities
    
    private func handleWidgetAction(_ action: WidgetAction) async {
        switch action {
        case .toggleTimer:
            toggleTimer()
        case .dismissActivity:
            await liveActivityManager.endActivity(for: habitId)
        }
    }
    
    private func startLiveActivity() async {
        guard let startTime = timerStartTime,
              let baseProgress = baseProgressWhenTimerStarted else { return }
        
        await liveActivityManager.startActivity(
            for: habit,
            currentProgress: baseProgress, // ✅ Используем сохраненный базовый прогресс!
            timerStartTime: startTime
        )
        
        print("🚀 Live Activity started with saved baseProgress: \(baseProgress)")
    }
    
    private func stopTimerAndSaveLiveProgressIfNeeded() {
        guard isTimeHabitToday && isTimerRunning else { return }
        
        let liveProgress = timerService.getLiveProgress(for: cachedHabitId) ?? currentProgress
        stopLocalUpdates()
        _ = timerService.stopTimer(for: cachedHabitId)
        updateProgressInCacheAndDB(liveProgress)
        print("🛑 Stopped timer and saved progress for \(habit.title): \(liveProgress)")
        
        baseProgressWhenTimerStarted = nil
    }
    
    private func stopTimerAndEndActivity() {
        stopLocalUpdates()
        _ = timerService.stopTimer(for: cachedHabitId)
        baseProgressWhenTimerStarted = nil
    }
    
    private func updateLiveActivityAfterManualChange() {
        updateLiveActivityIfActive(progress: currentProgress, isTimerRunning: false)
    }
    
    private func updateLiveActivityIfActive(progress: Int, isTimerRunning: Bool) {
        guard isTimeHabitToday && hasActiveLiveActivity else { return }
        
        Task {
            await liveActivityManager.updateActivity(
                for: cachedHabitId,
                currentProgress: progress,
                isTimerRunning: isTimerRunning,
                timerStartTime: isTimerRunning ? timerStartTime : nil
            )
        }
    }
    
    private func endLiveActivityIfNeeded() {
        guard isTimeHabitToday && hasActiveLiveActivity else { return }
        
        Task {
            await liveActivityManager.endActivity(for: cachedHabitId)
        }
    }
    
    private func debugTimerState() {
        print("🔍 Timer State Debug:")
        print("   isTimerRunning: \(isTimerRunning)")
        print("   timerStartTime: \(String(describing: timerStartTime))")
        print("   baseProgressWhenTimerStarted: \(String(describing: baseProgressWhenTimerStarted))")
        print("   currentProgress: \(currentProgress)")
        
        if let startTime = timerStartTime {
            let elapsed = Int(Date().timeIntervalSince(startTime))
            print("   elapsed: \(elapsed)s")
            
            if let base = baseProgressWhenTimerStarted {
                print("   expected Live Activity: \(base + elapsed)")
            }
        }
    }
    
    // MARK: - Delete Operations
    
    func deleteHabit() {
        NotificationCenter.default.removeObserver(self, name: .widgetActionReceived, object: nil)
        endLiveActivityIfNeeded()
        cleanup()
        modelContext.delete(habit)
        try? modelContext.save()
    }
    
    // MARK: - Cleanup
    
    func syncWithTimerService() {
        guard isTimeHabitToday, timerService.isTimerRunning(for: cachedHabitId) else { return }
        if let liveProgress = timerService.getLiveProgress(for: cachedHabitId) {
            updateProgressInCacheAndDB(liveProgress)
            print("🔄 Synced progress for \(habit.title): \(liveProgress)")
        }
    }
    
    func cleanup() {
        stopLocalUpdates()
        NotificationCenter.default.removeObserver(self, name: .widgetActionReceived, object: nil)
        onHabitDeleted = nil
    }
}
