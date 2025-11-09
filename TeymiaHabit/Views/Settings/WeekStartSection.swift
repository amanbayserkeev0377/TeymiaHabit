import SwiftUI

struct WeekStartSection: View {
    @Environment(WeekdayPreferences.self) private var weekdayPrefs
    @State private var selection: Int
    
    init() {
        _selection = State(initialValue: WeekdayPreferences.shared.firstDayOfWeek)
    }
    
    private var localizedWeekdays: [(name: String, value: Int)] {
        let calendar = Calendar.current
        let today = Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        
        let weekday = calendar.component(.weekday, from: today)
        
        // Calculate date offsets for specific weekdays
        let sundayOffset = weekday == 1 ? 0 : -(weekday - 1)
        let mondayOffset = weekday == 2 ? 0 : (weekday > 2 ? -(weekday - 2) : 1)
        let saturdayOffset = weekday == 7 ? 0 : (weekday < 7 ? 7 - weekday : -1)
        
        let sundayDate = calendar.date(byAdding: .day, value: sundayOffset, to: today)!
        let mondayDate = calendar.date(byAdding: .day, value: mondayOffset, to: today)!
        let saturdayDate = calendar.date(byAdding: .day, value: saturdayOffset, to: today)!
        
        let sundayName = dateFormatter.string(from: sundayDate).capitalized
        let mondayName = dateFormatter.string(from: mondayDate).capitalized
        let saturdayName = dateFormatter.string(from: saturdayDate).capitalized
        
        return [
            ("week_start_system".localized, 0),
            (saturdayName, 7),
            (sundayName, 1),
            (mondayName, 2)
        ]
    }
    
    var body: some View {
        Picker(selection: $selection) {
            ForEach(localizedWeekdays, id: \.value) { weekday in
                Text(weekday.name).tag(weekday.value)
            }
        } label: {
            Label(
                title: { Text("week_start_day".localized) },
                icon: {
                    Image("calendar")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(.brown.gradient)
                }
            )
        }
        .pickerStyle(.menu)
        .tint(.secondary)
        .onChange(of: selection) { _, newValue in
            weekdayPrefs.updateFirstDayOfWeek(newValue)
        }
    }
}
