import SwiftUI
import SwiftData

struct ArchivedHabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var colorManager = AppColorManager.shared
    
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
        .navigationBarTitleDisplayMode(.inline)
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
            HabitStatisticsView(habit: habit)
        }
    }
    
    // MARK: - Private Methods
    
    @ViewBuilder
    private var listContent: some View {
        if archivedHabits.isEmpty {
            VStack {
                Spacer()
                
                Image("3d_archive")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIScreen.main.bounds.width * 0.45,
                           height: UIScreen.main.bounds.width * 0.45)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } else {
            Section(
                footer: Text("archived_habits_footer".localized)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            ) {
                ForEach(archivedHabits) { habit in
                    archivedHabitRow(habit)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                habitToDelete = habit
                                isDeleteSingleAlertPresented = true
                            } label: {
                                Label("button_delete".localized, systemImage: "trash")
                            }
                            .tint(.red)
                            
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
    
    @ViewBuilder
    private func archivedHabitRow(_ habit: Habit) -> some View {
        Button {
            selectedHabitForStats = habit
        } label: {
            HStack(spacing: 12) {
                universalIcon(
                    iconId: habit.iconName,
                    baseSize: 24,
                    color: habit.iconColor,
                    colorScheme: colorScheme
                )
                .frame(width: 36, height: 36)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(UIColor.label))
                        .lineLimit(1)
                    
                    Text("goal".localized(with: habit.formattedGoal))
                        .font(.caption)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color(uiColor: .systemGray3))
                    .font(.footnote)
                    .fontWeight(.bold)
            }
            .padding(.vertical, 2)
        }
    }
    
    private func unarchiveHabit(_ habit: Habit) {
        habit.isArchived = false
        try? modelContext.save()
        HapticManager.shared.play(.success)
    }
    
    private func deleteHabit(_ habit: Habit) {
        NotificationManager.shared.cancelNotifications(for: habit)
        modelContext.delete(habit)
        try? modelContext.save()
        HapticManager.shared.play(.error)
    }
}

// MARK: - Badge Component

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
