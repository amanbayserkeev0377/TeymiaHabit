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
    private let liveActivityManager = HabitLiveActivityManager()
    
    // MARK: - UI State
    var alertState = AlertState()
    var onHabitDeleted: (() -> Void)?
    
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
        // Only for time habits on today
        guard habit.type == .time && isToday else { return }
        
        Task {
            await liveActivityManager.restoreActiveActivityIfNeeded()
            liveActivityManager.startListeningForWidgetActions()
        }
        
        // Listen for widget actions
        NotificationCenter.default.addObserver(
            forName: .widgetActionReceived,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                await self?.handleWidgetAction(notification)
            }
        }
    }
    
    private func handleWidgetAction(_ notification: Notification) async {
        guard let actionNotification = notification.object as? WidgetActionNotification,
              actionNotification.habitId == habit.uuid.uuidString else { return }
        
        switch actionNotification.action {
        case .toggleTimer:
            toggleTimer()
        case .complete:
            completeHabit()
        case .addTime:
            // Add 1 minute
            do {
                try progressService.addProgress(60, for: habit, date: date, modelContext: modelContext)
            } catch {
                print("❌ Add time failed: \(error)")
            }
        }
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
    
    private func updateLiveActivity() async {
        guard habit.type == .time && isToday else { return }
        
        let habitId = habit.uuid.uuidString
        
        if isTimerRunning {
            // Get the actual timer start time from TimerService
            let timerStartTime = timerService.getTimerStartTime(for: habitId) ?? Date()
            
            await liveActivityManager.startActivity(
                for: habit,
                currentProgress: currentProgress,
                timerStartTime: timerStartTime
            )
            print("🎬 Live Activity started for \(habit.title)")
        } else {
            await liveActivityManager.updateActivity(
                currentProgress: currentProgress,
                isTimerRunning: false,
                timerStartTime: nil
            )
            print("⏸️ Live Activity updated - timer stopped")
        }
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
            
            // End Live Activity when completed
            if habit.type == .time && isToday {
                Task {
                    await liveActivityManager.endCurrentActivity()
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
        // Remove notification observer
        NotificationCenter.default.removeObserver(self)
        onHabitDeleted = nil
    }
}
