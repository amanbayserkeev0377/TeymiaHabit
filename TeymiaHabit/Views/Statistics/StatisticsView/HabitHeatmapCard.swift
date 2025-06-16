import SwiftUI

struct HabitHeatmapCard: View {
    let habit: Habit
    let onTap: () -> Void
    
    @State private var heatmapData: [HeatmapDataPoint] = []
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
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
                    
                    // Year stats
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(yearCompletionRate)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(habit.iconColor.color)
                        
                        Text("This Year")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Heatmap Grid (GitHub style - horizontal layout)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 1) {
                        ForEach(heatmapWeeks, id: \.week) { weekData in
                            VStack(spacing: 1) {
                                ForEach(0..<7, id: \.self) { dayIndex in
                                    if dayIndex < weekData.days.count {
                                        RoundedRectangle(cornerRadius: 1)
                                            .fill(colorForCompletionRate(weekData.days[dayIndex].completionRate))
                                            .frame(width: 8, height: 8)
                                    } else {
                                        RoundedRectangle(cornerRadius: 1)
                                            .fill(Color.clear)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .stroke(habit.iconColor.color.opacity(0.2), lineWidth: 1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            generateHeatmapData()
        }
    }
    
    // MARK: - Data Generation
    
    private func generateHeatmapData() {
        var data: [HeatmapDataPoint] = []
        let today = Date()
        
        // Calculate days for past year (365 days)
        for dayOffset in 0..<365 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset - 364, to: today) else { continue }
            let completionRate = calculateCompletionRate(for: date)
            data.append(HeatmapDataPoint(date: date, completionRate: completionRate))
        }
        
        heatmapData = data
    }
    
    private func calculateCompletionRate(for date: Date) -> Double {
        // Only calculate for dates not in the future
        guard date <= Date() else { return 0 }
        
        // Check if habit is active on this date
        guard habit.isActiveOnDate(date) else { return 0 }
        
        let progress = habit.progressForDate(date)
        let goal = habit.goal
        
        // Return 1.0 if completed, 0.0 if not
        return progress >= goal ? 1.0 : 0.0
    }
    
    private func colorForCompletionRate(_ rate: Double) -> Color {
        if rate == 0 {
            return Color.gray.opacity(0.1)
        } else {
            return habit.iconColor.color.opacity(0.8)
        }
    }
    
    // MARK: - Computed Properties
    
    private var heatmapWeeks: [WeekData] {
        // Group days into weeks for proper grid layout
        var weeks: [WeekData] = []
        var currentWeek: [HeatmapDataPoint] = []
        
        for (index, dataPoint) in heatmapData.enumerated() {
            currentWeek.append(dataPoint)
            
            // Complete week (7 days) or last day
            if currentWeek.count == 7 || index == heatmapData.count - 1 {
                weeks.append(WeekData(week: weeks.count, days: currentWeek))
                currentWeek = []
            }
        }
        
        return weeks
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
