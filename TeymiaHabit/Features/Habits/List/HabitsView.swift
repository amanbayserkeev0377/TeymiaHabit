import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(HabitService.self) private var habitService
    @Environment(SoundManager.self) private var soundManager
    @Environment(TimerService.self) private var timerService
    @Environment(WidgetService.self) private var widgetService
    @Environment(NotificationManager.self) private var notificationManager
    
    @Binding var selectedDate: Date
    
    var body: some View {
        HabitsContentView(
            selectedDate: $selectedDate,
            viewModel: HabitsViewModel(
                modelContext: modelContext,
                habitService: habitService,
                notificationManager: notificationManager,
                soundManager: soundManager,
                widgetService: widgetService,
                timerService: timerService
            )
        )
    }
}

struct HabitsContentView: View {
    @Query(sort: \Habit.displayOrder) private var allHabits: [Habit]
    @Environment(NavigationManager.self) private var navManager
    @Binding var selectedDate: Date
    @State private var vm: HabitsViewModel
    #if os(iOS)
    @State private var isEditMode: EditMode = .inactive
    #endif
    @State private var selectedHabit: Habit?
    @State private var showingNewHabit = false
    @State private var habitToEdit: Habit? = nil
        
    init(selectedDate: Binding<Date>, viewModel: HabitsViewModel) {
        self._selectedDate = selectedDate
        self._vm = State(wrappedValue: viewModel)
    }
    
    var body: some View {
        Group {
            if allHabits.isEmpty {
                emptyView
            } else {
                habitsList
            }
        }
        .onChange(of: allHabits, initial: true) { _, newValue in
            Task { @MainActor in
                vm.allBaseHabits = newValue
            }
        }
        .sheet(isPresented: $showingNewHabit) {
            NavigationStack {
                NewHabitView()
            }
        }
        .sheet(item: $habitToEdit) { habit in
            NavigationStack {
                NewHabitView(habit: habit)
            }
        }
        .sheet(item: $selectedHabit) { habit in
            NavigationStack {
                HabitDetailView(habit: habit, date: selectedDate)
                    .presentationDetents([.fraction(0.6)])
                    .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: navManager.habitToOpen) { _, habit in
            guard let habit else { return }
            selectedHabit = habit
            navManager.habitToOpen = nil
        }
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(iOS)
        if !vm.allBaseHabits.isEmpty {
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    withAnimation {
                        isEditMode = isEditMode == .active ? .inactive : .active
                    }
                } label: {
                    Image(systemName: isEditMode == .active ? "checkmark" : "line.3.horizontal")
                        .foregroundStyle(Color.primary)
                }
            }
        }
        #endif
        
        if !Calendar.current.isDateInToday(selectedDate) {
            ToolbarItem(placement: .primaryAction) {
                Button { selectedDate = Date() } label: {
                    Image(systemName: "arrowshape.turn.up.left")
                        .foregroundStyle(Color.primary)
                }
            }
        }
        
        ToolbarSpacer(.fixed, placement: .primaryAction)
        
        ToolbarItem(placement: .primaryAction) {
            Button { showingNewHabit = true } label: {
                Image(systemName: "plus")
                    .foregroundStyle(Color.primary)
            }
        }
    }
    
    // MARK: - Habits List
    private var habitsList: some View {
        List {
            habitListContent
        }
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        #if os(iOS)
        .environment(\.editMode, $isEditMode)
        #endif
        .environment(vm)
        .navigationTitle(vm.navigationTitle(for: selectedDate))
//        .navigationBarTitleDisplayMode(.inline) TODO
        .toolbar { toolbarContent }
    }
    
    @ViewBuilder
    private var habitListContent: some View {
        Section {
            WeeklyCalendarView(selectedDate: $selectedDate)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        
        ForEach(vm.activeHabits(for: selectedDate)) { habit in
            HabitCard(habit: habit, date: selectedDate, onEdit: {
                habitToEdit = habit
            })
            .opacity(habit.isSkipped(on: selectedDate) ? 0.4 : 1.0)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(
                top: DS.Spacing.s6,
                leading: DS.Spacing.s16,
                bottom: DS.Spacing.s6,
                trailing: DS.Spacing.s16
            ))
            .onTapGesture {
                #if os(iOS)
                guard isEditMode != .active else { return }
                #endif
                selectedHabit = habit
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                swipeActions(for: habit)
            }
        }
        .onMove { source, destination in
            vm.moveHabits(from: source, to: destination, date: selectedDate)
        }
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
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
                Button { showingNewHabit = true } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("create_habit")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.blackWhite)
                    .padding(.horizontal, DS.Spacing.s24)
                    .padding(.vertical, DS.Spacing.s12)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(.primary).interactive(), in: .capsule)
            }
        )
    }
    
    // MARK: - Swipe Actions
    @ViewBuilder
    private func swipeActions(for habit: Habit) -> some View {
        let isCompleted = habit.progressForDate(selectedDate) >= habit.goal
        Button { vm.completeHabit(habit, date: selectedDate) } label: {
            Label("", systemImage: isCompleted ? "arrow.uturn.backward" : "checkmark")
        }
        .tint(isCompleted ? .red : .green)
        
        let isSkipped = habit.isSkipped(on: selectedDate)
        Button { vm.toggleSkip(for: habit, date: selectedDate) } label: {
            Label("", systemImage: isSkipped ? "arrow.left" : "arrow.right")
        }
        .tint(.gray)
    }
}
