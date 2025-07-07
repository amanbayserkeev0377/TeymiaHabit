import SwiftUI
import SwiftData

struct ArchivedHabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var colorManager = AppColorManager.shared
    
    // Query only archived habits
    @Query(
        filter: #Predicate<Habit> { habit in
            habit.isArchived
        },
        sort: [SortDescriptor(\Habit.createdAt, order: .reverse)]
    )
    private var archivedHabits: [Habit]
    
    @State private var selectedHabitForStats: Habit? = nil
    @State private var habitToDelete: Habit? = nil
    @State private var isDeleteSingleAlertPresented = false
    
    var body: some View {
        List {
            listContent
        }
        .listStyle(.insetGrouped)
        .navigationTitle("archived_habits".localized)
        .navigationBarTitleDisplayMode(.large)
        .deleteSingleHabitAlert(
            isPresented: $isDeleteSingleAlertPresented,
            habitName: habitToDelete?.title ?? "",
            onDelete: {
                if let habit = habitToDelete {
                    deleteHabit(habit)
                }
                habitToDelete = nil
            },
            habit: habitToDelete
        )
        .sheet(item: $selectedHabitForStats) { habit in
            NavigationStack {
                HabitStatisticsView(habit: habit)
            }
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - List Content
    @ViewBuilder
    private var listContent: some View {
        if archivedHabits.isEmpty {
            ContentUnavailableView(
                "no_archived_habits".localized,
                systemImage: "archivebox"
            )
            .listRowBackground(Color.clear)
        } else {
            // Footer с подсказкой о swipe actions
            Section(
                footer: Text("archived_habits_footer".localized)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            ) {
                ForEach(archivedHabits) { habit in
                    archivedHabitRow(habit)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            // Delete action (red)
                            Button(role: .destructive) {
                                habitToDelete = habit
                                isDeleteSingleAlertPresented = true
                            } label: {
                                Label("button_delete".localized, systemImage: "trash")
                            }
                            .tint(.red)
                            
                            // Unarchive action (cyan)
                            Button {
                                unarchiveHabit(habit)
                            } label: {
                                Label("unarchive".localized, systemImage: "tray.and.arrow.up")
                            }
                            .tint(.cyan)
                        }
                }
            }
        }
    }
    
    // MARK: - Archived Habit Row
    @ViewBuilder
    private func archivedHabitRow(_ habit: Habit) -> some View {
        Button {
            selectedHabitForStats = habit
        } label: {
            HStack {
                // Icon слева
                let iconName = habit.iconName ?? "checkmark"
                
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .frame(width: 24, height: 24)
                    .foregroundStyle(habit.iconName == nil ? colorManager.selectedColor.color : habit.iconColor.color)
                
                // Название привычки (одна строка)
                Text(habit.title)
                    .tint(.primary)
                
                Spacer()
                
                // Chevron для показа что можно нажать (как в StatisticsView)
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color(uiColor: .systemGray3))
                    .font(.footnote)
                    .fontWeight(.bold)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func unarchiveHabit(_ habit: Habit) {
        habit.isArchived = false
        try? modelContext.save()
        HapticManager.shared.play(.success)
    }
    
    private func deleteHabit(_ habit: Habit) {
        // Cancel notifications
        NotificationManager.shared.cancelNotifications(for: habit)
        
        // Delete from model context
        modelContext.delete(habit)
        
        try? modelContext.save()
        HapticManager.shared.play(.error)
    }
}

// MARK: - Archived Habits Count Badge

struct ArchivedHabitsCountBadge: View {
    @Query(
        filter: #Predicate<Habit> { habit in
            habit.isArchived
        }
    )
    private var archivedHabits: [Habit]
    
    var body: some View {
        if !archivedHabits.isEmpty {
            Text("\(archivedHabits.count)")
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
        }
    }
}
