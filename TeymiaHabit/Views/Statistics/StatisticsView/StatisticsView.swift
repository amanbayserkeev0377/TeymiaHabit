import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(
        filter: #Predicate<Habit> { habit in
            !habit.isArchived
        },
        sort: [SortDescriptor(\Habit.createdAt)]
    )
    private var allHabits: [Habit]
    
    private var habits: [Habit] {
        allHabits.sorted { first, second in
            if first.isPinned != second.isPinned {
                return first.isPinned && !second.isPinned
            }
            return first.createdAt < second.createdAt
        }
    }
    
    @State private var selectedHabitForStats: Habit? = nil
    
    var body: some View {
        NavigationStack {
            if habits.isEmpty {
                StatisticsEmptyStateView()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Overview Section
                        VStack(spacing: 16) {
                            OverviewStatsView(habits: habits)
                        }
                        .padding(.horizontal, 16)
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
        // 🔄 ИЗМЕНЕНО: NavigationLink вместо sheet
        .navigationDestination(item: $selectedHabitForStats) { habit in
            HabitStatisticsView(habit: habit)
        }
    }
}

// MARK: - Statistics Empty State (без изменений)

struct StatisticsEmptyStateView: View {
    @State private var isAnimating = false
    @ObservedObject private var colorManager = AppColorManager.shared
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: "chart.line.text.clipboard")
                .font(.system(size: 120, weight: .thin))
                .foregroundStyle(colorManager.selectedColor.color.opacity(0.3))
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                }
            
            Text("no_statistics_title".localized)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .padding(.top, 24)
            
            Text("no_statistics_description".localized)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 8)
            
            Spacer()
        }
    }
}
