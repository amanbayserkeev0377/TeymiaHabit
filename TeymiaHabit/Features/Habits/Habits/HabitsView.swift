import SwiftUI
import SwiftData

struct HabitsView: View {
    @Query(sort: \Habit.displayOrder) private var allHabits: [Habit]
    @Environment(HabitsViewModel.self) private var vm
    @Environment(\.modelContext) private var modelContext
    @Environment(AppDependencyContainer.self) private var appContainer
    
    @Namespace private var habitNamespace
    
    @Binding var selectedDate: Date
    @Binding var selectedHabit: Habit?
    
    @State private var showingNewHabit = false
    @State private var habitToEdit: Habit? = nil
    @State private var alertState = AlertState()
    @State private var habitForProgress: Habit? = nil
    @State private var isEditMode: EditMode = .inactive
    
    var body: some View {
        Group {
            if allHabits.isEmpty {
                emptyView
            } else {
                habitsList
            }
        }
        .onChange(of: allHabits, initial: true) { oldValue, newValue in
            Task { @MainActor in
                vm.allBaseHabits = newValue
            }
        }
        .navigationTitle(vm.navigationTitle(for: selectedDate))
        .toolbar {
            if !vm.allBaseHabits.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        withAnimation {
                            isEditMode = isEditMode == .active ? .inactive : .active
                        }
                    }) {
                        Image(systemName: isEditMode == .active ? "checkmark" : "line.3.horizontal")
                            .foregroundStyle(Color.primary)
                    }
                }
            }
            
            if !Calendar.current.isDateInToday(selectedDate) {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        selectedDate = Date()
                    }) {
                        Image(systemName: "arrowshape.turn.up.left")
                            .foregroundStyle(Color.primary)
                    }
                }
            }
            
            ToolbarSpacer(.flexible, placement: .primaryAction)
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                        showingNewHabit = true
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
        .sheet(item: $habitToEdit) { habit in
            NewHabitView(habit: habit)
        }
        .sheet(item: $selectedHabit) { habit in
            HabitDetailView(
                habit: habit,
                date: selectedDate,
                modelContext: modelContext,
                appContainer: appContainer
            )
            .navigationTransition(.zoom(sourceID: habit.id, in: habitNamespace))
            .presentationSizing(.page)
        }
        .deleteSingleHabitAlert(
            isPresented: $alertState.isDeleteAlertPresented,
            habitName: habitForProgress?.title ?? "",
            onDelete: {
                if let habit = habitForProgress {
                    vm.deleteHabit(habit)
                }
                habitForProgress = nil
            }
        )
    }
    
    private var habitsList: some View {
        List {
            Section {
                WeeklyCalendarView(selectedDate: $selectedDate)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            
            ForEach(vm.activeHabits(for: selectedDate)) { habit in
                HabitCard(habit: habit, date: selectedDate)
                .matchedTransitionSource(id: habit.id, in: habitNamespace)
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .opacity(habit.isSkipped(on: selectedDate) ? 0.4 : 1.0)
                .onTapGesture { selectedHabit = habit }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    swipeActions(for: habit)
                }
            }
            .onMove(perform: { source, destination in
                vm.moveHabits(from: source, to: destination, date: selectedDate)
            })
        }
        .listStyle(.plain)
        .scrollIndicators(.hidden)
    }
    
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
    }
    
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
