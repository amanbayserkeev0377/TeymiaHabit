import Foundation
import SwiftData
import SwiftUI

@Observable @MainActor
final class HabitsViewModel {
    private let modelContext: ModelContext
    private let habitService: HabitService
    private let soundManager: SoundManager
    private let timerService: TimerService
    private(set) var widgetService: WidgetService
    private(set) var notificationManager: NotificationManager
    
    var allBaseHabits: [Habit] = []
    var temporaryProgress: [UUID: Int] = [:]
    
    init(
        modelContext: ModelContext,
        habitService: HabitService,
        notificationManager: NotificationManager,
        soundManager: SoundManager,
        widgetService: WidgetService,
        timerService: TimerService
    ) {
        self.modelContext = modelContext
        self.habitService = habitService
        self.notificationManager = notificationManager
        self.soundManager = soundManager
        self.widgetService = widgetService
        self.timerService = timerService
    }
    
    // MARK: - Computed Properties
    
    func activeHabits(for date: Date) -> [Habit] {
        allBaseHabits.filter { habit in
            habit.isActiveOnDate(date) && date >= habit.startDate
        }
    }
    
    func navigationTitle(for date: Date) -> String {
        if allBaseHabits.isEmpty { return "" }
        if Calendar.current.isDateInToday(date) { return "today".capitalized }
        if Calendar.current.isDateInYesterday(date) { return "yesterday".capitalized }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: date).capitalized
    }
    
    // MARK: - Actions
    
    private func handleResult(_ didComplete: Bool) {
        if didComplete {
            soundManager.playCompletionSound()
        }
    }
    
    func handleRingTap(on habit: Habit, date: Date) {
        switch habit.type {
        case .count:
            let current = temporaryProgress[habit.uuid] ?? habit.progressForDate(date)
            let newValue = current + 1
            
            temporaryProgress[habit.uuid] = newValue
            
            let result = habitService.addProgress(1, to: habit, date: date, context: modelContext)
            handleResult(result)
            
        case .time:
            let habitId = habit.uuid.uuidString
            if timerService.isTimerRunning(for: habitId) {
                if let finalProgress = timerService.stopTimer(for: habitId) {
                    temporaryProgress[habit.uuid] = finalProgress
                    
                    let result = habitService.updateProgress(to: finalProgress, for: habit, date: date, context: modelContext)
                    handleResult(result)
                }
            } else {
                let current = habit.progressForDate(date)
                _ = timerService.startTimer(for: habitId, baseProgress: current)
            }
        }
        saveAndReloadWithDebounce(for: habit.uuid)
    }
    
    func completeHabit(_ habit: Habit, date: Date) {
        _ = habitService.completeHabit(for: habit, date: date, context: modelContext)
    }
    
    func toggleSkip(for habit: Habit, date: Date) {
        if habit.isSkipped(on: date) {
            habitService.unskipDate(date, for: habit, context: modelContext)
        } else {
            habitService.skipDate(date, for: habit, context: modelContext)
        }
    }
    
    func archiveHabit(_ habit: Habit) {
        habitService.archive(habit, context: modelContext)
    }
    
    func deleteHabit(_ habit: Habit) {
        habitService.delete(habit, context: modelContext)
    }
    
    // MARK: - Reorder
    func moveHabits(from source: IndexSet, to destination: Int, date: Date) {
        let activeHabits = activeHabits(for: date)
        var updatedAllHabits = allBaseHabits.sorted(by: { $0.displayOrder < $1.displayOrder })
        
        let habitsToMove = source.map { activeHabits[$0] }
        
        let targetIndex: Int
        if destination < activeHabits.count {
            let targetHabit = activeHabits[destination]
            targetIndex = updatedAllHabits.firstIndex(of: targetHabit) ?? updatedAllHabits.count
        } else {
            if let lastVisible = activeHabits.last,
               let lastIndexInAll = updatedAllHabits.firstIndex(of: lastVisible) {
                targetIndex = lastIndexInAll + 1
            } else {
                targetIndex = updatedAllHabits.count
            }
        }
        
        let sourceIndices = IndexSet(habitsToMove.compactMap { updatedAllHabits.firstIndex(of: $0) })
        
        updatedAllHabits.move(fromOffsets: sourceIndices, toOffset: targetIndex)
        for (index, habit) in updatedAllHabits.enumerated() {
            habit.displayOrder = index
        }
        saveAndReload()
    }

    private func saveAndReload() {
        try? modelContext.save()
        widgetService.reloadWidgetsAfterDataChange()
    }
    
    // MARK: - Timer
    func checkCompletionForActiveTimer(_ habit: Habit, date: Date) {
        guard let liveProgress = timerService.getLiveProgress(for: habit.uuid.uuidString),
              habit.progressForDate(date) < habit.goal,
              liveProgress >= habit.goal else { return }
        soundManager.playCompletionSound()
    }
    
    // MARK: - Debounce
    private func saveAndReloadWithDebounce(for uuid: UUID) {
        try? modelContext.save()
        widgetService.reloadWidgetsAfterDataChange()
        Task {
            try? await Task.sleep(for: .seconds(0.6))
            temporaryProgress.removeValue(forKey: uuid)
        }
    }
}
