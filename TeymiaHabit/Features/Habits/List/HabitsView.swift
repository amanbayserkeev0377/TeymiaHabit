import SwiftUI
import SwiftData

struct HabitsView: View {
    @Query(sort: \Habit.displayOrder) private var allHabits: [Habit]
    @Environment(HabitsViewModel.self) private var vm
    @Environment(\.modelContext) private var modelContext
    @Environment(AppDependencyContainer.self) private var appContainer
    @Environment(NavigationManager.self) private var navManager
    @Namespace private var habitNamespace
    @State private var isEditMode: EditMode = .inactive
    
    @Binding var selectedDate: Date
    @State private var selectedHabit: Habit?
    @State private var showingNewHabit = false
    @State private var habitToEdit: Habit? = nil
    
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
        .navigationTitle(vm.navigationTitle(for: selectedDate))
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingNewHabit) {
            NewHabitView()
        }
        .sheet(item: $habitToEdit) { habit in
            NewHabitView(habit: habit)
        }
        .fullScreenCover(item: $selectedHabit) { habit in
                HabitDetailView(
                    habit: habit,
                    date: selectedDate,
                    modelContext: modelContext,
                    appContainer: appContainer
                )
                .navigationTransition(.zoom(sourceID: habit.id, in: habitNamespace))
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
        if !vm.allBaseHabits.isEmpty {
            ToolbarItem(placement: .topBarLeading) {
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
        .environment(\.editMode, $isEditMode)
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
            .matchedTransitionSource(id: habit.id, in: habitNamespace)
            .opacity(habit.isSkipped(on: selectedDate) ? 0.4 : 1.0)
            .onTapGesture {
                guard isEditMode != .active else { return }
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
                    .foregroundStyle(.primaryInverse)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
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
