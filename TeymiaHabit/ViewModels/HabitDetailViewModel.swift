import SwiftUI
import SwiftData
import UserNotifications

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
    private var updateTimer: Timer?
    private var hasPendingChanges: Bool = false
    private var lastSavedProgress: Int = 0
    private(set) var uiProgress: Int = 0
    private(set) var localUpdateTrigger: Int = 0
    private var progressCache: [String: Int] = [:]
    private var baseProgressWhenTimerStarted: Int?
    private var hasPlayedTimerCompletionSound = false
    private var hasShownGoalNotification = false
    private var saveWorkItem: DispatchWorkItem?
    private let backgroundQueue = DispatchQueue(label: "habit.save.background", qos: .userInitiated)
    private var isCloudKitEnabled: Bool {
        return !modelContext.container.configurations.isEmpty
    }
    
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
        if isTimeHabitToday && timerService.isTimerRunning(for: cachedHabitId) {
            _ = localUpdateTrigger
            
            if let liveProgress = timerService.getLiveProgress(for: cachedHabitId) {
                let baseProgress = habit.progressForDate(currentDisplayedDate)
                if !hasPlayedTimerCompletionSound &&
                   baseProgress < habit.goal &&
                   liveProgress >= habit.goal {
                    
                    hasPlayedTimerCompletionSound = true
                    
                    DispatchQueue.main.async {
                        SoundManager.shared.playCompletionSound()
                        HapticManager.shared.play(.success)
                    }
                }
                
                return liveProgress
            }
        }
        
        return uiProgress
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
            baseProgressWhenTimerStarted = habit.progressForDate(initialDate)
            startLocalUpdates()
        }
    }
    
    // MARK: - Date Management
    
    func updateDisplayedDate(_ newDate: Date) {
        currentDisplayedDate = newDate
        hasShownGoalNotification = false
        
        let dateKey = dateToKey(newDate)
        if progressCache[dateKey] == nil {
            let progress = habit.progressForDate(newDate)
            progressCache[dateKey] = progress
        }
        
        let newProgress = habit.progressForDate(newDate)
        uiProgress = newProgress
        lastSavedProgress = newProgress
        
        if Calendar.current.isDateInToday(newDate) && habit.type == .time {
            if timerService.isTimerRunning(for: cachedHabitId) && updateTimer == nil {
                startLocalUpdates()
            }
        } else {
            stopLocalUpdates()
        }
        
        localUpdateTrigger += 1
    }
    
    // MARK: - Progress Management
    
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
    
    func handleCustomCountInput(count: Int) {
        stopTimerAndSaveLiveProgressIfNeeded()
        uiProgress = min(uiProgress + count, 999999)
        hasPendingChanges = true
        scheduleBackgroundSave()
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
        uiProgress = min(uiProgress + totalSeconds, 86400)
        hasPendingChanges = true
        scheduleBackgroundSave()
        alertState.successFeedbackTrigger.toggle()
        updateLiveActivityAfterManualChange()
    }
    
    func completeHabit() {
        guard !isAlreadyCompleted else { return }
        
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
        
        let baseProgress = currentProgress
        baseProgressWhenTimerStarted = baseProgress
        hasShownGoalNotification = false
        hasPlayedTimerCompletionSound = false
        
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
        } else {
            alertState.errorFeedbackTrigger.toggle()
        }
    }
    
    private func stopTimer() {
        stopLocalUpdates()
        
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
        hasShownGoalNotification = false
    }
    
    private func startLocalUpdates() {
        guard isTimeHabitToday else { return }
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.handleTimerTick()
            }
        }
    }
    
    private func handleTimerTick() async {
        guard timerService.isTimerRunning(for: cachedHabitId) else {
            stopLocalUpdates()
            return
        }
        
        /// Show goal notification without stopping timer
        if let baseProgress = baseProgressWhenTimerStarted,
           baseProgress < habit.goal &&
           currentProgress >= habit.goal &&
           !hasShownGoalNotification {
            
            await showGoalAchievedNotification()
            hasShownGoalNotification = true
        }
        
        localUpdateTrigger += 1
        await syncLiveActivityIfNeeded()
    }
    
    private func stopLocalUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
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
            currentProgress: baseProgress,
            timerStartTime: startTime
        )
    }
    
    private func syncLiveActivityIfNeeded() async {
        guard hasActiveLiveActivity,
              let startTime = timerStartTime,
              let baseProgress = baseProgressWhenTimerStarted else { return }
        
        let elapsed = Int(Date().timeIntervalSince(startTime))
        
        if elapsed % Constants.liveActivitySyncInterval == 0 {
            await liveActivityManager.updateActivity(
                for: cachedHabitId,
                currentProgress: baseProgress,
                isTimerRunning: true,
                timerStartTime: startTime
            )
        }
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
    
    // MARK: - Notifications
    
    private func showGoalAchievedNotification() async {
        alertState.successFeedbackTrigger.toggle()
        await sendGoalAchievedNotification()
    }
    
    private func sendGoalAchievedNotification() async {
        guard NotificationManager.shared.notificationsEnabled,
              await NotificationManager.shared.ensureAuthorization() else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "goal_achieved_title".localized
        content.body = "goal_achieved_body".localized(with: habit.title)
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "goal-achieved-\(cachedHabitId)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - App Lifecycle
    
    private func setupStableSubscriptions() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.handleAppWillEnterForeground()
            }
        }
    }
    
    private func handleAppWillEnterForeground() async {
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        let dateKey = dateToKey(currentDisplayedDate)
        progressCache.removeValue(forKey: dateKey)
        
        let freshProgress = habit.progressForDate(currentDisplayedDate)
        progressCache[dateKey] = freshProgress
        
        uiProgress = freshProgress
        lastSavedProgress = freshProgress
        
        if isTimeHabitToday && timerService.isTimerRunning(for: cachedHabitId) {
            if !hasActiveLiveActivity {
                if let finalProgress = timerService.stopTimer(for: cachedHabitId) {
                    uiProgress = finalProgress
                    hasPendingChanges = true
                    scheduleBackgroundSave()
                }
                stopLocalUpdates()
                baseProgressWhenTimerStarted = nil
            }
        }
        
        localUpdateTrigger += 1
    }
    
    // MARK: - Helper Methods
    
    private func dateToKey(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }
    
    private func scheduleBackgroundSave() {
        saveWorkItem?.cancel()
        
        let progressToSave = uiProgress
        let workItem = DispatchWorkItem { [weak self] in
            self?.performBackgroundSave(progress: progressToSave)
        }
        
        saveWorkItem = workItem
        let delay = isCloudKitEnabled ? 1.2 : 0.5
        backgroundQueue.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
    
    private func performBackgroundSave(progress: Int) {
        guard progress != lastSavedProgress else { return }
        
        let container = modelContext.container
        let habitUUID = habit.uuid
        let dateToSave = currentDisplayedDate
        
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            let backgroundContext = ModelContext(container)
            
            let descriptor = FetchDescriptor<Habit>(
                predicate: #Predicate<Habit> { h in h.uuid == habitUUID }
            )
            
            guard let bgHabit = try? backgroundContext.fetch(descriptor).first else { return }
            
            bgHabit.updateProgress(to: progress, for: dateToSave, modelContext: backgroundContext)
            
            await MainActor.run {
                self.lastSavedProgress = progress
                self.hasPendingChanges = false
                
                WidgetUpdateService.shared.reloadWidgetsAfterDataChange()
            }
        }
    }
    
    private func performImmediateSave() {
        saveWorkItem?.cancel()
        
        let progress = uiProgress
        
        Task {
            habit.updateProgress(to: progress, for: currentDisplayedDate, modelContext: modelContext)
            lastSavedProgress = progress
            hasPendingChanges = false
            WidgetUpdateService.shared.reloadWidgetsAfterDataChange()
        }
    }
        
    private func stopTimerAndSaveLiveProgressIfNeeded() {
        guard isTimeHabitToday && isTimerRunning else { return }
        
        let liveProgress = timerService.getLiveProgress(for: cachedHabitId) ?? currentProgress
        stopLocalUpdates()
        _ = timerService.stopTimer(for: cachedHabitId)
        uiProgress = liveProgress
        hasPendingChanges = true
        scheduleBackgroundSave()
        baseProgressWhenTimerStarted = nil
    }
    
    private func stopTimerAndEndActivity() {
        stopLocalUpdates()
        _ = timerService.stopTimer(for: cachedHabitId)
        baseProgressWhenTimerStarted = nil
    }
    
    // MARK: - Cleanup
    
    func deleteHabit() {
        NotificationCenter.default.removeObserver(self, name: .widgetActionReceived, object: nil)
        endLiveActivityIfNeeded()
        cleanup()
        modelContext.delete(habit)
        try? modelContext.save()
    }
    
    func syncWithTimerService() {
        guard isTimeHabitToday, timerService.isTimerRunning(for: cachedHabitId) else { return }
        if let liveProgress = timerService.getLiveProgress(for: cachedHabitId) {
            uiProgress = liveProgress
            hasPendingChanges = true
            scheduleBackgroundSave()
        }
    }
    
    func cleanup() {
        saveWorkItem?.cancel()
        if hasPendingChanges && uiProgress != lastSavedProgress {
            performImmediateSave()
        }
        
        stopLocalUpdates()
        NotificationCenter.default.removeObserver(self)
        onHabitDeleted = nil
    }
}
