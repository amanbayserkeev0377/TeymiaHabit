import SwiftUI
import SwiftData

struct HabitListRow: View {
    @Environment(TimerService.self) private var timerService
    @Environment(HabitsViewModel.self) private var vm
    
    let habit: Habit
    let date: Date
    
    // MARK: - Computer Properties
    
    private var isTimerActive: Bool {
        guard habit.modelContext != nil,
              habit.type == .time,
              Calendar.current.isDateInToday(date) else { return false }
        
        return timerService.isTimerRunning(for: habit.uuid.uuidString)
    }
    
    private var cardProgress: Int {
        guard habit.modelContext != nil else { return 0 }
        if let tempValue = vm.temporaryProgress[habit.uuid] {
            return tempValue
        }
        
        _ = timerService.updateTrigger
        
        if isTimerActive {
            return timerService.getLiveProgress(for: habit.uuid.uuidString) ?? habit.progressForDate(date)
        }
        
        return habit.progressForDate(date)
    }
    
    private var cardCompletionPercentage: Double {
        guard habit.goal > 0 else { return 0 }
        return Double(cardProgress) / Double(habit.goal)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            HabitIconView(iconName: habit.iconName, color: habit.actualColor)
            
            // Title + Progress
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.headline)
                
                Text("\(habit.formatProgress(cardProgress)) / \(habit.formattedGoal)")
                    .font(.subheadline)
            }
            .foregroundStyle(.primary)
            .lineLimit(1)
            
            Spacer()
            
            // Interactive Progress Ring
            Button(action: {
                vm.handleRingTap(on: habit, date: date)
            }) {
                ProgressRing(
                    progress: cardCompletionPercentage,
                    currentValue: "",
                    isCompleted: cardProgress >= habit.goal,
                    isExceeded: cardProgress > habit.goal,
                    habit: habit,
                    size: 50,
                    isTimerRunning: isTimerActive
                )
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.md)
        .onChange(of: timerService.updateTrigger) { _, _ in
            if isTimerActive {
                vm.checkCompletionForActiveTimer(habit, date: date)
            }
        }
    }
}
    
    // MARK: - Habit Card
    
    struct HabitCard: View {
        @Environment(HabitsViewModel.self) private var vm
        
        let habit: Habit
        let date: Date
        var onEdit: () -> Void
        
        @State private var showDeleteAlert = false
        
        private var isSkipped: Bool { habit.isSkipped(on: date) }
        
        var body: some View {
            HabitListRow(habit: habit, date: date)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: Radius.xl))
                .contentShape(.rect(cornerRadius: Radius.xl))
                .contentShape(.contextMenuPreview, .capsule)
                .contentShape(.dragPreview, .capsule)
                .contentShape(.hoverEffect, .capsule)
                .contextMenu {
                    skipButton
                    editButton
                    archiveButton
                    Divider()
                    deleteButton
                }
                .deleteSingleHabitAlert(
                    isPresented: $showDeleteAlert,
                    habitName: habit.title,
                    onDelete: { vm.deleteHabit(habit) },
                )
        }
        
        // MARK: - Context Menu Buttons
        
        private var skipButton: some View {
            Button { vm.toggleSkip(for: habit, date: date) } label: {
                Label(
                    isSkipped ? "unskip" : "skip",
                    systemImage: isSkipped ? "arrow.left" : "arrow.right"
                )
            }
            .tint(.primary)
        }
        
        private var editButton: some View {
            Button { onEdit() } label: {
                Label("button_edit", systemImage: "pencil")
            }
            .tint(.primary)
        }
        
        private var archiveButton: some View {
            Button { vm.archiveHabit(habit) } label: {
                Label("archive", systemImage: "archivebox")
            }
            .tint(.primary)
        }
        
        private var deleteButton: some View {
            Button(role: .destructive) { showDeleteAlert = true } label: {
                Label("button_delete", systemImage: "trash")
            }
            .tint(.red)
        }
    }
