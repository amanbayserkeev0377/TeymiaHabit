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
    @State private var showingReorderHabits = false
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
        ZStack {
            contentView
            fabButton
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text(navigationTitle)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                if !Calendar.current.isDateInToday(selectedDate) {
                    Button(action: {
                        selectedDate = Date()
                    }) {
                        HStack(spacing: 4) {
                            Text("today".localized)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(colorManager.selectedColor.color)
                            Image(systemName: "arrow.uturn.left")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(colorManager.selectedColor.color)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                    }
                    .buttonStyle(.plain)
                    .background(
                        Capsule()
                            .fill(colorManager.selectedColor.color.opacity(0.1))
                    )
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
        .sheet(isPresented: $showingReorderHabits) {
            ReorderHabitsView()
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
    
    // MARK: - View Components
    
    private var contentView: some View {
        VStack(spacing: 0) {
            if allBaseHabits.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        WeeklyCalendarView(selectedDate: $selectedDate)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        
                        if hasHabitsForDate {
                            LazyVStack(spacing: 14) {
                                ForEach(activeHabitsForDate) { habit in
                                    HabitCardView(
                                        habit: habit,
                                        date: selectedDate,
                                        viewModel: nil,
                                        onTap: {
                                            selectedHabit = habit
                                        },
                                        onEdit: { habitToEdit = habit },
                                        onArchive: { archiveHabit(habit) },
                                        onDelete: {
                                            habitForProgress = habit
                                            alertState.isDeleteAlertPresented = true
                                        },
                                        onReorder: {
                                            showingReorderHabits = true
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
    }
    
    private var fabButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button(action: {
                    HapticManager.shared.playSelection()
                    if !ProManager.shared.isPro && allBaseHabits.count >= 3 {
                        showingPaywall = true
                    } else {
                        showingNewHabit = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(colorManager.selectedColor.adaptiveGradient(for: colorScheme).opacity(0.2))
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(
                                Circle()
                                    .fill(colorManager.selectedColor.adaptiveGradient(for: colorScheme).opacity(0.8))
                                    .shadow(
                                        color: colorManager.selectedColor.color.opacity(0.2),
                                        radius: 8,
                                        x: 0,
                                        y: 6
                                    )
                            )
                    }
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
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
