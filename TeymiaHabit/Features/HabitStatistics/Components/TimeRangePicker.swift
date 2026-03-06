import SwiftUI

enum ChartTimeRange: String, CaseIterable {
    case week
    case month
    case year

    var displayName: LocalizedStringResource {
        switch self {
        case .week: return "chart_range_week"
        case .month: return "chart_range_month"
        case .year: return "chart_range_year"
        }
    }

    var days: Int {
        let calendar = Calendar.current
        switch self {
        case .week:
            return 7
        case .month:
            let range = calendar.range(of: .day, in: .month, for: Date())
            return range?.count ?? 30
        case .year:
            let range = calendar.range(of: .day, in: .year, for: Date())
            return range?.count ?? 365
        }
    }
}

struct TimeRangePicker: View {
    @Binding var selection: ChartTimeRange

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(ChartTimeRange.allCases, id: \.self) { range in
                Text(range.displayName).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}
