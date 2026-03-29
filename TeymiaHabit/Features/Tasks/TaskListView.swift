import SwiftUI
import SwiftData

struct TaskListView: View {
    var taskList: TaskList
    @Query private var tasks: [TodoTask]
    
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTask: TodoTask?
    @State private var newTaskTitle = ""
    @State private var isAddingTask = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var showCompletedTasks = false
    
    init(taskList: TaskList) {
            self.taskList = taskList
            let listId = taskList.persistentModelID
            let predicate = #Predicate<TodoTask> { task in
                task.list?.persistentModelID == listId
            }
            
            _tasks = Query(filter: predicate, sort: \TodoTask.createdAt)
        }

    private var pendingTasks: [TodoTask] {
            tasks.filter { !$0.isCompleted }.sorted { $0.createdAt < $1.createdAt }
        }

        private var completedTasks: [TodoTask] {
            tasks.filter { $0.isCompleted }.sorted { $0.createdAt > $1.createdAt }
        }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if tasks.isEmpty && !isAddingTask {
                    emptyState
                } else {
                    taskList_content
                }
            }

            // Add task bar
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
        .navigationTitle(taskList.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        withAnimation { showCompletedTasks.toggle() }
                    } label: {
                        Label(
                            showCompletedTasks ? "Hide Completed" : "Show Completed",
                            systemImage: showCompletedTasks ? "eye.slash" : "eye"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task)
        }
    }

    // MARK: - Task List Content

    private var taskList_content: some View {
        List {
            // Pending tasks
            Section {
                ForEach(pendingTasks) { task in
                    TaskRowView(task: task) {
                        toggleTask(task)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedTask = task }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { deleteTask(task) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button { toggleTask(task) } label: {
                            Label("Done", systemImage: "checkmark")
                        }
                        .tint(.green)
                    }
                }
                .listRowSeparator(.hidden)
            }

            // Completed tasks (collapsible)
            if showCompletedTasks && !completedTasks.isEmpty {
                Section {
                    ForEach(completedTasks) { task in
                        TaskRowView(task: task) {
                            toggleTask(task)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedTask = task }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { deleteTask(task) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button { toggleTask(task) } label: {
                                Label("Undo", systemImage: "arrow.uturn.backward")
                            }
                            .tint(.orange)
                        }
                    }
                    .listRowSeparator(.hidden)
                } header: {
                    HStack {
                        Text("Completed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(completedTasks.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Bottom padding for floating button
            Color.clear
                .frame(height: 80)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollDismissesKeyboard(.immediately)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: taskList.iconName)
                .font(.system(size: 40))
                .foregroundStyle(taskList.color.gradient.opacity(0.5))

            Text("No tasks")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions
    
    private func saveTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            withAnimation(.spring(response: 0.35)) { isAddingTask = false }
            return
        }
        
        let task = TodoTask(title: trimmed)
        task.list = taskList
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
    }
    
    private func deleteTask(_ task: TodoTask) {
        modelContext.delete(task)
    }
}
