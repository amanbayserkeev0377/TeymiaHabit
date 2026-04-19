import SwiftUI

struct HabitStatisticsView: View {
    @State private var statsViewModel: HabitStatsViewModel
    let habit: Habit
    
    init(habit: Habit) {
        self.habit = habit
        _statsViewModel = State(wrappedValue: HabitStatsViewModel(habit: habit))
    }
    
    var body: some View {
        @Bindable var vm = statsViewModel
        
        NavigationStack {
            List {
                Section {
                    StreaksView(viewModel: statsViewModel)
                }
                
                Section {
                    MonthlyCalendarView(
                        habit: habit,
                        selectedDate: $vm.selectedDate
                    )
                }
                .listRowInsets(EdgeInsets())
                
                Section {
                    VStack(spacing: 30) {
                        TimeRangePicker(selection: $vm.barChartTimeRange)
                            .padding(.horizontal, 16)
                        
                        barChartContent
                    }
                }
                .listRowInsets(EdgeInsets())
            }
            .navigationTitle(habit.title)
            .navigationSubtitle("Goal: \(habit.formattedGoal)")
            .toolbar {
                CloseToolbarButton()
            }
        }
    }
    
    @ViewBuilder
    private var barChartContent: some View {
        switch statsViewModel.barChartTimeRange {
        case .week: WeeklyHabitChart(habit: habit)
        case .month: MonthlyHabitChart(habit: habit)
        case .year: YearlyHabitChart(habit: habit)
        }
    }
}
