import SwiftUI

struct WeekStartRowView: View {
    @Environment(WeekdayPreferences.self) private var weekdayPrefs
    
    var body: some View {
        NavigationLink(destination: WeekStartView()) {
            HStack {
                Label(
                    title: { Text("settings_week_start") },
                    icon: { RowIcon(systemName: "calendar") }
                )
                Spacer()
                Text(selectedWeekDayName).foregroundStyle(Color.secondary)
            }
        }
    }
    
    private var selectedWeekDayName: LocalizedStringResource {
        let current = weekdayPrefs.firstDayOfWeek
        if current == 0 { return "week_start_system" }
        let name = Calendar.current.weekdaySymbols[current - 1].capitalized
        return LocalizedStringResource(stringLiteral: name)
    }
}

struct WeekStartView: View {
    @Environment(WeekdayPreferences.self) private var prefs
    
    private var options: [(name: String, value: Int)] {
        let symbols = Calendar.current.weekdaySymbols
        var list = [("week_start_system", 0)]
        let targetDays = [7, 1, 2]
        
        for dayValue in targetDays {
            let name = symbols[dayValue - 1].capitalized
            list.append((name, dayValue))
        }
        return list
    }
    
    var body: some View {
        List {
            ForEach(options, id: \.value) { option in
                Button {
                    withAnimation(.snappy) {
                        prefs.updateFirstDayOfWeek(option.value)
                    }
                } label: {
                    HStack {
                        Text(LocalizedStringResource(stringLiteral: option.name))
                            .foregroundStyle(Color.primary)
                        
                        Spacer()
                        
                        if prefs.firstDayOfWeek == option.value { SelectionCheckmark() }
                    }
                }
            }
        }
        .navigationTitle("settings_week_start")
    }
}
