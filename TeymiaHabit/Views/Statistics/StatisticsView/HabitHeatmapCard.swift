import SwiftUI

struct HabitHeatmapCard: View {
    let habit: Habit
    let onTap: () -> Void
    
    @State private var heatmapData: [HeatmapDataPoint] = []
    @State private var isDataLoaded = false
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.playSelection()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header (всегда показываем)
                HStack {
                    if let iconName = habit.iconName {
                        Image(systemName: iconName)
                            .font(.system(size: 20))
                            .foregroundStyle(habit.iconColor.color)
                            .frame(width: 24, height: 24)
                    }
                    
                    Text(habit.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        if isDataLoaded {
                            Text(yearCompletionRate)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(habit.iconColor.color)
                        } else {
                            Text("...")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("this_year".localized)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                
                // Heatmap Grid - ЛЕНИВАЯ ЗАГРУЗКА
                if isDataLoaded {
                    heatmapContent
                    HeatmapLegend(habit: habit)
                } else {
                    // Placeholder пока данные загружаются
                    loadingPlaceholder
                }
            }
            .padding(.horizontal, 0)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // 🚀 КЛЮЧ: Загружаем данные только когда карточка появляется на экране
            if !isDataLoaded {
                Task {
                    await loadDataAsync()
                }
            }
        }
    }
    
    // MARK: - Lazy Loading
    
    @MainActor
    private func loadDataAsync() async {
        // Небольшая задержка чтобы не все карточки загружались одновременно
        try? await Task.sleep(nanoseconds: UInt64.random(in: 50_000_000...200_000_000)) // 50-200ms
        
        await Task {
            generateHeatmapData()
        }.value
        
        isDataLoaded = true
    }
    
    // MARK: - Content Views
    
    private var heatmapContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 4) {
                // Fixed weekday labels
                VStack(spacing: 1) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 12, height: 16)
                    
                    ForEach(0..<7, id: \.self) { dayIndex in
                        Text(weekdayLabels[dayIndex])
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 12, height: 12, alignment: .center)
                    }
                }
                .frame(width: 16)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 0) {
                            ForEach(Array(monthLabels.enumerated()), id: \.offset) { index, month in
                                Text(month)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 39, alignment: .leading)
                            }
                        }
                        .frame(height: 16)
                        
                        HStack(spacing: 1) {
                            ForEach(yearlyWeeks, id: \.week) { weekData in
                                VStack(spacing: 1) {
                                    ForEach(0..<7, id: \.self) { dayIndex in
                                        if dayIndex < weekData.days.count {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(colorForCompletionRate(weekData.days[dayIndex].completionRate))
                                                .frame(width: 12, height: 12)
                                        } else {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.clear)
                                                .frame(width: 12, height: 12)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(.horizontal, 8)
        .onAppear {
            // Smooth fade-in animation когда данные готовы
            withAnimation(.easeOut(duration: 0.3)) {
                // Animation trigger if needed
            }
        }
    }
    
    private var loadingPlaceholder: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 4) {
                // Weekday labels placeholder
                VStack(spacing: 1) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 12, height: 16)
                    
                    ForEach(0..<7, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 12, height: 12)
                    }
                }
                .frame(width: 16)
                
                // 🚀 НАТИВНЫЙ Loading с ProgressView
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 1) {
                        // Month labels placeholder
                        HStack(spacing: 0) {
                            ForEach(0..<12, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 39, height: 12)
                            }
                        }
                        .frame(height: 16)
                        
                        // 🎯 ЦЕНТРАЛЬНЫЙ ProgressView вместо fake grid
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(habit.iconColor.color)
                                
                                Text("Loading...")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .frame(height: 84) // Высота реального heatmap grid
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(.horizontal, 8)
        .redacted(reason: .placeholder) // 🚀 НАТИВНЫЙ placeholder эффект
    }
    
    // MARK: - Data Generation (оптимизированная версия)
    
    private func generateHeatmapData() {
        let currentYear = calendar.component(.year, from: Date())
        guard let startOfYear = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)) else {
            return
        }
        
        // Используем кэш для оптимизации
        let progressCache = buildProgressCache()
        
        var data: [HeatmapDataPoint] = []
        let today = Date()
        let endDate = min(today, calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31)) ?? today)
        
        var currentDate = startOfYear
        while currentDate <= endDate {
            let completionRate = calculateCompletionRateFromCache(for: currentDate, cache: progressCache)
            data.append(HeatmapDataPoint(date: currentDate, completionRate: completionRate))
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        heatmapData = data
    }
    
    private func buildProgressCache() -> [String: Int] {
        var cache: [String: Int] = [:]
        
        let currentYear = calendar.component(.year, from: Date())
        guard let startOfYear = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31)) else {
            return cache
        }
        
        guard let completions = habit.completions else { return cache }
        
        for completion in completions {
            if completion.date >= startOfYear && completion.date <= endOfYear {
                let dateKey = formatDateKey(completion.date)
                cache[dateKey] = (cache[dateKey] ?? 0) + completion.value
            }
        }
        
        return cache
    }
    
    private func calculateCompletionRateFromCache(for date: Date, cache: [String: Int]) -> Double {
        guard date <= Date() && habit.isActiveOnDate(date) else { return 0 }
        
        let dateKey = formatDateKey(date)
        let progress = cache[dateKey] ?? 0
        let goal = habit.goal
        
        return goal > 0 ? min(Double(progress) / Double(goal), 1.0) : 0
    }
    
    private func formatDateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // MARK: - Helper Properties (without changes)
    
    private var yearlyWeeks: [WeekData] {
        let currentYear = calendar.component(.year, from: Date())
        guard let january1st = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)) else {
            return []
        }
        
        var startDate = january1st
        while calendar.component(.weekday, from: startDate) != 1 {
            startDate = calendar.date(byAdding: .day, value: -1, to: startDate)!
        }
        
        var weeks: [WeekData] = []
        
        for weekIndex in 0..<52 {
            var weekDays: [HeatmapDataPoint] = []
            
            for dayIndex in 0..<7 {
                let currentDate = calendar.date(byAdding: .day, value: weekIndex * 7 + dayIndex, to: startDate)!
                let currentDateYear = calendar.component(.year, from: currentDate)
                
                if currentDateYear == currentYear && currentDate <= Date() {
                    let dataPoint = heatmapData.first { calendar.isDate($0.date, inSameDayAs: currentDate) } ??
                                    HeatmapDataPoint(date: currentDate, completionRate: 0)
                    weekDays.append(dataPoint)
                } else {
                    weekDays.append(HeatmapDataPoint(date: currentDate, completionRate: 0))
                }
            }
            
            weeks.append(WeekData(week: weekIndex, days: weekDays))
        }
        
        return weeks
    }
    
    private var monthLabels: [String] {
        return ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    }
    
    private var weekdayLabels: [String] {
        let firstWeekday = calendar.firstWeekday
        var labels: [String] = []
        
        for i in 0..<7 {
            let weekdayIndex = (firstWeekday + i - 1) % 7
            let weekdayName = calendar.shortWeekdaySymbols[weekdayIndex]
            labels.append(String(weekdayName.prefix(1)).uppercased())
        }
        
        return labels
    }
    
    private func colorForCompletionRate(_ rate: Double) -> Color {
        let baseColor = habit.iconColor.color
        
        switch rate {
        case 0:
            return Color.gray.opacity(0.1)
        case 0.01..<0.25:
            return baseColor.opacity(0.3)
        case 0.25..<0.50:
            return baseColor.opacity(0.5)
        case 0.50..<0.75:
            return baseColor.opacity(0.7)
        case 0.75..<1.0:
            return baseColor.opacity(0.9)
        default:
            return baseColor
        }
    }
    
    private func legendColor(for level: Int) -> Color {
        let baseColor = habit.iconColor.color
        
        switch level {
        case 0: return Color.gray.opacity(0.1)
        case 1: return baseColor.opacity(0.3)
        case 2: return baseColor.opacity(0.5)
        case 3: return baseColor.opacity(0.7)
        case 4: return baseColor
        default: return baseColor
        }
    }
    
    private var yearCompletionRate: String {
        let activeDays = heatmapData.filter { dataPoint in
            habit.isActiveOnDate(dataPoint.date) && dataPoint.date <= Date()
        }
        
        if activeDays.isEmpty { return "0%" }
        
        let completedDays = activeDays.filter { $0.completionRate >= 1.0 }.count
        let percentage = (Double(completedDays) / Double(activeDays.count)) * 100
        return "\(Int(percentage))%"
    }
}

// MARK: - Legend Component (вынеси в отдельный файл)
struct HeatmapLegend: View {
    let habit: Habit
    
    var body: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 6) {
                Text("less".localized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                ForEach(0..<5, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(legendColor(for: level))
                        .frame(width: 12, height: 12)
                }
                
                Text("more".localized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private func legendColor(for level: Int) -> Color {
        let baseColor = habit.iconColor.color
        
        switch level {
        case 0: return Color.gray.opacity(0.1)
        case 1: return baseColor.opacity(0.3)
        case 2: return baseColor.opacity(0.5)
        case 3: return baseColor.opacity(0.7)
        case 4: return baseColor
        default: return baseColor
        }
    }
}
