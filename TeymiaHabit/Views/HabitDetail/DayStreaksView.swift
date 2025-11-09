import SwiftUI

struct DayStreaksView: View {
    let habit: Habit
    let date: Date
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "laurel.leading")
                .font(.system(size: 38))
                .foregroundStyle(laurelGradient.gradient)
            
            Group {
                StatColumn(
                    value: "\(currentStreakUpToDate)",
                    label: "streak".localized
                )
                
                StatColumn(
                    value: "\(bestStreakUpToDate)",
                    label: "best".localized
                )
                
                StatColumn(
                    value: "\(totalCompletedUpToDate)",
                    label: "total".localized
                )
            }
            
            Image(systemName: "laurel.trailing")
                .font(.system(size: 38))
                .foregroundStyle(laurelGradient.gradient)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Computed Properties
    
    private var currentStreakUpToDate: Int {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        guard let completions = habit.completions else { return 0 }
        
        let completedDates = completions
            .filter { $0.value >= habit.goal && $0.date <= date }
            .map { calendar.startOfDay(for: $0.date) }
        
        return calculateStreakUpToDate(completedDates: completedDates, targetDate: targetDate)
    }
    
    private var bestStreakUpToDate: Int {
        let calendar = Calendar.current
        
        guard let completions = habit.completions else { return 0 }
        
        let completedDates = completions
            .filter { $0.value >= habit.goal && $0.date <= date }
            .map { calendar.startOfDay(for: $0.date) }
        
        return calculateBestStreakUpToDate(completedDates: completedDates)
    }
    
    private var totalCompletedUpToDate: Int {
        guard let completions = habit.completions else { return 0 }
        
        let calendar = Calendar.current
        let completedDays = completions
            .filter { $0.value >= habit.goal && $0.date <= date }
            .map { calendar.startOfDay(for: $0.date) }
        
        return Set(completedDays).count
    }
    
    private var laurelGradient: Color {
        habit.iconColor.color
    }
    
    // MARK: - Helper Methods
    
    private func calculateStreakUpToDate(completedDates: [Date], targetDate: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let sortedDates = completedDates
            .map { calendar.startOfDay(for: $0) }
            .sorted(by: >)
        
        guard !sortedDates.isEmpty else { return 0 }
        
        let isTargetToday = calendar.isDate(targetDate, inSameDayAs: today)
        let isCompletedOnTargetDate = sortedDates.contains(where: { calendar.isDate($0, inSameDayAs: targetDate) })
        
        /// Don't break streak for today if it's before 23:00 and habit is active
        if isTargetToday && habit.isActiveOnDate(targetDate) && !isCompletedOnTargetDate && calendar.component(.hour, from: Date()) < 23 {
            let previousDate = calendar.date(byAdding: .day, value: -1, to: targetDate)!
            var streak = 0
            var currentDate = previousDate
            
            while currentDate >= habit.startDate {
                if habit.isActiveOnDate(currentDate) {
                    if sortedDates.contains(where: { calendar.isDate($0, inSameDayAs: currentDate) }) {
                        streak += 1
                        currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                    } else {
                        break
                    }
                } else {
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                }
            }
            return streak
        }
        
        if !isCompletedOnTargetDate {
            return 0
        }
        
        var streak = 0
        var currentDate = targetDate
        
        while currentDate >= habit.startDate {
            if habit.isActiveOnDate(currentDate) {
                if sortedDates.contains(where: { calendar.isDate($0, inSameDayAs: currentDate) }) {
                    streak += 1
                } else {
                    break
                }
            }
            
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        return streak
    }
    
    private func calculateBestStreakUpToDate(completedDates: [Date]) -> Int {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        let completedDays = completedDates
            .map { calendar.startOfDay(for: $0) }
            .reduce(into: Set<Date>()) { result, date in
                result.insert(date)
            }
        
        var bestStreak = 0
        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: habit.startDate)
        
        while checkDate <= targetDate {
            if habit.isActiveOnDate(checkDate) {
                if completedDays.contains(checkDate) {
                    currentStreak += 1
                    bestStreak = max(bestStreak, currentStreak)
                } else {
                    currentStreak = 0
                }
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: checkDate) else { break }
            checkDate = nextDate
        }
        
        return bestStreak
    }
}
