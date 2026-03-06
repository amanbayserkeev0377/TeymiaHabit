import SwiftUI
import SwiftData

struct ArchiveRowView: View {
    var body: some View {
        NavigationLink(destination: ArchiveView()) {
            Label(
                title: { Text("settings_archived_habits") },
                icon: { Image(systemName: "arrow.up.trash").iconStyle() }
            )
        }
    }
}

struct ArchiveView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(
        filter: #Predicate<Habit> { habit in
            habit.isArchived
        },
        sort: [SortDescriptor(\Habit.createdAt, order: .reverse)]
    )
    private var archivedHabits: [Habit]
    
    @State private var habitToDelete: Habit? = nil
    @State private var isDeleteSingleAlertPresented = false
    
    var body: some View {
        List {
            listContent
        }
        .appBackground()
        .navigationTitle("settings_archived_habits")
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
    }
    
    // MARK: - Private Methods
    
    @ViewBuilder
    private var listContent: some View {
        if archivedHabits.isEmpty {
            Section {
                HStack {
                    Spacer()
                    
                    Image("ui-box.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundStyle(.gray.gradient)
                    
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } else {
            Section {
                ForEach(archivedHabits) { habit in
                    archivedHabitRow(habit)
                }
            }
            .listRowBackground(Color.rowBackground)
        }
    }
    
    @ViewBuilder
    private func archivedHabitRow(_ habit: Habit) -> some View {
        HStack(spacing: 12) {
            HabitIconView(iconName: habit.iconName, iconColor: habit.iconColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.title)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundStyle(Color.primary)
                
                Text("goal \(habit.formattedGoal)")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            Spacer()
            
            deleteButton(for: habit)
            unarchiveButton(for: habit)
            
        }
    }
    
    @ViewBuilder
    private func deleteButton(for habit: Habit) -> some View {
        Button {
            unarchiveHabit(habit)
        } label: {
            Image("ui-trash.restore")
                .resizable()
                .frame(width: 20, height: 20)
                .padding(8)
                .background(
                    Circle()
                        .fill(Color.secondary.opacity(0.1))
                )
        }
    }
    
    @ViewBuilder
    private func unarchiveButton(for habit: Habit) -> some View {
        Button {
            habitToDelete = habit
            isDeleteSingleAlertPresented = true
        } label: {
            Image("ui-trash")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(.red.gradient)
                .padding(8)
                .background(
                    Circle()
                        .fill(Color.secondary.opacity(0.1))
                )
        }
    }
    
    private func unarchiveHabit(_ habit: Habit) {
        HabitService.shared.unarchive(habit, context: modelContext)
    }
    
    private func deleteHabit(_ habit: Habit) {
        HabitService.shared.delete(habit, context: modelContext)
    }
}
