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
    private let widgetActionService = WidgetActionService.shared
    private var widgetActionTask: Task<Void, Never>?
    private var lastLiveActivityUpdate: Date = Date.distantPast
    private let liveActivityUpdateThrottle: TimeInterval = 0.5 // 500ms
    
    // MARK: - UI State
    var alertState = AlertState()
    var isTimeInputPresented: Bool = false  // ✅ ДОБАВЛЕНО
    var onHabitDeleted: (() -> Void)?
    var hasActiveLiveActivity: Bool = false
    
    // MARK: - Constants
    private enum Limits {
        static let maxCount = 999999
        static let maxTimeSeconds = 86400 // 24 hours
    }
    
    // MARK: - Computed Properties
    
    var currentProgress: Int {
        if Calendar.current.isDateInToday(date) {
            let habitId = habit.uuid.uuidString
            return timerService.getCurrentProgress(for: habitId)
        } else {
            return habit.progressForDate(date)
        }
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
            
            if !liveActivityManager.isListeningForWidgetActions {
                liveActivityManager.startListeningForWidgetActions()
                print("🔧 Started global widget listener for app")
            }
        }
        
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
        print("🔄 toggleTimer() called for: \(habit.title)")
        
        guard habit.type == .time && isToday else {
            print("❌ Timer toggle blocked")
            return
        }
        
        let habitId = habit.uuid.uuidString
        
        if timerService.isTimerRunning(for: habitId) {
            // Останавливаем таймер
            timerService.stopTimer(for: habitId)
            
            // Сохраняем прогресс в базу
            Task {
                await saveProgressToDatabase(timerService.getCurrentProgress(for: habitId))
            }
        } else {
            // Проверяем лимит таймеров
            guard timerService.canStartNewTimer else {
                showTimerLimitAlert()
                return
            }
            
            // Запускаем таймер
            let dbProgress = habit.progressForDate(date)
            let success = timerService.startTimer(for: habitId, initialProgress: dbProgress)
            
            if !success {
                showTimerLimitAlert()
                return
            }
        }
        
        // Обновляем Live Activity
        Task {
            await updateLiveActivity()
        }
    }
    
    private func startTimer() {
        guard habit.type == .time && isToday else { return }
        guard canStartTimer else {
            showTimerLimitAlert()
            return
        }
        
        let habitId = habit.uuid.uuidString
        let dbProgress = habit.progressForDate(date)
        let success = timerService.startTimer(for: habitId, initialProgress: dbProgress)
        
        if success {
            Task {
                await updateLiveActivity()
            }
        } else {
            alertState.errorFeedbackTrigger.toggle()
        }
    }
    
    private func updateLiveActivity() async {
        let now = Date()
        guard now.timeIntervalSince(lastLiveActivityUpdate) >= liveActivityUpdateThrottle else {
            print("🔄 Live Activity update throttled")
            return
        }
        lastLiveActivityUpdate = now
        
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
            print("⏸️ Timer stopped for \(habit.title) - Live Activity continues showing final result")
            
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
    
    func completeHabit() {
        guard !isAlreadyCompleted else { return }
        
        Task {
            do {
                try await completeHabitAsync()
                alertState.successFeedbackTrigger.toggle()
            } catch {
                print("❌ Complete failed: \(error)")
                alertState.errorFeedbackTrigger.toggle()
            }
        }
    }
    
    func resetProgress() {
        Task {
            do {
                try await resetProgressAsync()
            } catch {
                print("❌ Reset failed: \(error)")
                alertState.errorFeedbackTrigger.toggle()
            }
        }
    }
    
    // MARK: - Manual Input Handling
    
    func handleCountInput() {
        guard let value = Int(alertState.countInputText), value > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            alertState.countInputText = ""
            return
        }
        
        Task {
            if Calendar.current.isDateInToday(date) {
                let habitId = habit.uuid.uuidString
                let currentProgress = timerService.getCurrentProgress(for: habitId)
                let newProgress = currentProgress + value
                
                timerService.setProgress(newProgress, for: habitId)
                await saveProgressToDatabase(newProgress)
            } else {
                await addProgressToDatabase(value)
            }
            
            alertState.successFeedbackTrigger.toggle()
            alertState.countInputText = ""
        }
    }
    
    // ✅ НОВЫЙ метод для кастомного time input
    func handleCustomTimeInput(hours: Int, minutes: Int) {
        let totalSeconds = (hours * 3600) + (minutes * 60)
        
        guard totalSeconds > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            return
        }
        
        Task {
            if Calendar.current.isDateInToday(date) {
                let habitId = habit.uuid.uuidString
                let currentProgress = timerService.getCurrentProgress(for: habitId)
                let newProgress = currentProgress + totalSeconds
                
                timerService.setProgress(newProgress, for: habitId)
                await saveProgressToDatabase(newProgress)
            } else {
                await addProgressToDatabase(totalSeconds)
            }
            
            alertState.successFeedbackTrigger.toggle()
        }
    }
    
    // MARK: - Delete Operations
    
    func deleteHabit() {
        do {
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
        // Saves are handled in async methods
    }
    
    func cleanup() {
        widgetActionTask?.cancel()
        widgetActionTask = nil
        NotificationCenter.default.removeObserver(self)
        onHabitDeleted = nil
    }
}

// MARK: - Async Extensions

extension HabitDetailViewModel {
    
    func incrementProgressAsync() async throws {
        let value = habit.type == .count ? 1 : 60
        
        if Calendar.current.isDateInToday(date) {
            let habitId = habit.uuid.uuidString
            let currentProgress = timerService.getCurrentProgress(for: habitId)
            let newProgress = currentProgress + value
            
            timerService.setProgress(newProgress, for: habitId)
            await saveProgressToDatabase(newProgress)
        } else {
            await addProgressToDatabase(value)
        }
    }
    
    func decrementProgressAsync() async throws {
        let value = habit.type == .count ? 1 : 60
        
        if Calendar.current.isDateInToday(date) {
            let habitId = habit.uuid.uuidString
            let currentProgress = timerService.getCurrentProgress(for: habitId)
            let newProgress = max(0, currentProgress - value)
            
            timerService.setProgress(newProgress, for: habitId)
            await saveProgressToDatabase(newProgress)
        } else {
            let currentDb = habit.progressForDate(date)
            let newProgress = max(0, currentDb - value)
            await saveProgressToDatabase(newProgress)
        }
    }
    
    func completeHabitAsync() async throws {
        if Calendar.current.isDateInToday(date) {
            let habitId = habit.uuid.uuidString
            timerService.setProgress(habit.goal, for: habitId)
        }
        
        await saveProgressToDatabase(habit.goal)
        
        if habit.type == .time && Calendar.current.isDateInToday(date) {
            await liveActivityManager.endActivity(for: habit.uuid.uuidString)
            await updateLiveActivityState()
        }
    }
    
    func resetProgressAsync() async throws {
        if Calendar.current.isDateInToday(date) {
            let habitId = habit.uuid.uuidString
            timerService.setProgress(0, for: habitId)
        }
        
        await saveProgressToDatabase(0)
    }
    
    // MARK: - Database Helpers
    
    private func addProgressToDatabase(_ value: Int) async {
        let completion = HabitCompletion(
            date: date,
            value: value,
            habit: habit
        )
        
        await MainActor.run {
            modelContext.insert(completion)
            
            if Calendar.current.isDateInToday(date) {
                try? modelContext.save()
            } else {
                Task {
                    try await Task.sleep(nanoseconds: 50_000_000) // 50ms
                    try? modelContext.save()
                }
            }
        }
    }
    
    func saveProgressToDatabase(_ progress: Int) async {
        await MainActor.run {
            let existingCompletions = habit.completions?.filter {
                Calendar.current.isDate($0.date, inSameDayAs: date)
            } ?? []
            
            for completion in existingCompletions {
                modelContext.delete(completion)
            }
            
            if progress > 0 {
                let completion = HabitCompletion(
                    date: date,
                    value: progress,
                    habit: habit
                )
                modelContext.insert(completion)
            }
            
            if Calendar.current.isDateInToday(date) {
                try? modelContext.save()
            } else {
                Task {
                    try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    try? modelContext.save()
                }
            }
        }
    }
}
