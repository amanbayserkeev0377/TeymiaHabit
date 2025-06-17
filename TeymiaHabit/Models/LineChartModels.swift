import Foundation

// ===== Overview Time Range =====

enum OverviewTimeRange: String, CaseIterable {
    case week = "W"
    case month = "M"
    case year = "Y"
    case heatmap = "H"
    
    var localized: String {
        switch self {
        case .week: return "W"
        case .month: return "M"
        case .year: return "Y"
        case .heatmap: return "square.grid.2x2.fill"
        }
    }
    
    var isIcon: Bool {
        return self == .heatmap
    }
}

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

// ===== Heatmap Data =====

struct HeatmapDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let completionRate: Double // 0.0 or 1.0 for individual habits
}

struct WeekData {
    let week: Int
    let days: [HeatmapDataPoint]
}
