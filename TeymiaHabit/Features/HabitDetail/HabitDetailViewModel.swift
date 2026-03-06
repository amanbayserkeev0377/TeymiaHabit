import SwiftUI
import SwiftData

@Observable @MainActor
final class HabitDetailViewModel {
    // MARK: - Constants
    private enum Constants {
        static let incrementTimeValue = 60
        static let decrementTimeValue = -60
        static let liveActivitySyncInterval = 10
    }
    
    // MARK: - Dependencies
    private let habit: Habit
    private let modelContext: ModelContext
    private let timerService = TimerService.shared
    private let liveActivityManager = HabitLiveActivityManager.shared
    private let cachedHabitId: String
    
    // MARK: - State
    private var currentDisplayedDate: Date
    private var hasPendingChanges: Bool = false
    private var lastSavedProgress: Int = 0
    private(set) var uiProgress: Int = 0
    private var progressCache: [String: Int] = [:]
    private var baseProgressWhenTimerStarted: Int?
    private var hasPlayedTimerCompletionSound = false
    private var hasShownGoalNotification = false
    private var saveWorkItem: DispatchWorkItem?
    private let backgroundQueue = DispatchQueue(label: "habit.save.background", qos: .userInitiated)
    
    private var isCloudKitEnabled: Bool {
        return !modelContext.container.configurations.isEmpty
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // MARK: - UI State
    var alertState = AlertState()
    var onHabitDeleted: (() -> Void)?
    var isSkipped: Bool {
        habit.isSkipped(on: currentDisplayedDate)
    }
    var onDataSaved: (() -> Void)?
    
    // MARK: - Computed Properties
    var hasActiveLiveActivity: Bool {
        liveActivityManager.hasActiveActivity(for: cachedHabitId)
    }
    
    var currentProgress: Int {
        _ = timerService.updateTrigger
        
        if isTimeHabitToday && timerService.isTimerRunning(for: cachedHabitId) {
            if let liveProgress = timerService.getLiveProgress(for: cachedHabitId) {
                return liveProgress
            }
        }
        return uiProgress
    }
    
    func checkGoalProgress(_ current: Int) {
        guard current >= habit.goal,
              !hasPlayedTimerCompletionSound else { return }
        
        hasPlayedTimerCompletionSound = true
        
        SoundManager.shared.playCompletionSound()
        HapticManager.shared.play(.success)
        
        if !hasShownGoalNotification {
            hasShownGoalNotification = true
            Task { await checkGoalAchievement() }
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
        timerService.isTimerRunning(for: cachedHabitId)
    }
    
    var canStartTimer: Bool {
        timerService.canStartNewTimer || isTimerRunning
    }
    
    var timerStartTime: Date? {
        timerService.getTimerStartTime(for: cachedHabitId)
    }
    
    var habitId: String {
        cachedHabitId
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(currentDisplayedDate)
    }
    
    private var isTimeHabitToday: Bool {
        habit.type == .time && isToday
    }
    
    // MARK: - Initialization
    init(habit: Habit, initialDate: Date, modelContext: ModelContext) {
        self.habit = habit
        self.currentDisplayedDate = initialDate
        self.modelContext = modelContext
        self.cachedHabitId = habit.uuid.uuidString
        
        let initialProgress = habit.progressForDate(initialDate)
        progressCache[dateToKey(initialDate)] = initialProgress
        
        self.uiProgress = initialProgress
        self.lastSavedProgress = initialProgress
        
        setupStableSubscriptions()
        
        if isTimeHabitToday && timerService.isTimerRunning(for: cachedHabitId) {
            baseProgressWhenTimerStarted = initialProgress
        }
    }
    
    // MARK: - Date Management
    func updateDisplayedDate(_ newDate: Date) {
        currentDisplayedDate = newDate
        hasShownGoalNotification = false
        hasPlayedTimerCompletionSound = false
        
        let dateKey = dateToKey(newDate)
        if progressCache[dateKey] == nil {
            let progress = habit.progressForDate(newDate)
            progressCache[dateKey] = progress
        }
        
        let newProgress = habit.progressForDate(newDate)
        uiProgress = newProgress
        lastSavedProgress = newProgress
    }
    
    // MARK: - Progress Management
    // MARK: - Internal Update Logic
        func updateProgress(to newProgress: Int) {
            stopTimerAndSaveLiveProgressIfNeeded()
            uiProgress = newProgress
            hasPendingChanges = true
            scheduleBackgroundSave()
            updateLiveActivityAfterManualChange()
        }
    
    func incrementProgress() {
        let wasCompleted = isAlreadyCompleted
        let incrementValue = habit.type == .count ? 1 : Constants.incrementTimeValue
        
        stopTimerAndSaveLiveProgressIfNeeded()
        
        uiProgress = min(uiProgress + incrementValue, habit.type == .count ? 999999 : 86400)
        hasPendingChanges = true
        scheduleBackgroundSave()
        updateLiveActivityAfterManualChange()
        
        if !wasCompleted && isAlreadyCompleted {
            SoundManager.shared.playCompletionSound()
        }
    }
    
    func decrementProgress() {
        guard uiProgress > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            return
        }
        
        let decrementValue = habit.type == .count ? 1 : Constants.incrementTimeValue
        stopTimerAndSaveLiveProgressIfNeeded()
        
        uiProgress = max(uiProgress - decrementValue, 0)
        hasPendingChanges = true
        scheduleBackgroundSave()
        updateLiveActivityAfterManualChange()
    }
    
    func completeHabit() {
        guard !isAlreadyCompleted else { return }
        if isSkipped { habit.unskipDate(currentDisplayedDate, modelContext: modelContext) }
        
        if isTimeHabitToday && isTimerRunning {
            stopTimerAndEndActivity()
        }
        
        uiProgress = habit.goal
        hasPendingChanges = false
        performImmediateSave()
        alertState.successFeedbackTrigger.toggle()
        SoundManager.shared.playCompletionSound()
        endLiveActivityIfNeeded()
    }
    
    func resetProgress() {
        if isTimeHabitToday && isTimerRunning {
            stopTimerAndEndActivity()
        }
        uiProgress = 0
        hasPendingChanges = false
        performImmediateSave()
        updateLiveActivityIfActive(progress: 0, isTimerRunning: false)
    }
    
    // MARK: - Timer Management
    func toggleTimer() {
        guard isTimeHabitToday else { return }
        isTimerRunning ? stopTimer() : startTimer()
    }
    
    private func startTimer() {
        guard timerService.canStartNewTimer else {
            alertState.errorFeedbackTrigger.toggle()
            return
        }
        
        let baseProgress = uiProgress
        baseProgressWhenTimerStarted = baseProgress
        hasShownGoalNotification = false
        hasPlayedTimerCompletionSound = false
        
        let success = timerService.startTimer(for: cachedHabitId, baseProgress: baseProgress)
        
        if success {
            Task {
                await startLiveActivity()
            }
        } else {
            alertState.errorFeedbackTrigger.toggle()
        }
    }
    
    private func stopTimer() {
        if let finalProgress = timerService.stopTimer(for: cachedHabitId) {
            uiProgress = finalProgress
            hasPendingChanges = true
            scheduleBackgroundSave()
            
            Task {
                await liveActivityManager.updateActivity(
                    for: cachedHabitId,
                    currentProgress: finalProgress,
                    isTimerRunning: false,
                    timerStartTime: nil
                )
            }
        }
        baseProgressWhenTimerStarted = nil
    }
    
    // MARK: - Live Activities
    private func startLiveActivity() async {
        guard let startTime = timerStartTime,
              let baseProgress = baseProgressWhenTimerStarted else { return }
        
        await liveActivityManager.startActivity(
            for: habit,
            currentProgress: baseProgress,
            timerStartTime: startTime
        )
    }
    
    private func updateLiveActivityAfterManualChange() {
        updateLiveActivityIfActive(progress: uiProgress, isTimerRunning: false)
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
        guard hasActiveLiveActivity else { return }
        Task { await liveActivityManager.endActivity(for: cachedHabitId) }
    }
    
    // MARK: - Notifications
    private func checkGoalAchievement() async {
        await NotificationManager.shared.sendGoalAchievedNotification(for: habit)
    }
    
    // MARK: - App Lifecycle
    @ObservationIgnored
    nonisolated(unsafe) private var appForegroundObserver: Any?

    private func setupStableSubscriptions() {
        appForegroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleAppWillEnterForeground()
            }
        }
    }

    deinit {
        if let observer = appForegroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func handleAppWillEnterForeground() async {
        try? await Task.sleep(nanoseconds: 100_000_000)
        refresh()
    }
    
    func refresh() {
        let freshProgress = habit.progressForDate(currentDisplayedDate)
        uiProgress = freshProgress
        lastSavedProgress = freshProgress
        
        if isTimeHabitToday && timerService.isTimerRunning(for: cachedHabitId) {
             if let live = timerService.getLiveProgress(for: cachedHabitId) {
                 uiProgress = live
             }
        }
    }

    private func scheduleBackgroundSave() {
        saveWorkItem?.cancel()
        
        guard habit.modelContext != nil else { return }
        
        let progressToSave = uiProgress
        let dateToSave = currentDisplayedDate
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.performBackgroundSave(progress: progressToSave, date: dateToSave)
        }
        
        saveWorkItem = workItem
        let delay = isCloudKitEnabled ? 1.2 : 0.5
        backgroundQueue.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
    
    private func performBackgroundSave(progress: Int, date: Date) {
        guard habit.modelContext != nil else { return }
        guard progress != lastSavedProgress else { return }
        let container = modelContext.container
        let habitUUID = habit.uuid
        
        Task.detached { [weak self, habitUUID] in
            guard let self else { return }
            
            let backgroundContext = ModelContext(container)
            let descriptor = FetchDescriptor<Habit>(predicate: #Predicate<Habit> { h in h.uuid == habitUUID })
            
            do {
                if let bgHabit = try backgroundContext.fetch(descriptor).first {
                    bgHabit.updateProgress(to: progress, for: date, modelContext: backgroundContext)
                    try backgroundContext.save()
                    
                    await MainActor.run {
                        self.lastSavedProgress = progress
                        self.hasPendingChanges = false
                        WidgetUpdateService.shared.reloadWidgetsAfterDataChange()
                        self.onDataSaved?()
                    }
                }
            } catch {
                print("Failed to save background progress: \(error)")
            }
        }
    }
    
    private func performImmediateSave() {
        saveWorkItem?.cancel()
        habit.updateProgress(to: uiProgress, for: currentDisplayedDate, modelContext: modelContext)
        lastSavedProgress = uiProgress
        hasPendingChanges = false
        WidgetUpdateService.shared.reloadWidgetsAfterDataChange()
    }
    
    // MARK: - Helpers
    private func stopTimerAndSaveLiveProgressIfNeeded() {
        if isTimerRunning { stopTimer() }
    }
    
    private func stopTimerAndEndActivity() {
        _ = timerService.stopTimer(for: cachedHabitId)
        endLiveActivityIfNeeded()
    }
    
    private func dateToKey(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }
    
    func prepareForDeletion() {
        saveWorkItem?.cancel()
        hasPendingChanges = false
        
        if let observer = appForegroundObserver {
            NotificationCenter.default.removeObserver(observer)
            appForegroundObserver = nil
        }
    }
    
    // MARK: - Skip Actions
    func toggleSkip() {
        isSkipped ? unskipHabit() : skipHabit()
    }

    func skipHabit() {
        habit.skipDate(currentDisplayedDate, modelContext: modelContext)
        alertState.successFeedbackTrigger = true
        WidgetUpdateService.shared.reloadWidgets()
    }

    func unskipHabit() {
        habit.unskipDate(currentDisplayedDate, modelContext: modelContext)
        alertState.successFeedbackTrigger = true
        WidgetUpdateService.shared.reloadWidgets()
    }
}
