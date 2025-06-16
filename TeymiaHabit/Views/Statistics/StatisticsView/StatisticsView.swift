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
    
    @State private var selectedTimeRange: OverviewTimeRange = .week
    @State private var selectedHabitForStats: Habit? = nil
    
    var body: some View {
        NavigationStack {
            if habits.isEmpty {
                StatisticsEmptyStateView()
            } else {
                List {
                    // Overview Section
                    Section {
                        VStack(spacing: 16) {
                            if selectedTimeRange == .heatmap {
                                OverviewHeatmapView(habits: habits)
                            } else {
                                Text("Overview Coming Soon")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 32)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.quaternary)
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .listRowSeparator(.hidden)
                    
                    // Habits Charts Section
                    Section("Your Habits") {
                        if selectedTimeRange == .heatmap {
                            ForEach(habits) { habit in
                                HabitHeatmapCard(habit: habit, onTap: {
                                    selectedHabitForStats = habit
                                })
                            }
                        } else {
                            ForEach(habits) { habit in
                                HabitLineChartCard(
                                    habit: habit, 
                                    timeRange: selectedTimeRange,
                                    onTap: {
                                        selectedHabitForStats = habit
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("statistics".localized)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if !habits.isEmpty {
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(OverviewTimeRange.allCases, id: \.self) { range in
                            if range.isIcon {
                                Image(systemName: range.localized).tag(range)
                            } else {
                                Text(range.localized).tag(range)
                            }
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
            }
        }
        .sheet(item: $selectedHabitForStats) { habit in
            NavigationStack {
                HabitStatisticsView(habit: habit)
            }
            .presentationDragIndicator(.visible)
        }
    }
}

// ===== Empty State =====

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
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
}
