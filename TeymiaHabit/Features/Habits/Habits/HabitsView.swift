import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    
    @Query(
        filter: #Predicate<Habit> { habit in
            !habit.isArchived
        },
        sort: [SortDescriptor(\Habit.displayOrder), SortDescriptor(\Habit.createdAt)]
    )
    private var allBaseHabits: [Habit]

    @Binding var selectedDate: Date
    @Binding var selectedHabit: Habit?
    
    @State private var showingNewHabit = false
    @State private var showingPaywall = false
    @State private var habitToEdit: Habit? = nil
    @State private var alertState = AlertState()
    @State private var habitForProgress: Habit? = nil
    @State private var isEditMode: EditMode = .inactive
    
    private var baseHabits: [Habit] {
        allBaseHabits.sorted { first, second in
            if first.displayOrder != second.displayOrder {
                return first.displayOrder < second.displayOrder
            }
            return first.createdAt < second.createdAt
        }
    }
    
    private var activeHabitsForDate: [Habit] {
        allBaseHabits.filter { habit in
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
                ContentUnavailableView(
                    label: {
                        Label(
                            title: {
                                Text("no_habits")
                                    .foregroundStyle(Color.primary.gradient)
                                    .padding(.bottom, 40)
                            },
                            icon: {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(Color.primary.gradient)
                            }
                        )
                    },
                    actions: {
                        Button(action: {
                            showingNewHabit = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("create_habit")
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primaryInverse)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.tint(.primary).interactive(), in: .capsule)
                    }
                )
            } else {
                // Habits List
                if hasHabitsForDate {
                    List {
                        Section {
                            WeeklyCalendarView(selectedDate: $selectedDate)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        
                        ForEach(activeHabitsForDate) { habit in
                            HabitCard(
                                habit: habit,
                                date: selectedDate,
                                onToggleCompletion: { toggleHabitCompletion(habit) }
                            )
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparatorTint(Color.secondary.opacity(0.1))
                            .opacity(habit.isSkipped(on: selectedDate) ? 0.4 : 1.0)
                            .onTapGesture {
                                HapticManager.shared.playSelection()
                                selectedHabit = habit
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                let isCompleted = habit.progressForDate(selectedDate) >= habit.goal
                                Button {
                                    toggleHabitCompletion(habit)
                                } label: {
                                    Label("", systemImage: isCompleted ? "arrow.uturn.backward" : "checkmark")
                                }
                                .tint(isCompleted ? .red : .green)
                                
                                let isSkipped = habit.isSkipped(on: selectedDate)
                                Button {
                                    toggleSkip(for: habit)
                                } label: {
                                    Label("", systemImage: isSkipped ? "arrow.left" : "arrow.right")
                                }
                                .tint(.gray)
                            }
                        }
                        .onMove(perform: moveHabits)
                    }
                    .listStyle(.plain)
                    .scrollIndicators(.hidden)
                    .frame(maxWidth: 700)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .environment(\.editMode, $isEditMode)
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !allBaseHabits.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        withAnimation {
                            isEditMode = isEditMode == .active ? .inactive : .active
                        }
                        HapticManager.shared.playSelection()
                    }) {
                        Image(systemName: isEditMode == .active ? "checkmark" : "line.3.horizontal")
                            .foregroundStyle(Color.primary)
                    }
                }
            }
            
            if !Calendar.current.isDateInToday(selectedDate) {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        selectedDate = Date()
                    }) {
                        Image(systemName: "arrowshape.turn.up.left")
                            .foregroundStyle(Color.primary)
                    }
                }
            }
            
            ToolbarSpacer(.flexible, placement: .topBarTrailing)
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    HapticManager.shared.playSelection()
                    if !ProManager.shared.isPro && allBaseHabits.count >= 3 {
                        showingPaywall = true
                    } else {
                        showingNewHabit = true
                    }
                }) {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.primary)
                }
            }
        }
        .sheet(isPresented: $showingNewHabit) {
            NewHabitView()
                .presentationSizing(.page)
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(item: $habitToEdit) { habit in
            NewHabitView(habit: habit)
                .presentationSizing(.page)
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
    
    @MainActor
    private func toggleHabitCompletion(_ habit: Habit) {
        let currentProgress = habit.progressForDate(selectedDate)
        let isCompleted = currentProgress >= habit.goal
        
        if habit.isSkipped(on: selectedDate) {
            habit.unskipDate(selectedDate, modelContext: modelContext)
        }
        
        if isCompleted {
            habit.updateProgress(to: 0, for: selectedDate, modelContext: modelContext)
        } else {
            habit.updateProgress(to: habit.goal, for: selectedDate, modelContext: modelContext)
            SoundManager.shared.playCompletionSound()
        }
        
        try? modelContext.save()
        
        HapticManager.shared.play(.success)
        WidgetUpdateService.shared.reloadWidgets()
    }
    
    // MARK: - Helper Methods
    
    private func formattedNavigationTitle(for date: Date) -> String {
        if isToday(date) {
            return "today".capitalized
        } else if isYesterday(date) {
            return "yesterday".capitalized
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMMM"
            return formatter.string(from: date).capitalized
        }
    }
    
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private func isYesterday(_ date: Date) -> Bool {
        Calendar.current.isDateInYesterday(date)
    }
    
    private func toggleSkip(for habit: Habit) {
        let isSkipped = habit.isSkipped(on: selectedDate)
        if isSkipped {
            habit.unskipDate(selectedDate, modelContext: modelContext)
        } else {
            habit.skipDate(selectedDate, modelContext: modelContext)
        }
        HapticManager.shared.play(.success)
        WidgetUpdateService.shared.reloadWidgets()
    }
    
    private func deleteHabit(_ habit: Habit) {
        if selectedHabit?.persistentModelID == habit.persistentModelID {
            selectedHabit = nil
        }
        
        withAnimation {
            HabitService.shared.delete(habit, context: modelContext)
        }
        
        WidgetUpdateService.shared.reloadWidgets()
    }
    
    private func archiveHabit(_ habit: Habit) {
        habit.isArchived = true
        try? modelContext.save()
        HapticManager.shared.play(.success)
        WidgetUpdateService.shared.reloadWidgets()
    }
    
    // MARK: - Reordering
    
    private func moveHabits(from source: IndexSet, to destination: Int) {
        var updatedAllHabits = allBaseHabits
        let habitsToMove = source.map { activeHabitsForDate[$0] }
        let targetIndex: Int
        if destination < activeHabitsForDate.count {
            let targetHabit = activeHabitsForDate[destination]
            targetIndex = updatedAllHabits.firstIndex(of: targetHabit) ?? updatedAllHabits.count
        } else {
            if let lastVisible = activeHabitsForDate.last,
               let lastIndexInAll = updatedAllHabits.firstIndex(of: lastVisible) {
                targetIndex = lastIndexInAll + 1
            } else {
                targetIndex = updatedAllHabits.count
            }
        }
        
        let sourceIndices = IndexSet(habitsToMove.compactMap { updatedAllHabits.firstIndex(of: $0) })
        
        updatedAllHabits.move(fromOffsets: sourceIndices, toOffset: targetIndex)
        
        for (index, habit) in updatedAllHabits.enumerated() {
            habit.displayOrder = index
        }
        
        try? modelContext.save()
    }
}

// MARK: - Habit Card Component

struct HabitCard: View {
    let habit: Habit
    let date: Date
    let onToggleCompletion: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @State private var isEditPresented = false
    @State private var showDeleteAlert = false
    
    private var isCompleted: Bool {
        guard habit.modelContext != nil else { return false }
        return habit.progressForDate(date) >= habit.goal
    }
    
    private var isSkipped: Bool {
        guard habit.modelContext != nil else { return false }
        return habit.isSkipped(on: date)
    }
    
    var body: some View {
        if habit.modelContext == nil {
            EmptyView()
        } else {
            HStack {
                HabitListRow(
                    habit: habit,
                    date: date,
                    viewModel: nil
                )
                .padding(6)
            }
            .contextMenu {
                skipButton
                editButton
                archiveButton
                Divider()
                deleteButton
            }
            .sheet(isPresented: $isEditPresented) {
                NewHabitView(habit: habit)
            }
            .deleteSingleHabitAlert(
                isPresented: $showDeleteAlert,
                habitName: habit.title,
                onDelete: deleteHabit,
                habit: habit
            )
        }
    }
    
    // MARK: - Context Menu Buttons
    
    private var skipButton: some View {
        Button {
            toggleSkip()
        } label: {
            Label(
                isSkipped ? "unskip" : "skip",
                systemImage: isSkipped ? "arrow.left" : "arrow.right"
            )
        }
        .tint(.primary)
    }
    
    private var editButton: some View {
        Button {
            isEditPresented = true
        } label: {
            Label("button_edit", systemImage: "pencil")
        }
        .tint(.primary)
        
    }
    
    private var archiveButton: some View {
        Button {
            archiveHabit()
        } label: {
            Label("archive", systemImage: "archivebox")
        }
        .tint(.primary)
    }
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteAlert = true
        } label: {
            Label("button_delete", systemImage: "trash")
        }
        .tint(.red)
    }
    
    // MARK: - Actions
    
    private func toggleSkip() {
        if isSkipped {
            habit.unskipDate(date, modelContext: modelContext)
        } else {
            habit.skipDate(date, modelContext: modelContext)
        }
        HapticManager.shared.play(.success)
        WidgetUpdateService.shared.reloadWidgets()
    }
    
    private func archiveHabit() {
        HabitService.shared.archive(habit, context: modelContext)
    }
    
    private func deleteHabit() {
        HabitService.shared.delete(habit, context: modelContext)
    }
}
