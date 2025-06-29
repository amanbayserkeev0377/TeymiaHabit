import SwiftUI
import SwiftData

@Observable @MainActor
final class HabitDetailViewModel {
    // MARK: - Только необходимые зависимости
    private let habit: Habit
    private let date: Date
    private let modelContext: ModelContext
    
    // MARK: - Локальное состояние
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
    
    var formattedProgress: String {
        habit.type == .count ?
            "\(currentProgress)" :
        currentProgress.formattedAsTime()
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
    
    // MARK: - Простая инициализация
    init(habit: Habit, date: Date, modelContext: ModelContext) {
        self.habit = habit
        self.date = date
        self.modelContext = modelContext
        
        // Просто загружаем прогресс из SwiftData
        self.currentProgress = habit.progressForDate(date)
        
        // Восстанавливаем таймер только для сегодняшнего дня
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
    }
    
    func resetProgress() {
        stopTimerIfRunning()
        updateProgress(0)
    }
    
    // MARK: - Timer Management
    
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
            Task { @MainActor [weak self] in
                // Просто обновляем UI каждую секунду
            }
        }
        
        // Сохраняем время старта для восстановления при перезапуске
        let timerKey = "timer_\(habit.uuid.uuidString)"
        UserDefaults.standard.set(Date(), forKey: timerKey)
    }
    
    private func stopTimer() {
        guard let startTime = timerStartTime else { return }
        
        // Добавляем прошедшее время к прогрессу
        let elapsed = Int(Date().timeIntervalSince(startTime))
        updateProgress(min(currentProgress + elapsed, Limits.maxTimeSeconds))
        
        timer?.invalidate()
        timer = nil
        timerStartTime = nil
        
        // Убираем сохраненное время
        let timerKey = "timer_\(habit.uuid.uuidString)"
        UserDefaults.standard.removeObject(forKey: timerKey)
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
            // Удаляем старые записи для этой даты
            let existingCompletions = habit.completions?.filter {
                Calendar.current.isDate($0.date, inSameDayAs: date)
            } ?? []
            
            for completion in existingCompletions {
                modelContext.delete(completion)
            }
            
            // Добавляем новую запись если есть прогресс
            if currentProgress > 0 {
                let completion = HabitCompletion(
                    date: date,
                    value: currentProgress,
                    habit: habit
                )
                modelContext.insert(completion)
            }
            
            // SwiftData автоматически синхронизируется с iCloud!
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
        saveToDatabase() // Немедленное сохранение при выходе
    }
    
    func cleanup() {
        saveWorkItem?.cancel()
        timer?.invalidate()
        timer = nil
        
        // Сохраняем состояние таймера если активен
        if let startTime = timerStartTime {
            let timerKey = "timer_\(habit.uuid.uuidString)"
            UserDefaults.standard.set(startTime, forKey: timerKey)
        }
        
        saveIfNeeded()
        onHabitDeleted = nil
    }
}
