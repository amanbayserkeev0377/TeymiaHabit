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
    
    @Namespace private var namespace
    
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
        ZStack {
            Color.mainBackground
                .ignoresSafeArea()
            
            Group {
                if allBaseHabits.isEmpty {
                    EmptyStateView(onCreateHabit: {
                        showingNewHabit = true
                    })
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Calendar section
                            WeeklyCalendarView(selectedDate: $selectedDate)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                            
                            // Habits section
                            if hasHabitsForDate {
                                LazyVStack(spacing: 12) {
                                    ForEach(activeHabitsForDate) { habit in
                                        HabitCard(
                                            habit: habit,
                                            date: selectedDate,
                                            onTap: {
                                                HapticManager.shared.playSelection()
                                                selectedHabit = habit
                                            },
                                            onToggleCompletion: {
                                                toggleHabitCompletion(habit)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !allBaseHabits.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Text(navigationTitle)
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: true, vertical: false)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if !Calendar.current.isDateInToday(selectedDate) {
                            Button(action: {
                                selectedDate = Date()
                            }) {
                                Image(systemName: "arrowshape.turn.up.left")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(colorManager.selectedColor.color)
                            }
                        }
                        
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
            .presentationCornerRadius(30)
            .presentationDetents([detendForCurrentDevice])
        }
        .sheet(isPresented: $showingNewHabit) {
            NewHabitView()
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

// MARK: - Helper Properties

private var detendForCurrentDevice: PresentationDetent {
    let screenHeight = UIScreen.main.bounds.height
    
    if screenHeight <= 667 {
        return .fraction(0.8)
    }
    
    else if screenHeight <= 812 {
        return .fraction(0.7)
    }
    
    else {
        return .fraction(0.6)
    }
}

// MARK: - Habit Card Component

struct HabitCard: View {
    let habit: Habit
    let date: Date
    let onTap: () -> Void
    let onToggleCompletion: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    
    private var isCompleted: Bool {
        habit.progressForDate(date) >= habit.goal
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                HabitListRow(
                    habit: habit,
                    date: date,
                    viewModel: nil
                )
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.mainRowBackground)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}
