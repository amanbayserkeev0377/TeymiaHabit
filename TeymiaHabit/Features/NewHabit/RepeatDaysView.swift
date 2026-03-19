import SwiftUI

struct RepeatDaysView: View {
    @Binding var activeDays: [Bool]
    @Environment(WeekdayPreferences.self) private var weekdayPrefs
    @Environment(AppColorManager.self) private var colorManager
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    private var orderedWeekdays: [Weekday] {
        calendar.weekdays
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(orderedWeekdays, id: \.self) { weekday in
                let index = weekday.rawValue - 1
                let isActive = activeDays[index]
                let dayName = String(weekday.shortName.prefix(1)).uppercased()
                
                Button {
                    toggleDay(index)
                } label: {
                    Text(dayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isActive ? Color.primaryInverse.gradient : Color.primary.gradient)
                        .frame(width: 40, height: 40)
                        .background {
                            if isActive {
                                Circle()
                                    .fill(Color.primary.gradient)
                            }
                        }
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .circle)
            }
        }
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.selection, trigger: activeDays)
    }
    
    private func toggleDay(_ index: Int) {
        let activeCount = activeDays.filter { $0 }.count
        if activeCount == 1 && activeDays[index] { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            activeDays[index].toggle()
        }
    }
}
