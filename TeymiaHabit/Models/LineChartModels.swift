import Foundation

// ===== Generic Line Chart Data Point =====

struct LineChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let completionRate: Double // 0.0 to 1.0
}

// ===== Specific Chart Data Points =====

struct WeeklyChartDataPoint: Identifiable {
    let id = UUID()
    let dayName: String  
    let date: Date      
    let completionRate: Double
}

struct MonthlyChartDataPoint: Identifiable {
    let id = UUID()
    let dayName: String  
    let date: Date      
    let completionRate: Double
}

struct YearlyChartDataPoint: Identifiable {
    let id = UUID()
    let monthName: String  
    let date: Date      
    let completionRate: Double
}
