import SwiftUI
import SwiftData

@Observable @MainActor
final class HabitDetailViewModel {
    // MARK: - Dependencies
    private let habit: Habit
    private let date: Date
    private let modelContext: ModelContext
    private let progressService = ProgressService.shared
    private let timerService = TimerService.shared
    private let liveActivityManager = HabitLiveActivityManager.shared
    private let widgetActionService = WidgetActionService.shared
    private var widgetActionTask: Task<Void, Never>?
    
    // MARK: - UI State
    var alertState = AlertState()
    var onHabitDeleted: (() -> Void)?
    var hasActiveLiveActivity: Bool = false
    
    // MARK: - Constants
    private enum Limits {
        static let maxCount = 999999
        static let maxTimeSeconds = 86400 // 24 hours
    }
    
    // MARK: - Computed Properties
    
    var currentProgress: Int {
        return progressService.getProgress(for: habit, date: date)
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
        return progressService.isTimerRunning(for: habit)
    }
    
    var canStartTimer: Bool {
        timerService.canStartNewTimer || isTimerRunning
    }
    
    var activeTimerCount: Int {
        timerService.activeTimerCount
    }
    
    var remainingTimerSlots: Int {
        timerService.remainingSlots
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
        
        print("🚀 HabitDetailViewModel init:")
        print("   habit.title: \(habit.title)")
        print("   habit.type: \(habit.type)")
        print("   date: \(date)")
        print("   isToday: \(Calendar.current.isDateInToday(date))")
        print("   currentProgress: \(currentProgress)")
        
        // Initialize progress in TimerService if today but no active timer
        if isToday {
            let habitId = habit.uuid.uuidString
            let dbProgress = habit.progressForDate(date)
            
            // Only set if no current live progress
            if timerService.liveProgress[habitId] == nil {
                timerService.setProgress(dbProgress, for: habitId)
            }
        }
        
        // Setup Live Activities
        setupLiveActivities()
    }
    
    // MARK: - Live Activities Setup
    
    private func setupLiveActivities() {
        guard habit.type == .time && isToday else { return }
        
        print("🔧 Setting up Live Activities for: \(habit.title)")
        
        Task {
            await liveActivityManager.restoreActiveActivitiesIfNeeded()
            await updateLiveActivityState()
            
            // Start global listener only once
            if !liveActivityManager.isListeningForWidgetActions {
                liveActivityManager.startListeningForWidgetActions()
                print("🔧 Started global widget listener for app")
            }
        }
        
        // Start observing widget actions through service
        startObservingWidgetActions()
    }
    
    private func startObservingWidgetActions() {
        let habitId = habit.uuid.uuidString
        let habitTitle = habit.title
        
        widgetActionTask = Task { [weak self] in
            for await action in WidgetActionService.shared.observeActions(for: habitId) {
                guard let self = self else { break }
                print("🔔 Widget action received: \(action) for \(habitTitle)")
                await self.handleWidgetAction(action)
            }
        }
    }
    
    private func handleWidgetAction(_ action: WidgetAction) async {
        print("🔍 Processing widget action: \(action) for habit: \(habit.title)")
        print("🔍 Current timer state: \(isTimerRunning)")
        
        switch action {
        case .toggleTimer:
            print("🔄 Widget requested timer toggle for \(habit.title)")
            toggleTimer()
            
            // ВАЖНО: Принудительно обновляем Live Activity
            print("🔄 Force updating Live Activity after widget action")
            Task {
                await updateLiveActivity()
            }
            
        case .dismissActivity:
            print("❌ Widget requested dismiss for \(habit.title)")
            await liveActivityManager.endActivity(for: habit.uuid.uuidString)
            await updateLiveActivityState()
            return
        }
        
        await updateLiveActivityState()
    }
    
    private func updateLiveActivityState() async {
        hasActiveLiveActivity = liveActivityManager.hasActiveActivity(for: habit.uuid.uuidString)
    }

    // MARK: - Manual Live Activity Controls

    func startLiveActivityManually() async {
        guard habit.type == .time, isToday else { return }
        
        if !isTimerRunning {
            startTimer()
        }
        
        guard let startTime = timerStartTime else { return }
        
        await liveActivityManager.startActivity(
            for: habit,
            currentProgress: currentProgress,
            timerStartTime: startTime
        )
        
        await updateLiveActivityState()
    }

    func endLiveActivityManually() async {
        await liveActivityManager.endActivity(for: habit.uuid.uuidString)
        await updateLiveActivityState()
    }
    
    // MARK: - Timer Management
    
    func toggleTimer() {
        print("🔄 toggleTimer() called")
        print("   habit.type: \(habit.type)")
        print("   isToday: \(isToday)")
        print("   isTimerRunning: \(isTimerRunning)")
        
        guard habit.type == .time && isToday else {
            print("❌ Timer toggle blocked: habit.type=\(habit.type), isToday=\(isToday)")
            return
        }
        
        do {
            let wasRunning = isTimerRunning
            let success = try progressService.toggleTimer(for: habit, date: date, modelContext: modelContext)
            
            if !wasRunning && !success {
                showTimerLimitAlert()
                return
            }
            
            // Update Live Activity
            Task {
                await updateLiveActivity()
            }
            
        } catch {
            print("❌ Timer toggle failed: \(error)")
            alertState.errorFeedbackTrigger.toggle()
        }
    }
    
    // MARK: - Private Timer Methods
    
    private func startTimer() {
        guard habit.type == .time && isToday else { return }
        guard canStartTimer else {
            showTimerLimitAlert()
            return
        }
        
        do {
            let success = try progressService.toggleTimer(for: habit, date: date, modelContext: modelContext)
            if success {
                // Start Live Activity
                Task {
                    await updateLiveActivity()
                }
            }
        } catch {
            print("❌ Start timer failed: \(error)")
            alertState.errorFeedbackTrigger.toggle()
        }
    }
    
    private func stopTimer() {
        guard habit.type == .time && isToday else { return }
        
        do {
            _ = try progressService.toggleTimer(for: habit, date: date, modelContext: modelContext)
            // Update Live Activity
            Task {
                await updateLiveActivity()
            }
        } catch {
            print("❌ Stop timer failed: \(error)")
            alertState.errorFeedbackTrigger.toggle()
        }
    }
    
    private func updateLiveActivity() async {
        print("🔍 updateLiveActivity called for: \(habit.title)")
        print("🔍 habitId: \(habit.uuid.uuidString)")
        print("🔍 isTimerRunning: \(isTimerRunning)")
        
        guard habit.type == .time && isToday else {
            print("❌ Guard failed - not time habit or not today")
            return
        }
        
        let habitId = habit.uuid.uuidString
        
        if isTimerRunning {
            let timerStartTime = timerService.getTimerStartTime(for: habitId) ?? Date()
            print("🎬 Starting Live Activity for \(habit.title)")
            
            await liveActivityManager.startActivity(
                for: habit,
                currentProgress: currentProgress,
                timerStartTime: timerStartTime
            )
            print("🎬 Live Activity started for \(habit.title)")
        } else {
            // ВАЖНО: НЕ обновляйте Live Activity при остановке таймера!
            // Live Activity должна продолжать показывать финальный результат
            print("⏸️ Timer stopped for \(habit.title) - Live Activity continues showing final result")
            
            // Только обновляем финальное состояние если Live Activity активна
            if liveActivityManager.hasActiveActivity(for: habitId) {
                await liveActivityManager.updateActivity(
                    for: habitId,
                    currentProgress: currentProgress,
                    isTimerRunning: false,
                    timerStartTime: nil
                )
            }
        }
        
        await updateLiveActivityState()
    }
    
    private func showTimerLimitAlert() {
        alertState.errorFeedbackTrigger.toggle()
        print("❌ Timer limit reached: \(activeTimerCount)/5")
    }
    
    // MARK: - Progress Operations
    
    func incrementProgress() {
        guard !isAlreadyCompleted else {
            alertState.errorFeedbackTrigger.toggle()
            return
        }
        
        do {
            let value = habit.type == .count ? 1 : 60
            try progressService.addProgress(value, for: habit, date: date, modelContext: modelContext)
        } catch {
            print("❌ Increment failed: \(error)")
            alertState.errorFeedbackTrigger.toggle()
        }
    }
    
    func decrementProgress() {
        guard currentProgress > 0 else { return }
        
        do {
            let value = habit.type == .count ? -1 : -60
            try progressService.addProgress(value, for: habit, date: date, modelContext: modelContext)
        } catch {
            print("❌ Decrement failed: \(error)")
            alertState.errorFeedbackTrigger.toggle()
        }
    }
    
    func completeHabit() {
        guard !isAlreadyCompleted else { return }
        
        do {
            try progressService.completeHabit(habit, date: date, modelContext: modelContext)
            alertState.successFeedbackTrigger.toggle()
            
            // ТОЛЬКО тут завершаем Live Activity - когда цель достигнута
            if habit.type == .time && isToday {
                Task {
                    await liveActivityManager.endActivity(for: habit.uuid.uuidString)
                    await updateLiveActivityState()
                }
            }
        } catch {
            print("❌ Complete failed: \(error)")
            alertState.errorFeedbackTrigger.toggle()
        }
    }
    
    func resetProgress() {
        do {
            try progressService.resetProgress(for: habit, date: date, modelContext: modelContext)
        } catch {
            print("❌ Reset failed: \(error)")
            alertState.errorFeedbackTrigger.toggle()
        }
    }
    
    // MARK: - Manual Input Handling
    
    func handleCountInput() {
        guard let value = Int(alertState.countInputText), value > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            alertState.countInputText = ""
            return
        }
        
        do {
            try progressService.addProgress(value, for: habit, date: date, modelContext: modelContext)
            alertState.successFeedbackTrigger.toggle()
            alertState.countInputText = ""
        } catch {
            print("❌ Count input failed: \(error)")
            alertState.errorFeedbackTrigger.toggle()
            alertState.countInputText = ""
        }
    }
    
    func handleTimeInput() {
        let hours = Int(alertState.hoursInputText) ?? 0
        let minutes = Int(alertState.minutesInputText) ?? 0
        let totalSeconds = (hours * 3600) + (minutes * 60)
        
        guard totalSeconds > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            clearTimeInputs()
            return
        }
        
        do {
            try progressService.addProgress(totalSeconds, for: habit, date: date, modelContext: modelContext)
            alertState.successFeedbackTrigger.toggle()
            clearTimeInputs()
        } catch {
            print("❌ Time input failed: \(error)")
            alertState.errorFeedbackTrigger.toggle()
            clearTimeInputs()
        }
    }
    
    private func clearTimeInputs() {
        alertState.hoursInputText = ""
        alertState.minutesInputText = ""
    }
    
    // MARK: - Delete Operations
    
    func deleteHabit() {
        do {
            // Завершаем Live Activity при удалении привычки
            if habit.type == .time && isToday && hasActiveLiveActivity {
                Task {
                    await liveActivityManager.endActivity(for: habit.uuid.uuidString)
                }
            }
            
            cleanup()
            modelContext.delete(habit)
            try modelContext.save()
        } catch {
            print("❌ Delete failed: \(error)")
        }
    }
    
    // MARK: - Cleanup
    
    func saveIfNeeded() {
        // ProgressService handles all saving automatically
    }
    
    func cleanup() {
        // Cancel widget action observation
        widgetActionTask?.cancel()
        widgetActionTask = nil
        
        // Remove any remaining observers
        NotificationCenter.default.removeObserver(self)
        onHabitDeleted = nil
    }
}
