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
                    value: "\(bestStreakUpToDate)",
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
    
    private var bestStreakUpToDate: Int {
        let calendar = Calendar.current
        
        guard let completions = habit.completions else { return 0 }
        
        // Получаем все завершенные даты ДО выбранной даты
        let completedDates = completions
            .filter { $0.value >= habit.goal && $0.date <= date }
            .map { calendar.startOfDay(for: $0.date) }
        
        return calculateBestStreakUpToDate(completedDates: completedDates)
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
        let today = calendar.startOfDay(for: Date())
        
        // Преобразуем даты в начало дня и сортируем по убыванию
        let sortedDates = completedDates
            .map { calendar.startOfDay(for: $0) }
            .sorted(by: >)
        
        // Если нет выполненных дат, возвращаем 0
        guard !sortedDates.isEmpty else { return 0 }
        
        // Проверяем, является ли targetDate сегодняшним днем
        let isTargetToday = calendar.isDate(targetDate, inSameDayAs: today)
        
        // Проверяем, выполнена ли привычка на целевой дате
        let isCompletedOnTargetDate = sortedDates.contains(where: { calendar.isDate($0, inSameDayAs: targetDate) })
        
        // Если targetDate - это сегодня, и день активен, и привычка не выполнена,
        // но еще не 23:00, не обнуляем стрик
        if isTargetToday && habit.isActiveOnDate(targetDate) && !isCompletedOnTargetDate && calendar.component(.hour, from: Date()) < 23 {
            // Начинаем считать стрик с предыдущего дня
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
        
        // Если целевая дата не завершена и это не сегодня, стрик = 0
        if !isCompletedOnTargetDate {
            return 0
        }
        
        var streak = 0
        var currentDate = targetDate
        
        // Считаем назад от целевой даты
        while currentDate >= habit.startDate {
            // Если день активен для привычки
            if habit.isActiveOnDate(currentDate) {
                if sortedDates.contains(where: { calendar.isDate($0, inSameDayAs: currentDate) }) {
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
    
    private func calculateBestStreakUpToDate(completedDates: [Date]) -> Int {
            let calendar = Calendar.current
            let targetDate = calendar.startOfDay(for: date)
            
            // Преобразуем даты в начало дня
            let completedDays = completedDates
                .map { calendar.startOfDay(for: $0) }
                .reduce(into: Set<Date>()) { result, date in
                    result.insert(date)
                }
            
            var bestStreak = 0
            var currentStreak = 0
            var checkDate = calendar.startOfDay(for: habit.startDate)
            
            // ✅ Проходим дни от начала привычки ДО целевой даты (включительно)
            while checkDate <= targetDate {
                // Если день активен для привычки
                if habit.isActiveOnDate(checkDate) {
                    // Проверяем, выполнена ли привычка в этот день
                    if completedDays.contains(checkDate) {
                        currentStreak += 1
                        // Обновляем лучший стрик, если текущий больше
                        bestStreak = max(bestStreak, currentStreak)
                    } else {
                        // Стрик прерван
                        currentStreak = 0
                    }
                }
                
                // Переходим к следующему дню
                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: checkDate) else { break }
                checkDate = nextDate
            }
            
            return bestStreak
        }
}




