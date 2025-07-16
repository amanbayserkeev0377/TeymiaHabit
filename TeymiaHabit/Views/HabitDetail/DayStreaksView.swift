import SwiftUI

struct DayStreaksView: View {
    let habit: Habit
    let date: Date
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "laurel.leading")
                .font(.system(size: 38))
                .foregroundStyle(laurelGradient)
            
            Group {
                // Current Streak до этой даты
                StatColumn(
                    value: "\(currentStreakUpToDate)",
                    label: "streak".localized
                )
                
                // Best Streak (остается глобальным)
                StatColumn(
                    value: "\(bestStreak)",
                    label: "best".localized
                )
                
                // Total до этой даты
                StatColumn(
                    value: "\(totalCompletedUpToDate)",
                    label: "total".localized
                )
            }
            
            Image(systemName: "laurel.trailing")
                .font(.system(size: 38))
                .foregroundStyle(laurelGradient)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Computed Properties
    
    // Current streak до выбранной даты (включительно)
    private var currentStreakUpToDate: Int {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        // Получаем все завершенные даты до целевой даты
        guard let completions = habit.completions else { return 0 }
        
        let completedDates = completions
            .filter { $0.value >= habit.goal && $0.date <= date }
            .map { calendar.startOfDay(for: $0.date) }
        
        return calculateStreakUpToDate(completedDates: completedDates, targetDate: targetDate)
    }
    
    // Best streak (глобальный, как в оригинале)
    private var bestStreak: Int {
        let statsViewModel = HabitStatsViewModel(habit: habit)
        return statsViewModel.bestStreak
    }
    
    // Total завершений до выбранной даты (включительно)
    private var totalCompletedUpToDate: Int {
        guard let completions = habit.completions else { return 0 }
        
        let calendar = Calendar.current
        let completedDays = completions
            .filter { $0.value >= habit.goal && $0.date <= date }
            .map { calendar.startOfDay(for: $0.date) }
        
        return Set(completedDays).count
    }
    
    // MARK: - Gradient for Laurel Branches
    private var laurelGradient: LinearGradient {
        return habit.iconColor.adaptiveGradient(for: colorScheme)
    }
    
    // MARK: - Helper Methods
    
    private func calculateStreakUpToDate(completedDates: [Date], targetDate: Date) -> Int {
        let calendar = Calendar.current
        let completedDaysSet = Set(completedDates)
        
        // Если целевая дата не завершена, streak = 0
        if !completedDaysSet.contains(targetDate) {
            return 0
        }
        
        var streak = 0
        var currentDate = targetDate
        
        // Считаем назад от целевой даты
        while currentDate >= habit.startDate {
            // Если день активен для привычки
            if habit.isActiveOnDate(currentDate) {
                if completedDaysSet.contains(currentDate) {
                    streak += 1
                } else {
                    break // Streak прерван
                }
            }
            
            // Переходим к предыдущему дню
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        return streak
    }
}
