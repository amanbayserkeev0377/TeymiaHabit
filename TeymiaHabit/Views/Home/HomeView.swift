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
    @State private var showingReorderHabits = false
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
            ZStack {

                contentView
                
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
            print("🔗 HomeView received deeplink notification")
            
            if let habit = notification.object as? Habit {
                // ✅ Проверяем, не та ли же привычка уже открыта
                if selectedHabit?.uuid == habit.uuid {
                    print("✅ Same habit already open, no action needed")
                    return
                }
                
                // ✅ Закрываем текущий sheet только если это другая привычка
                selectedHabit = nil
                
                // ✅ Через задержку открываем новый
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedHabit = habit
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissAllSheets)) { _ in
            print("🔄 Dismissing all sheets")
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
    
    private func deleteHabit(_ habit: Habit) {
        NotificationManager.shared.cancelNotifications(for: habit)
        modelContext.delete(habit)
        do {
            try modelContext.save()
            HabitManager.shared.removeViewModel(for: habit.uuid.uuidString)
            HapticManager.shared.play(.error)
            WidgetUpdateService.shared.reloadWidgets()
        } catch {
            print("❌ Ошибка при удалении привычки: \(error.localizedDescription)")
        }
    }
    
    private func archiveHabit(_ habit: Habit) {
        habit.isArchived = true
        try? modelContext.save()
        HapticManager.shared.play(.success)
        WidgetUpdateService.shared.reloadWidgets()
    }
}

// MARK: - HabitCardView
struct HabitCardView: View {
    let habit: Habit
    let date: Date
    let onTap: () -> Void
    let onEdit: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void
    let onReorder: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    private let ringSize: CGFloat = 52
    private let lineWidth: CGFloat = 6
    
    @State private var timerUpdateTrigger = 0
    @State private var cardTimer: Timer?
    @State private var isProgressRingPressed = false
    @State private var progressAnimationTrigger = 0
    @State private var hasPlayedCompletionSound = false
    @State private var confettiTrigger = 0
    
    private var isTimerActive: Bool {
        guard habit.type == .time && Calendar.current.isDateInToday(date) else {
            return false
        }
        
        let habitId = habit.uuid.uuidString
        return TimerService.shared.isTimerRunning(for: habitId)
    }
    
    private var cardProgress: Int {
        _ = timerUpdateTrigger // Подписка на обновления
        
        // Live прогресс для активных таймеров сегодня
        if isTimerActive {
            if let liveProgress = TimerService.shared.getLiveProgress(for: habit.uuid.uuidString) {
                return liveProgress
            }
        }
        
        // Обычный прогресс из базы
        return habit.progressForDate(date)
    }
    
    private var formattedProgress: String {
        return habit.formatProgress(cardProgress)
    }
    
    private func checkTimerCompletion() {
        guard isTimerActive,
              let liveProgress = TimerService.shared.getLiveProgress(for: habit.uuid.uuidString),
              !hasPlayedCompletionSound,
              habit.progressForDate(date) < habit.goal, // База была < цели
              liveProgress >= habit.goal else { return } // Live достиг цели
        
        hasPlayedCompletionSound = true
        SoundManager.shared.playCompletionSound()
        HapticManager.shared.play(.success)
    }
    
    private var cardCompletionPercentage: Double {
        guard habit.goal > 0 else { return 0 }
        return Double(cardProgress) / Double(habit.goal)
    }
    
    private var cardIsCompleted: Bool {
        return cardProgress >= habit.goal
    }
    
    private var cardIsExceeded: Bool {
        return cardProgress > habit.goal
    }
    
    private var completedTextGradient: AnyShapeStyle {
        return AppColorManager.getCompletedBarStyle(for: colorScheme)
    }
    
    private var exceededTextGradient: AnyShapeStyle {
        return AppColorManager.getExceededBarStyle(for: colorScheme)
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
                    baseSize: 26,
                    color: habit.iconColor,
                    colorScheme: colorScheme
                )
                .frame(width: 54, height: 54)
                .background(
                    Circle()
                        .fill(habit.iconColor.adaptiveGradient(for: colorScheme).opacity(0.15))
                )
                
                // Middle - Title and progress/goal
                VStack(alignment: .leading, spacing: 3) {
                    Text(habit.title)
                        .font(.body.weight(.medium))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)
                    
                    Text(formattedProgress)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(progressTextColor)
                        .monospacedDigit()
                        .animation(isTimerActive ? .none : .easeInOut(duration: 0.4), value: formattedProgress)
                }
                
                Spacer()
                
                // Right side - Progress Ring
                ZStack {
                    ProgressRing.compact(
                        progress: cardCompletionPercentage,
                        isCompleted: cardIsCompleted,
                        isExceeded: cardIsExceeded,
                        habit: habit,
                        size: ringSize,
                        lineWidth: lineWidth
                    )
                }
                .confettiCannon(
                    trigger: $confettiTrigger,
                    num: 15,
                    confettis: [.shape(.circle), .shape(.triangle)],
                    colors: [.orange, .green, .blue, .red, .yellow, .purple, .pink, .cyan],
                    confettiSize: 6.0,
                    rainHeight: 500.0,
                    radius: 120,
                    hapticFeedback: false
                )
                .scaleEffect(isProgressRingPressed ? 1.2 : 1.0)
                .animation(.smooth(duration: 0.6), value: isProgressRingPressed)
                .onTapGesture {
                    HapticManager.shared.playImpact(.medium)
                    
                    isProgressRingPressed = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isProgressRingPressed = false
                    }
                    
                    toggleHabitCompletion()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 64)
            .background(cardBackground)
        }
        .buttonStyle(.plain)
        .onAppear {
            if isTimerActive {
                startCardTimer()
            }
        }
        .onDisappear {
            stopCardTimer()
        }
        .onChange(of: timerUpdateTrigger) { _, _ in
            if isTimerActive {
                checkTimerCompletion()
            }
        }
        .onChange(of: isTimerActive) { _, newValue in
            if newValue {
                startCardTimer()
                hasPlayedCompletionSound = false
            } else {
                stopCardTimer()
            }
        }
        .contextMenu {
            // Edit
            Button {
                onEdit()
            } label: {
                Label("button_edit".localized, systemImage: "pencil")
            }
            .withAppGradient()

            Button {
                onReorder()
            } label : {
                Label("reorder".localized, systemImage: "arrow.up.arrow.down")
            }
            .withAppGradient()

            // Archive
            Button {
                onArchive()
            } label: {
                Label("archive".localized, systemImage: "archivebox")
            }
            .withAppGradient()

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
    
    // MARK: - Toggle Completion
    
    private func toggleHabitCompletion() {
        do {
            let viewModel = try HabitManager.shared.getViewModel(for: habit, date: date, modelContext: modelContext)
            
            if cardIsCompleted {
                // Если завершена - сбрасываем на 0
                viewModel.resetProgress()
            } else {
                // Если не завершена - завершаем
                let wasCompleted = cardIsCompleted // ✅ Сохраняем состояние ДО изменения
                viewModel.completeHabit()
                SoundManager.shared.playCompletionSound()
                
                // ✅ Показываем конфетти если привычка стала завершенной
                if !wasCompleted {
                    confettiTrigger += 1 // ✅ Добавил += 1
                }
            }
            HapticManager.shared.play(.success)
            WidgetUpdateService.shared.reloadWidgets()
        } catch {
            // Fallback - direct habit methods
            if cardIsCompleted {
                // ✅ Исправил логику: если завершена - сбрасываем
                habit.resetProgress(for: date, modelContext: modelContext)
            } else {
                // ✅ Если НЕ завершена - завершаем
                let wasCompleted = cardIsCompleted // ✅ Сохраняем состояние ДО изменения
                habit.complete(for: date, modelContext: modelContext)
                SoundManager.shared.playCompletionSound()
                
                // ✅ Конфетти и в fallback случае
                if !wasCompleted {
                    confettiTrigger += 1
                }
            }
            HapticManager.shared.play(.success)
            WidgetUpdateService.shared.reloadWidgets()

        }
    }

    
    // MARK: - Computed Properties
    private var progressTextColor: AnyShapeStyle {
        if cardIsExceeded {
            return exceededTextGradient
        } else if cardIsCompleted {
            return completedTextGradient
        } else {
            return AnyShapeStyle(Color.primary)
        }
    }
    
    private var cardBackground: some View {
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
    }
    
    // MARK: - Timer Management
    
    private func startCardTimer() {
        // Останавливаем предыдущий таймер если есть
        stopCardTimer()
        
        // Запускаем новый таймер с интервалом 1 секунда
        cardTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            timerUpdateTrigger += 1
        }
    }
    
    private func stopCardTimer() {
        cardTimer?.invalidate()
        cardTimer = nil
    }
}
