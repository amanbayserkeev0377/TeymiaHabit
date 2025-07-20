import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(
        filter: #Predicate<Habit> { habit in
            !habit.isArchived
        },
        sort: [SortDescriptor(\Habit.displayOrder), SortDescriptor(\Habit.createdAt)]
    )
    private var allHabits: [Habit]
    
    private var habits: [Habit] {
        allHabits.sorted { first, second in
            if first.displayOrder != second.displayOrder {
                return first.displayOrder < second.displayOrder
            }
            return first.createdAt < second.createdAt
        }
    }
    
    @State private var selectedHabitForStats: Habit? = nil
    
    var body: some View {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea(.all)
                
                if habits.isEmpty {
                    StatisticsEmptyStateView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            VStack(spacing: 16) {
                                OverviewStatsView(habits: habits)
                            }
                            .padding(.horizontal, 8)
                            .padding(.top, 16)
                            
                            // Habits List with individual StreaksView
                            LazyVStack(spacing: 12) {
                                ForEach(habits) { habit in
                                    HabitStatsListCard(habit: habit) {
                                        selectedHabitForStats = habit
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            Spacer(minLength: 20)
                        }
                    }
                }
            }
        .navigationTitle("statistics".localized)
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedHabitForStats) { habit in
                HabitStatisticsView(habit: habit)
                .presentationSizing(.page)
        }
    }
}

// MARK: - Statistics Empty State

struct StatisticsEmptyStateView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Image("3d_bar_chart")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: UIScreen.main.bounds.width * 0.45,
                       height: UIScreen.main.bounds.width * 0.45)
            
            Spacer()
        }
    }
}
