import SwiftUI
import SwiftData

struct ArchiveView: View {
    // MARK: - Dependencies
    @Environment(\.modelContext) private var modelContext
    @Environment(AppDependencyContainer.self) private var appContainer
    
    // MARK: - Data
    @Query(
        filter: #Predicate<Habit> { habit in
            habit.isArchived
        },
        sort: [SortDescriptor(\Habit.createdAt, order: .reverse)]
    )
    private var archivedHabits: [Habit]
    
    // MARK: - State
    @State private var habitToDelete: Habit? = nil
    @State private var isDeleteSingleAlertPresented = false
    
    var body: some View {
        Form {
            listContent
        }
        .formStyle(.grouped)
        .navigationTitle("settings_archived_habits")
        .deleteSingleHabitAlert(
            isPresented: $isDeleteSingleAlertPresented,
            habitName: habitToDelete?.title ?? "",
            onDelete: {
                if let habit = habitToDelete {
                    deleteHabit(habit)
                }
                habitToDelete = nil
            }
        )
    }
    
    // MARK: - View Sections
    
    @ViewBuilder
    private var listContent: some View {
        if archivedHabits.isEmpty {
            Section {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                    Text("No archived habits")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)
        } else {
            Section {
                ForEach(archivedHabits) { habit in
                    archivedHabitRow(habit)
                }
            }
        }
    }
    
    @ViewBuilder
    private func archivedHabitRow(_ habit: Habit) -> some View {
        HStack(spacing: 12) {
            HabitIconView(iconName: habit.iconName, color: habit.actualColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.title)
                    .lineLimit(1)
                    .foregroundStyle(Color.primary)
                
                Text("goal \(habit.formattedGoal)")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            
            Spacer()
            
            unarchiveButton(for: habit)
            deleteButton(for: habit)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func unarchiveButton(for habit: Habit) -> some View {
        Button {
            unarchiveHabit(habit)
        } label: {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .resizable()
                .frame(width: 28, height: 28)
                .foregroundStyle(.blue.gradient)
                .padding(4)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func deleteButton(for habit: Habit) -> some View {
        Button {
            habitToDelete = habit
            isDeleteSingleAlertPresented = true
        } label: {
            Image(systemName: "trash.circle.fill")
                .resizable()
                .frame(width: 28, height: 28)
                .foregroundStyle(.red.gradient)
                .padding(4)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Private Methods
    
    private func unarchiveHabit(_ habit: Habit) {
        appContainer.habitService.unarchive(habit)
    }
    
    private func deleteHabit(_ habit: Habit) {
        appContainer.habitService.delete(habit)
    }
}
