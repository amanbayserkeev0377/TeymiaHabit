import SwiftUI
import SwiftData

// MARK: - Generic Scope List View

struct ScopeTaskListView: View {
    let scope: TaskScope

    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [TodoTask]

    @State private var selectedTask: TodoTask?
    @State private var newTaskTitle = ""
    @State private var isAddingTask = false
    @FocusState private var isTextFieldFocused: Bool

    // Filter tasks based on scope
    private var tasks: [TodoTask] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        switch scope {
        case .inbox:
            return allTasks
                .filter { !$0.isCompleted && $0.list == nil }
                .sorted { $0.createdAt > $1.createdAt }

        case .today:
            return allTasks.filter { task in
                guard !task.isCompleted, let date = task.dueDate else { return false }
                return calendar.isDate(date, inSameDayAs: today)
            }.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }

        case .upcoming:
            return allTasks.filter { task in
                guard !task.isCompleted, let date = task.dueDate else { return false }
                return date >= tomorrow
            }.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }

        case .completed:
            return allTasks
                .filter { $0.isCompleted }
                .sorted { $0.createdAt > $1.createdAt }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if tasks.isEmpty {
                    emptyState
                } else {
                    taskList
                }
            }

            // Add task bar for non-completed scopes
            if scope != .completed {
                VStack(spacing: 0) {
                    if isAddingTask {
                        AddTaskBar(title: $newTaskTitle, isFocused: $isTextFieldFocused) {
                            saveTask()
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        FloatingAddButton {
                            withAnimation(.spring(response: 0.35)) {
                                isAddingTask = true
                                isTextFieldFocused = true
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.35), value: isAddingTask)
            }
        }
        .navigationTitle(scope.displayName)
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task)
        }
        .onTapGesture {
            // Dismiss add bar on background tap
            if isAddingTask && newTaskTitle.isEmpty {
                withAnimation(.spring(response: 0.35)) {
                    isAddingTask = false
                    isTextFieldFocused = false
                }
            }
        }
    }

    // MARK: - Task List

    private var taskList: some View {
        List {
            ForEach(groupedTasks, id: \.0) { group, tasks in
                Section(header: group.map { Text($0).font(.caption).foregroundStyle(.secondary) }) {
                    ForEach(tasks) { task in
                        TaskRowView(task: task) {
                            toggleTask(task)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTask = task
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteTask(task)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                toggleTask(task)
                            } label: {
                                Label(
                                    task.isCompleted ? "Undo" : "Done",
                                    systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark"
                                )
                            }
                            .tint(task.isCompleted ? .orange : .green)
                        }
                    }
                }
            }
            .listRowSeparator(.hidden)

            // Bottom padding for floating button
            Color.clear
                .frame(height: 80)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollDismissesKeyboard(.immediately)
    }

    // MARK: - Grouping

    /// Groups tasks by date section for Upcoming scope, plain list for others
    private var groupedTasks: [(String?, [TodoTask])] {
        guard scope == .upcoming else {
            return [(nil, tasks)]
        }

        let calendar = Calendar.current
        var groups: [(String?, [TodoTask])] = []
        var grouped: [String: [TodoTask]] = [:]

        for task in tasks {
            guard let date = task.dueDate else { continue }
            let key = sectionTitle(for: date, calendar: calendar)
            grouped[key, default: []].append(task)
        }

        // Sort groups chronologically
        let sortedKeys = grouped.keys.sorted { a, b in
            let dateA = grouped[a]?.first?.dueDate ?? .distantFuture
            let dateB = grouped[b]?.first?.dueDate ?? .distantFuture
            return dateA < dateB
        }

        for key in sortedKeys {
            groups.append((key, grouped[key] ?? []))
        }

        return groups
    }

    private func sectionTitle(for date: Date, calendar: Calendar) -> String {
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let weekAhead = calendar.date(byAdding: .day, value: 7, to: today) ?? today

        if calendar.isDate(date, inSameDayAs: tomorrow) { return "Tomorrow" }
        if date < weekAhead {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: date)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: scope.emptyIcon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.5))

            Text(scope.emptyMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func saveTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            withAnimation(.spring(response: 0.35)) {
                isAddingTask = false
            }
            return
        }

        let dueDate: Date? = scope == .today ? Date() : nil
        let task = TodoTask(title: trimmed, dueDate: dueDate)
        modelContext.insert(task)

        withAnimation(.spring(response: 0.35)) {
            newTaskTitle = ""
            isAddingTask = false
            isTextFieldFocused = false
        }
        HapticManager.shared.play(.success)
    }

    private func toggleTask(_ task: TodoTask) {
        withAnimation(.spring(response: 0.3)) {
            task.isCompleted.toggle()
        }
        HapticManager.shared.playSelection()
    }

    private func deleteTask(_ task: TodoTask) {
        modelContext.delete(task)
        HapticManager.shared.play(.error)
    }
}

// MARK: - TaskScope Extensions

extension TaskScope {
    var displayName: String {
        switch self {
        case .inbox: return "Inbox"
        case .today: return "Today"
        case .upcoming: return "Upcoming"
        case .completed: return "Completed"
        }
    }

    var emptyIcon: String {
        switch self {
        case .inbox: return "tray"
        case .today: return "star"
        case .upcoming: return "calendar"
        case .completed: return "checkmark.circle"
        }
    }

    var emptyMessage: String {
        switch self {
        case .inbox: return "No tasks in Inbox"
        case .today: return "Nothing due today"
        case .upcoming: return "No upcoming tasks"
        case .completed: return "No completed tasks yet"
        }
    }
}
