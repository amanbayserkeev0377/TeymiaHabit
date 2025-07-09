import SwiftUI
import SwiftData

struct HomeView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var colorManager = AppColorManager.shared
    @State private var showingPaywall = false
    
    @Query(
        filter: #Predicate<Habit> { habit in
            !habit.isArchived
        },
        sort: [SortDescriptor(\Habit.displayOrder), SortDescriptor(\Habit.createdAt)]
    )
    private var allBaseHabits: [Habit]
    
    // Simplified habits filtering
    private var baseHabits: [Habit] {
        return allBaseHabits.sorted { first, second in
            if first.displayOrder != second.displayOrder {
                return first.displayOrder < second.displayOrder
            }
            return first.createdAt < second.createdAt
        }
    }
    
    @State private var selectedDate: Date = .now
    @State private var showingNewHabit = false
    // ✅ ИЗМЕНЕНИЕ: Используем объект Habit напрямую вместо String ID
    @State private var selectedHabit: Habit? = nil
    @State private var habitToEdit: Habit? = nil
    @State private var alertState = AlertState()
    @State private var habitForProgress: Habit? = nil
    
    // Computed property for filtering habits based on selected date
    private var activeHabitsForDate: [Habit] {
        baseHabits.filter { habit in
            habit.isActiveOnDate(selectedDate) &&
            selectedDate >= habit.startDate
        }
    }
    
    // Whether there are habits for selected date
    private var hasHabitsForDate: Bool {
        return !activeHabitsForDate.isEmpty
    }
    
    // MARK: - Computed Properties
    private var navigationTitle: String {
        if allBaseHabits.isEmpty {
            return ""
        }
        return formattedNavigationTitle(for: selectedDate)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea(.all)
                
                contentView
                
                // ✅ УПРОЩЕНИЕ: Прямое использование HabitDetailView без контейнера
                if let selectedHabit = selectedHabit {
                    HabitDetailView(
                        habit: selectedHabit,
                        date: selectedDate,
                        isPresented: Binding(
                            get: { self.selectedHabit != nil },
                            set: { if !$0 { self.selectedHabit = nil } }
                        )
                    )
                    .zIndex(1000)
                }
                
                // FAB
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
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(colorManager.selectedColor.adaptiveGradient(for: colorScheme))
                                        .shadow(
                                            color: colorManager.selectedColor.color.opacity(0.4),
                                            radius: 12,
                                            x: 0,
                                            y: 6
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text(navigationTitle)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
            }
            
            // Today button справа
            ToolbarItem(placement: .topBarTrailing) {
                if !Calendar.current.isDateInToday(selectedDate) {
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            selectedDate = Date()
                        }
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
        // ✅ Убираем - обработка уже есть в App
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            if allBaseHabits.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // WeeklyCalendarView
                        WeeklyCalendarView(selectedDate: $selectedDate)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        
                        // Habits list
                        if hasHabitsForDate {
                            LazyVStack(spacing: 14) {
                                ForEach(activeHabitsForDate) { habit in
                                    HabitCardView(
                                        habit: habit,
                                        date: selectedDate,
                                        onTap: {
                                            // ✅ УПРОЩЕНИЕ: Прямая установка объекта Habit
                                            print("🎯 Карточка нажата: \(habit.title)")
                                            selectedHabit = habit
                                        },
                                        onComplete: { completeHabit(habit, for: selectedDate) },
                                        onEdit: { habitToEdit = habit },
                                        onArchive: { archiveHabit(habit) },
                                        onDelete: {
                                            habitForProgress = habit
                                            alertState.isDeleteAlertPresented = true
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 100) // Место для FAB
                }
            }
        }
    }
    
    // MARK: - Navigation Title
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
    
    // MARK: - Helper Methods
    private func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }
    
    private func isYesterday(_ date: Date) -> Bool {
        return Calendar.current.isDateInYesterday(date)
    }
    
    // MARK: - Actions
    private func completeHabit(_ habit: Habit, for date: Date) {
        let currentProgress = habit.progressForDate(date)
        
        if currentProgress < habit.goal {
            habit.completeForDate(date)
            try? modelContext.save()
            HapticManager.shared.play(.success)
        }
    }
    
    private func deleteHabit(_ habit: Habit) {
        NotificationManager.shared.cancelNotifications(for: habit)
        modelContext.delete(habit)
        do {
            try modelContext.save()
            // ✅ ДОБАВИТЬ: Интеграция с HabitManager
            HabitManager.shared.removeViewModel(for: habit.uuid.uuidString)
            HapticManager.shared.play(.error)
        } catch {
            print("❌ Ошибка при удалении привычки: \(error.localizedDescription)")
        }
    }
    
    private func archiveHabit(_ habit: Habit) {
        habit.isArchived = true
        try? modelContext.save()
        HapticManager.shared.play(.success)
    }
}

// MARK: - HabitCardView остается без изменений
struct HabitCardView: View {
    let habit: Habit
    let date: Date
    let onTap: () -> Void
    let onComplete: () -> Void
    let onEdit: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let ringSize: CGFloat = 58
    private let lineWidth: CGFloat = 7
    private let iconSize: CGFloat = 26
    
    @State private var timerPulseScale: CGFloat = 1.0
    
    private var isTimerActive: Bool {
        guard habit.type == .time && Calendar.current.isDateInToday(date) else {
            return false
        }
        
        let habitId = habit.uuid.uuidString
        return TimerService.shared.isTimerRunning(for: habitId)
    }
    
    private var cardProgress: Int {
        let progress = habit.progressForDate(date)
        return progress
    }
    
    private var cardCompletionPercentage: Double {
        guard habit.goal > 0 else { return 0 }
        return Double(cardProgress) / Double(habit.goal)
    }
    
    private var cardFormattedProgressValue: String {
        switch habit.type {
        case .count:
            return cardProgress.formattedAsProgressForRing()
        case .time:
            return cardProgress.formattedAsTimeForRing()
        }
    }
    
    private var cardIsCompleted: Bool {
        return cardProgress >= habit.goal
    }
    
    private var cardIsExceeded: Bool {
        return cardProgress > habit.goal
    }
    
    private var adaptedFontSize: CGFloat {
        let value = cardFormattedProgressValue
        let baseSize = ringSize * 0.28
        
        let digitsCount = value.filter { $0.isNumber }.count
        let factor: CGFloat = digitsCount <= 3 ? 1.0 : (digitsCount == 4 ? 0.85 : 0.7)
        
        return baseSize * factor
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.playSelection()
            onTap()
        }) {
            HStack(spacing: 16) {
                // Left side - Icon
                universalIcon(
                    iconId: habit.iconName,
                    baseSize: 30,
                    color: habit.iconColor,
                    colorScheme: colorScheme
                )
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(habit.iconColor.adaptiveGradient(for: colorScheme).opacity(0.2))
                )
                
                // Middle - Title and goal
                VStack(alignment: .leading, spacing: 5) {
                    Text(habit.title)
                        .font(.headline.weight(.semibold))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text("goal_format".localized(with: habit.formattedGoal))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                ZStack {
                    ProgressRing(
                        progress: cardCompletionPercentage,
                        currentValue: cardFormattedProgressValue,
                        isCompleted: cardIsCompleted,
                        isExceeded: cardIsExceeded,
                        habit: habit,
                        size: ringSize,
                        lineWidth: lineWidth,
                        fontSize: adaptedFontSize,
                        iconSize: iconSize
                    )
                    
                    .overlay(alignment: .bottomTrailing) {
                        if isTimerActive {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(habit.iconColor.adaptiveGradient(for: colorScheme))
                                .scaleEffect(timerPulseScale)
                                .animation(
                                    .easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true),
                                    value: timerPulseScale
                                )
                                .onAppear {
                                    if isTimerActive {
                                        timerPulseScale = 1.1
                                    }
                                }
                                .onDisappear {
                                    timerPulseScale = 1.0
                                }
                                .offset(x: 12, y: 12)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                Color(.separator).opacity(0.5),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(
                        color: Color(.systemGray4).opacity(0.6),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            // Complete
            Button {
                onComplete()
            } label: {
                Label("complete".localized, systemImage: "checkmark")
            }
            .disabled(cardIsCompleted)
            .withHabitColor(habit)
            
            Divider()
            
            // Edit
            Button {
                onEdit()
            } label: {
                Label("button_edit".localized, systemImage: "pencil")
            }
            .withHabitColor(habit)
            
            // Archive
            Button {
                onArchive()
            } label: {
                Label("archive".localized, systemImage: "archivebox")
            }
            .withHabitColor(habit)
            
            Divider()
            
            // Delete
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("button_delete".localized, systemImage: "trash")
            }
            .tint(.red)
        }
    }
}
