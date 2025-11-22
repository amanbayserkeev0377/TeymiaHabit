import SwiftUI
import SwiftData

@Observable
class HabitStatsViewModel {
    let habit: Habit
    
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var totalValue: Int = 0
    
    init(habit: Habit) {
        self.habit = habit
        calculateStats()
    }
    
    func refresh() {
        calculateStats()
    }
    
    // MARK: - Private Methods
    
    private func calculateStats() {
        let calendar = Calendar.current
        
        var completedDates: [Date] = []
        var completedDaysSet = Set<Date>()
        
        guard let completions = habit.completions else {
            currentStreak = 0
            bestStreak = 0
            totalValue = 0
            return
        }
        
        for completion in completions {
            let dayStart = calendar.startOfDay(for: completion.date)
            
            if completion.value >= habit.goal {
                if !completedDates.contains(where: { calendar.isDate($0, inSameDayAs: dayStart) }) {
                    completedDates.append(dayStart)
                }
                completedDaysSet.insert(dayStart)
            }
        }
        
        totalValue = completedDaysSet.count
        currentStreak = calculateCurrentStreak(completedDates: completedDates)
        bestStreak = calculateBestStreak(completedDates: completedDates)
    }
    
    private func calculateCurrentStreak(completedDates: [Date]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let sortedDates = completedDates
            .map { calendar.startOfDay(for: $0) }
            .sorted(by: >)
        
        guard !sortedDates.isEmpty else { return 0 }
        
        let isCompletedToday = sortedDates.contains { calendar.isDate($0, inSameDayAs: today) }
        
        // Break streak if today is active day but not completed after 23:00
        if habit.isActiveOnDate(today) && !isCompletedToday && calendar.component(.hour, from: Date()) >= 23 {
            return 0
        }
        
        var streak = 0
        var currentDate = isCompletedToday ? today : calendar.date(byAdding: .day, value: -1, to: today)!
        
        while true {
            if !habit.isActiveOnDate(currentDate) {
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                if currentDate < habit.startDate {
                    break
                }
                continue
            }
            
            let isCompletedOnDate = sortedDates.contains { calendar.isDate($0, inSameDayAs: currentDate) }
            let  isSkippedOnDate = habit.isSkipped(on: currentDate)
            
            if isCompletedOnDate || isSkippedOnDate {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                
                if currentDate < habit.startDate {
                    break
                }
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateBestStreak(completedDates: [Date]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let completedDays = completedDates
            .map { calendar.startOfDay(for: $0) }
            .reduce(into: Set<Date>()) { result, date in
                result.insert(date)
            }
        
        var bestStreak = 0
        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: habit.startDate)
        
        while checkDate <= today {
            if habit.isActiveOnDate(checkDate) {
                let isSkippedOnDate = habit.isSkipped(on: checkDate)
                if completedDays.contains(checkDate) || isSkippedOnDate {
                    currentStreak += 1
                    bestStreak = max(bestStreak, currentStreak)
                } else {
                    currentStreak = 0
                }
            }
            
            checkDate = calendar.date(byAdding: .day, value: 1, to: checkDate)!
        }
        
        return bestStreak
    }
}
