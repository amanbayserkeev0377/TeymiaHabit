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
        .scrollContentBackground(.hidden)
        .background(Color.mainGroupBackground)
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
            Section {
                HStack {
                    Spacer()
                    
                    Image("archive.fill")
                        .resizable()
                        .foregroundStyle(.gray.gradient)
                        .frame(
                            width: UIScreen.main.bounds.width * 0.25,
                            height: UIScreen.main.bounds.width * 0.25
                        )
                    
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } else {
            Section(
                footer: Text("archived_habits_footer".localized)
                    .font(.footnote)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            ) {
                ForEach(archivedHabits) { habit in
                    archivedHabitRow(habit)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                habitToDelete = habit
                                isDeleteSingleAlertPresented = true
                            } label: {
                                Image("trash.swipe")
                            }
                            .tint(.red)
                            
                            Button {
                                unarchiveHabit(habit)
                            } label: {
                                Image("unarchive.swipe")
                            }
                            .tint(.gray)
                        }
                }
            }
            .listRowBackground(Color.mainRowBackground)
        }
    }
    
    @ViewBuilder
    private func archivedHabitRow(_ habit: Habit) -> some View {
        Button {
            selectedHabitForStats = habit
        } label: {
            HStack(spacing: 12) {
                HabitIconView(
                    iconName: habit.iconName,
                    color: habit.iconColor
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.title)
                        .fontWeight(.medium)
                        .fontDesign(.rounded)
                        .lineLimit(1)
                        .foregroundStyle(Color(UIColor.label))
                    
                    Text("goal".localized(with: habit.formattedGoal))
                        .font(.caption)
                        .fontDesign(.rounded)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                }
            }
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
