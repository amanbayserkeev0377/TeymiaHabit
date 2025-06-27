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
                    VStack(spacing: 0) {
                        // Overview Section
                        VStack(spacing: 16) {
                            OverviewStatsView(habits: habits)
                        }
                        .padding(.horizontal, 0)
                        .padding(.vertical, 16)
                        // 🔥 НОВЫЙ: Habits List вместо charts
                        LazyVStack(spacing: 12) {
                            ForEach(habits) { habit in
                                HabitStatsListCard(habit: habit) {
                                    selectedHabitForStats = habit
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.horizontal, 0)
                        Spacer(minLength: 20)
                    }
                }
            }
        }
        .navigationTitle("statistics".localized)
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedHabitForStats) { habit in
            NavigationStack {
                HabitStatisticsView(habit: habit)
            }
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Statistics Empty State

struct StatisticsEmptyStateView: View {
    @State private var isAnimating = false
    @ObservedObject private var colorManager = AppColorManager.shared
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: "chart.line.text.clipboard")
                .font(.system(size: 120, weight: .thin))
                .foregroundStyle(colorManager.selectedColor.color.opacity(0.3))
                .scaleEffect(isAnimating ? 1.05 : 0.98)
                .animation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
            
            VStack(spacing: 8) {
                Text("No Statistics Yet")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text("Create your first habit to see beautiful charts and insights")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct HabitStatsListCard: View {
    let habit: Habit
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Иконка привычки
                if let iconName = habit.iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 24))
                        .foregroundStyle(habit.iconColor.color)
                        .frame(width: 44, height: 44)
                        .background(habit.iconColor.color.opacity(0.1))
                        .clipShape(Circle())
                }
                
                // Информация о привычке
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(habit.formattedGoal)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Прогресс сегодня
                    HStack(spacing: 4) {
                        if habit.isCompletedForDate(Date()) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(.gray)
                                .font(.caption)
                        }
                        
                        Text("today".localized)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // 🔥 УПРОЩЕНО: Считаем streaks напрямую от habit
                VStack(alignment: .trailing, spacing: 8) {
                    // Current Streak
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(currentStreak)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(habit.iconColor.color)
                        
                        Text("current".localized)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Best Streak
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(bestStreak)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Text("best".localized)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 🔥 ДОБАВИТЬ простые computed properties:
    private var currentStreak: Int {
        // Простая логика streak - можно упростить или использовать существующий метод
        return 5 // Placeholder - замените на реальную логику
    }
    
    private var bestStreak: Int {
        // Простая логика best streak
        return 12 // Placeholder - замените на реальную логику
    }
}
