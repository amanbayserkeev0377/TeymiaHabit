import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var colorManager = AppColorManager.shared
    
    @Query(
        filter: #Predicate<Habit> { habit in
            !habit.isArchived
        },
        sort: [SortDescriptor(\Habit.displayOrder), SortDescriptor(\Habit.createdAt)]
    )
    private var allBaseHabits: [Habit]
    
    @State private var selectedDate: Date = .now
    @State private var showingNewHabit = false
    @State private var showingPaywall = false
    @State private var selectedHabit: Habit? = nil
    @State private var habitToEdit: Habit? = nil
    @State private var alertState = AlertState()
    @State private var habitForProgress: Habit? = nil
    
    private var baseHabits: [Habit] {
        allBaseHabits.sorted { first, second in
            if first.displayOrder != second.displayOrder {
                return first.displayOrder < second.displayOrder
            }
            return first.createdAt < second.createdAt
        }
    }
    
    private var activeHabitsForDate: [Habit] {
        baseHabits.filter { habit in
            habit.isActiveOnDate(selectedDate) &&
            selectedDate >= habit.startDate
        }
    }
    
    private var hasHabitsForDate: Bool {
        !activeHabitsForDate.isEmpty
    }
    
    private var navigationTitle: String {
        if allBaseHabits.isEmpty {
            return ""
        }
        return formattedNavigationTitle(for: selectedDate)
    }
    
    var body: some View {
        Group {
            if allBaseHabits.isEmpty {
                EmptyStateView()
            } else {
                List {
                    // Calendar section
                    Section {
                        WeeklyCalendarView(selectedDate: $selectedDate)
                            .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    
                    // Habits section
                    if hasHabitsForDate {
                        Section {
                            ForEach(activeHabitsForDate) { habit in
                                Button(action: {
                                    HapticManager.shared.playSelection()
                                    selectedHabit = habit
                                }) {
                                    HabitListRow(
                                        habit: habit,
                                        date: selectedDate,
                                        viewModel: nil
                                    )
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button {
                                        toggleHabitCompletion(habit)
                                    } label: {
                                        Image(systemName: habit.progressForDate(selectedDate) >= habit.goal ? "xmark" : "checkmark")
                                    }
                                    .tint(habit.progressForDate(selectedDate) >= habit.goal ? .orange : .green)
                                }
                            }
                            .onMove(perform: moveHabits)
                        }
                    }
                }
                .listStyle(.plain)
                .environment(\.defaultMinListRowHeight, 56)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text(navigationTitle)
                    .fontWeight(.medium)
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: true, vertical: false)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    // Back to today button
                    if !Calendar.current.isDateInToday(selectedDate) {
                        Button(action: {
                            selectedDate = Date()
                        }) {
                            Image(systemName: "arrowshape.turn.up.left")
                                .font(.body.weight(.medium))
                                .foregroundStyle(colorManager.selectedColor.color)
                        }
                    }
                    
                    // Add button
                    Button(action: {
                        HapticManager.shared.playSelection()
                        if !ProManager.shared.isPro && allBaseHabits.count >= 3 {
                            showingPaywall = true
                        } else {
                            showingNewHabit = true
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(colorManager.selectedColor.color)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openHabitFromDeeplink)) { notification in
            if let habit = notification.object as? Habit {
                if selectedHabit?.uuid == habit.uuid {
                    return
                }
                
                selectedHabit = nil
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedHabit = habit
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissAllSheets)) { _ in
            selectedHabit = nil
        }
        .sheet(item: $selectedHabit) { habit in
            NavigationStack {
                HabitDetailView(
                    habit: habit,
                    date: selectedDate
                )
            }
            .presentationDragIndicator(.visible)
            .presentationDetents([.fraction(0.98)])
        }
        .sheet(isPresented: $showingNewHabit) {
            NavigationStack {
                CreateHabitView()
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(item: $habitToEdit) { habit in
            NewHabitView(habit: habit)
        }
        .deleteSingleHabitAlert(
            isPresented: Binding(
                get: { alertState.isDeleteAlertPresented && habitForProgress != nil },
                set: { if !$0 { alertState.isDeleteAlertPresented = false } }
            ),
            habitName: habitForProgress?.title ?? "",
            onDelete: {
                if let habit = habitForProgress {
                    deleteHabit(habit)
                }
                habitForProgress = nil
            },
            habit: habitForProgress
        )
    }
    
    // MARK: - List Actions
    
    private func toggleHabitCompletion(_ habit: Habit) {
        guard let viewModel = try? HabitManager.shared.getViewModel(for: habit, date: selectedDate, modelContext: modelContext) else {
            return
        }
        
        let isCompleted = habit.progressForDate(selectedDate) >= habit.goal
        
        if isCompleted {
            viewModel.resetProgress()
        } else {
            viewModel.completeHabit()
            SoundManager.shared.playCompletionSound()
        }
        
        HapticManager.shared.play(.success)
        WidgetUpdateService.shared.reloadWidgets()
    }
    
    private func moveHabits(from source: IndexSet, to destination: Int) {
        var updatedHabits = activeHabitsForDate
        updatedHabits.move(fromOffsets: source, toOffset: destination)
        
        // Update display order
        for (index, habit) in updatedHabits.enumerated() {
            habit.displayOrder = index
        }
        
        try? modelContext.save()
        HapticManager.shared.playSelection()
    }
    
    // MARK: - Helper Methods
    
    private func formattedNavigationTitle(for date: Date) -> String {
        if isToday(date) {
            return "today".localized.capitalized
        } else if isYesterday(date) {
            return "yesterday".localized.capitalized
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, d MMM"
            return formatter.string(from: date).capitalized
        }
    }
    
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private func isYesterday(_ date: Date) -> Bool {
        Calendar.current.isDateInYesterday(date)
    }
    
    private func deleteHabit(_ habit: Habit) {
        NotificationManager.shared.cancelNotifications(for: habit)
        modelContext.delete(habit)
        do {
            try modelContext.save()
            HabitManager.shared.removeViewModel(for: habit.uuid.uuidString)
            HapticManager.shared.play(.error)
            WidgetUpdateService.shared.reloadWidgets()
        } catch {
            HapticManager.shared.play(.error)
        }
    }
    
    private func archiveHabit(_ habit: Habit) {
        habit.isArchived = true
        try? modelContext.save()
        HapticManager.shared.play(.success)
        WidgetUpdateService.shared.reloadWidgets()
    }
}
