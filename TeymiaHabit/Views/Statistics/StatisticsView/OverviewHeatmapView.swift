import SwiftUI

struct OverviewHeatmapView: View {
    let habits: [Habit]
    
    @State private var heatmapData: [HeatmapDataPoint] = []
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Combined activity across all habits (past year)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Overall heatmap
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 1) {
                    ForEach(heatmapWeeks, id: \.week) { weekData in
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
                .padding(.horizontal, 4)
            }
            
            // Legend and stats
            HStack {
                // Legend
                HStack(spacing: 4) {
                    Text("Less")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    ForEach(0..<5, id: \.self) { intensity in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(legendColor(for: intensity))
                            .frame(width: 8, height: 8)
                    }
                    
                    Text("More")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Overall year stats
                VStack(alignment: .trailing, spacing: 2) {
                    Text(overallYearStats)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColorManager.shared.selectedColor.color)
                    
                    Text("Overall")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary)
        }
        .onAppear {
            generateOverallHeatmapData()
        }
    }
    
    // MARK: - Data Generation
    
    private func generateOverallHeatmapData() {
        var data: [HeatmapDataPoint] = []
        let today = Date()
        
        // Calculate days for past year (365 days)
        for dayOffset in 0..<365 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset - 364, to: today) else { continue }
            let completionRate = calculateOverallCompletionRate(for: date)
            data.append(HeatmapDataPoint(date: date, completionRate: completionRate))
        }
        
        heatmapData = data
    }
    
    private func calculateOverallCompletionRate(for date: Date) -> Double {
        // Only calculate for dates not in the future
        guard date <= Date() else { return 0 }
        
        // Get all habits that were active on this date
        let activeHabits = habits.filter { $0.isActiveOnDate(date) }
        guard !activeHabits.isEmpty else { return 0 }
        
        // Calculate how many habits were completed
        let completedHabits = activeHabits.filter { habit in
            habit.progressForDate(date) >= habit.goal
        }
        
        // Return percentage of habits completed (0.0 to 1.0)
        return Double(completedHabits.count) / Double(activeHabits.count)
    }
    
    private func colorForCompletionRate(_ rate: Double) -> Color {
        switch rate {
        case 0:
            return Color.gray.opacity(0.1)
        case 0.01..<0.25:
            return Color.green.opacity(0.3)
        case 0.25..<0.50:
            return Color.green.opacity(0.5)
        case 0.50..<0.75:
            return Color.green.opacity(0.7)
        case 0.75..<1.0:
            return Color.green.opacity(0.9)
        case 1.0:
            return Color.green
        default:
            return Color.gray.opacity(0.1)
        }
    }
    
    private func legendColor(for intensity: Int) -> Color {
        switch intensity {
        case 0: return Color.gray.opacity(0.1)
        case 1: return Color.green.opacity(0.3)
        case 2: return Color.green.opacity(0.5)
        case 3: return Color.green.opacity(0.7)
        case 4: return Color.green
        default: return Color.gray.opacity(0.1)
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
    
    private var overallYearStats: String {
        let activeDays = heatmapData.filter { $0.completionRate > 0 }
        let totalDays = heatmapData.filter { dataPoint in
            // Only count days where at least one habit was active
            return habits.contains { $0.isActiveOnDate(dataPoint.date) && dataPoint.date <= Date() }
        }
        
        if totalDays.isEmpty { return "0%" }
        
        let percentage = (Double(activeDays.count) / Double(totalDays.count)) * 100
        return "\(Int(percentage))%"
    }
}
