import SwiftUI
import SwiftData

@Observable @MainActor
final class HabitDetailViewModel {
    // MARK: - Dependencies
    private let habit: Habit
    private let date: Date
    private let modelContext: ModelContext
    
    // MARK: - State
    private(set) var currentProgress: Int = 0
    private var timerStartTime: Date?
    private var timer: Timer?
    
    // MARK: - Debounced save
    private var saveWorkItem: DispatchWorkItem?
    private let saveDebounceDelay: TimeInterval = 0.3
    
    // MARK: - UI State
    var alertState = AlertState()
    var onHabitDeleted: (() -> Void)?
    
    // MARK: - Constants
    private enum Limits {
        static let maxCount = 999999
        static let maxTimeSeconds = 86400 // 24 hours
    }
    
    // MARK: - Computed Properties
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
        timer != nil && timerStartTime != nil
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    // MARK: - Initialization
    init(habit: Habit, date: Date, modelContext: ModelContext) {
        self.habit = habit
        self.date = date
        self.modelContext = modelContext
        
        // Load current progress from SwiftData
        self.currentProgress = habit.progressForDate(date)
        
        // NEW: Live Activity setup
            setupLiveActivityListener()
        
        Task {
                await liveActivityManager.restoreActiveActivityIfNeeded()
                await updateLiveActivityState()
                liveActivityManager.startListeningForWidgetActions()
            }
        
        // Restore timer only for today and time habits
        if isToday && habit.type == .time {
            restoreTimerStateIfNeeded()
        }
    }
    
    // MARK: - Progress Operations
    
    func incrementProgress() {
        guard !isAlreadyCompleted else {
            alertState.errorFeedbackTrigger.toggle()
            return
        }
        
        if habit.type == .count {
            updateProgress(min(currentProgress + 1, Limits.maxCount))
        } else {
            stopTimerIfRunning()
            updateProgress(min(currentProgress + 60, Limits.maxTimeSeconds))
        }
    }
    
    func decrementProgress() {
        guard currentProgress > 0 else { return }
        
        if habit.type == .count {
            updateProgress(max(currentProgress - 1, 0))
        } else {
            stopTimerIfRunning()
            updateProgress(max(currentProgress - 60, 0))
        }
    }
    
    func completeHabit() {
        guard !isAlreadyCompleted else { return }
        
        stopTimerIfRunning()
        updateProgress(habit.goal)
        alertState.successFeedbackTrigger.toggle()
        
        // NEW: End Live Activity when completed
        Task {
            await liveActivityManager.endCurrentActivity()
            await updateLiveActivityState()
        }
    }
    
    func resetProgress() {
        stopTimerIfRunning()
        updateProgress(0)
    }
    
    // MARK: - Timer Management (simple & reliable)
    
    func toggleTimer() {
        guard habit.type == .time && isToday else { return }
        
        if isTimerRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        timerStartTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startTime = self.timerStartTime else { return }
                
                let elapsed = Int(Date().timeIntervalSince(startTime))
                let baseProgress = self.habit.progressForDate(self.date)
                self.currentProgress = min(baseProgress + elapsed, Limits.maxTimeSeconds)
                
                // Update Live Activity every 5 seconds to save battery
                if elapsed % 5 == 0 {
                    await self.updateLiveActivityIfNeeded()
                }
            }
        }
        
        let timerKey = "timer_\(habit.uuid.uuidString)"
        UserDefaults.standard.set(Date(), forKey: timerKey)
        
        // NEW: Start Live Activity automatically for time habits
        if habit.type == .time && isToday {
            Task {
                await startLiveActivity()
            }
        }
    }
    
    private func stopTimer() {
        guard let startTime = timerStartTime else { return }
        
        let elapsed = Int(Date().timeIntervalSince(startTime))
        let baseProgress = habit.progressForDate(date)
        updateProgress(min(baseProgress + elapsed, Limits.maxTimeSeconds))
        
        timer?.invalidate()
        timer = nil
        timerStartTime = nil
        
        let timerKey = "timer_\(habit.uuid.uuidString)"
        UserDefaults.standard.removeObject(forKey: timerKey)
        
        // NEW: Update Live Activity
        Task {
            await updateLiveActivityIfNeeded()
        }
    }
    
    private func stopTimerIfRunning() {
        if isTimerRunning {
            stopTimer()
        }
    }
    
    private func restoreTimerStateIfNeeded() {
        let timerKey = "timer_\(habit.uuid.uuidString)"
        if let savedStartTime = UserDefaults.standard.object(forKey: timerKey) as? Date,
           Calendar.current.isDate(savedStartTime, inSameDayAs: Date()) {
            
            timerStartTime = savedStartTime
            startTimer()
        }
    }
    
    // MARK: - Data Management
    
    private func updateProgress(_ newValue: Int) {
        guard newValue != currentProgress else { return }
        
        currentProgress = newValue
        debouncedSave()
    }
    
    private func debouncedSave() {
        saveWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                self?.saveToDatabase()
            }
        }
        
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + saveDebounceDelay, execute: workItem)
    }
    
    private func saveToDatabase() {
        do {
            // Remove existing completions for this date
            if let existingCompletions = habit.completions?.filter({
                Calendar.current.isDate($0.date, inSameDayAs: date)
            }) {
                for completion in existingCompletions {
                    modelContext.delete(completion)
                }
            }
            
            // Add new completion if there's progress
            if currentProgress > 0 {
                let completion = HabitCompletion(
                    date: date,
                    value: currentProgress,
                    habit: habit
                )
                modelContext.insert(completion)
            }
            
            // SwiftData automatically syncs with iCloud!
            try modelContext.save()
            
        } catch {
            print("❌ Save failed: \(error)")
        }
    }
    
    // MARK: - User Input Handling
    
    func handleCountInput() {
        guard let value = Int(alertState.countInputText), value > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            alertState.countInputText = ""
            return
        }
        
        updateProgress(min(currentProgress + value, Limits.maxCount))
        alertState.successFeedbackTrigger.toggle()
        alertState.countInputText = ""
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
        
        stopTimerIfRunning()
        updateProgress(min(currentProgress + totalSeconds, Limits.maxTimeSeconds))
        
        alertState.successFeedbackTrigger.toggle()
        clearTimeInputs()
    }
    
    private func clearTimeInputs() {
        alertState.hoursInputText = ""
        alertState.minutesInputText = ""
    }
    
    // MARK: - Delete Operations
    
    func deleteHabit() {
        do {
            cleanup()
            modelContext.delete(habit)
            try modelContext.save()
        } catch {
            print("❌ Delete failed: \(error)")
        }
    }
    
    // MARK: - Cleanup
    
    func saveIfNeeded() {
        saveWorkItem?.cancel()
        saveToDatabase() // Immediate save on exit
    }
    
    func cleanup() {
        saveWorkItem?.cancel()
        timer?.invalidate()
        timer = nil
        
        if let startTime = timerStartTime {
            let timerKey = "timer_\(habit.uuid.uuidString)"
            UserDefaults.standard.set(startTime, forKey: timerKey)
        }
        
        // NEW: Keep Live Activity running if timer is active, end if not
        Task {
            if !isTimerRunning {
                await liveActivityManager.endCurrentActivity()
            }
        }
        
        saveIfNeeded()
        onHabitDeleted = nil
        
        // NEW: Remove notification observers
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - LiveActivities
    
    private let liveActivityManager = HabitLiveActivityManager()
    var hasActiveLiveActivity: Bool = false

    private func setupLiveActivityListener() {
        let habitId = habit.uuid.uuidString
        
        NotificationCenter.default.addObserver(
            forName: .widgetActionReceived,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let action = notification.object as? WidgetActionNotification,
                  action.habitId == habitId else { return }
            
            Task { @MainActor in
                await self.handleWidgetAction(action.action)
            }
        }
    }
    
    private func handleWidgetAction(_ action: WidgetAction) async {
        switch action {
        case .toggleTimer:
            if isTimerRunning {
                stopTimer()
            } else {
                startTimer()
            }
            
        case .complete:
            completeHabit()
            
        case .addTime:
            // Add 1 minute
            updateProgress(min(currentProgress + 60, Limits.maxTimeSeconds))
        }
        
        await updateLiveActivityState()
    }

    private func updateLiveActivityState() async {
        hasActiveLiveActivity = liveActivityManager.hasActiveActivity
    }
    
    private func startLiveActivity() async {
        guard let startTime = timerStartTime else { return }
        
        await liveActivityManager.startActivity(
            for: habit,
            currentProgress: currentProgress,
            timerStartTime: startTime
        )
        
        await updateLiveActivityState()
    }

    private func updateLiveActivityIfNeeded() async {
        guard hasActiveLiveActivity else { return }
        
        await liveActivityManager.updateActivity(
            currentProgress: currentProgress,
            isTimerRunning: isTimerRunning,
            timerStartTime: timerStartTime
        )
    }

    func startLiveActivityManually() async {
        guard habit.type == .time, isToday else { return }
        
        if !isTimerRunning {
            startTimer()
        } else {
            await startLiveActivity()
        }
    }

    func endLiveActivityManually() async {
        await liveActivityManager.endCurrentActivity()
        await updateLiveActivityState()
    }

}
