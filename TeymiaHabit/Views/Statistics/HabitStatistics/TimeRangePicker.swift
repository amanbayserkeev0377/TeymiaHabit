import SwiftUI

enum ChartTimeRange: String, CaseIterable {
    case week
    case month
    case year

    var localized: String {
        switch self {
        case .week: return "week".localized
        case .month: return "month".localized
        case .year: return "year".localized
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
        Picker("Time Range", selection: $selection) {
            ForEach(ChartTimeRange.allCases, id: \.self) { range in
                Text(range.localized).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}
