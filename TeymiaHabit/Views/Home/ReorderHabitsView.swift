import SwiftUI
import SwiftData

struct ReorderHabitsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    @Query(
        filter: #Predicate<Habit> { habit in
            !habit.isArchived
        },
        sort: [SortDescriptor(\Habit.displayOrder), SortDescriptor(\Habit.createdAt)]
    )
    private var habits: [Habit]
    
    @State private var reorderedHabits: [Habit] = []
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(reorderedHabits, id: \.uuid) { habit in
                    ReorderHabitRow(habit: habit)
                }
                .onMove(perform: moveHabits)
            }
            .listStyle(.insetGrouped)
            .environment(\.editMode, .constant(.active))
            .navigationTitle("reorder".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("button_cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("button_save".localized) {
                        saveReorder()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            reorderedHabits = habits
        }
        .presentationDragIndicator(.visible)
    }
    
    private func moveHabits(from source: IndexSet, to destination: Int) {
        reorderedHabits.move(fromOffsets: source, toOffset: destination)
        HapticManager.shared.playSelection()
    }
    
    private func saveReorder() {
        for (index, habit) in reorderedHabits.enumerated() {
            habit.displayOrder = index
        }
        
        do {
            try modelContext.save()
            HapticManager.shared.play(.success)
        } catch {
            HapticManager.shared.play(.error)
        }
    }
}

// MARK: - Reorder Habit Row

struct ReorderHabitRow: View {
    let habit: Habit
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
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
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text("goal".localized(with: habit.formattedGoal))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
