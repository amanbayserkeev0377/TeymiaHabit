import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var allTasks: [TodoTask]
    @Query(sort: \TaskList.title)
    private var allLists: [TaskList]
    private var standaloneLists: [TaskList] {
        allLists.filter { $0.group == nil }
    }
    @Query(sort: \TaskGroup.createdAt)
    private var groups: [TaskGroup]
    
    @State private var selectedScope: TaskScope?
    @State private var isAddingList = false
    @State private var newTaskTitle = ""
    @State private var isAddingTask = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        List {
            // MARK: - Scope Grid
            Section {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 12
                ) {
                    TaskScopeNavigationButton(
                        title: "Completed",
                        icon: "checkmark.circle.fill",
                        color: Color(#colorLiteral(red: 0.007716967259, green: 0.7099662423, blue: 0.635252893, alpha: 1)),
                        count: completedCount
                    ) { selectedScope = .completed }
                    
                    TaskScopeNavigationButton(
                        title: "Inbox",
                        icon: "tray.fill",
                        color: Color(#colorLiteral(red: 0.2824559212, green: 0.5449249148, blue: 0.9648384452, alpha: 1)),
                        count: inboxCount
                    ) { selectedScope = .inbox }
                    
                    TaskScopeNavigationButton(
                        title: "Upcoming",
                        icon: "calendar",
                        color: Color(#colorLiteral(red: 0.9804772735, green: 0.3530035317, blue: 0.3137320876, alpha: 1)),
                        count: upcomingCount
                    ) { selectedScope = .upcoming }
                    
                    TaskScopeNavigationButton(
                        title: "Today",
                        icon: "star.fill",
                        color: .appOrange,
                        count: todayCount
                    ) { selectedScope = .today }
                }
            }
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            
            // MARK: - Standalone Lists
            if !standaloneLists.isEmpty {
                Section("My Lists") {
                    ForEach(standaloneLists) { list in
                        NavigationLink(destination: TaskListView(taskList: list)) {
                            TaskListNavigationRow(
                                title: list.title,
                                iconName: list.iconName,
                                color: list.iconColor.color,
                                count: (list.tasks ?? []).filter { !$0.isCompleted }.count
                            )
                        }
                        .navigationLinkIndicatorVisibility(.hidden)
                    }
                    .onDelete { indices in
                        deleteLists(at: indices, from: standaloneLists)
                    }
                }
            }
            
            // MARK: - Groups
            ForEach(groups) { group in
                Section(group.title) {
                    let sortedLists = (group.lists ?? []).sorted(by: { $0.title < $1.title })
                    ForEach(sortedLists) { list in
                        NavigationLink(destination: TaskListView(taskList: list)) {
                            TaskListNavigationRow(
                                title: list.title,
                                iconName: list.iconName,
                                color: list.iconColor.color,
                                count: (list.tasks ?? []).filter { !$0.isCompleted }.count
                            )
                        }
                        .navigationLinkIndicatorVisibility(.hidden)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Tasks")
        .navigationDestination(item: $selectedScope) { scope in
            ScopeTaskListView(scope: scope)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddingList = true
                } label: {
                    Label("Add List", systemImage: "folder.badge.plus")
                }
            }
        }
        .sheet(isPresented: $isAddingList) {
            NewTaskListView()
        }
        .safeAreaBar(edge: .bottom, alignment: .center) {
            if isAddingTask {
                AddTaskBar(title: $newTaskTitle, isFocused: $isTextFieldFocused) {
                    saveQuickTask()
                }
            }
        }
        .safeAreaBar(edge: .bottom, alignment: .trailing) {
            if !isAddingTask {
                FloatingAddButton {
                    isAddingTask = true
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    // MARK: - Computed Counts
    
    private var inboxCount: Int {
        allTasks.filter { !$0.isCompleted && $0.list == nil }.count
    }
    
    private var todayCount: Int {
        let calendar = Calendar.current
        return allTasks.filter { task in
            guard !task.isCompleted, let date = task.dueDate else { return false }
            return calendar.isDateInToday(date)
        }.count
    }
    
    private var upcomingCount: Int {
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        return allTasks.filter { task in
            guard !task.isCompleted, let date = task.dueDate else { return false }
            return date >= tomorrow
        }.count
    }
    
    private var completedCount: Int {
        allTasks.filter { $0.isCompleted }.count
    }
    
    // MARK: - Actions
    
    private func saveQuickTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            withAnimation(.spring(response: 0.35)) {
                isAddingTask = false
            }
            return
        }
        
        let task = TodoTask(title: trimmed)
        modelContext.insert(task)
        
        withAnimation(.spring(response: 0.35)) {
            newTaskTitle = ""
            isAddingTask = false
            isTextFieldFocused = false
        }
        HapticManager.shared.play(.success)
    }
    
    private func deleteLists(at indices: IndexSet, from lists: [TaskList]) {
        for index in indices {
            modelContext.delete(lists[index])
        }
    }
}

struct TaskListNavigationRow: View {
    let title: String
    let iconName: String
    let color: Color
    let count: Int
    
    var body: some View {
        HStack {
            Label {
                Text(title)
                    .fontWeight(.semibold)
            } icon: { Image(systemName: iconName)
                    .foregroundStyle(color.gradient)
            }
            
            Spacer()
            
            if count > 0 {
                Text("\(count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
        }
    }
}

struct TaskGroupNavigationRow: View {
    let title: String
    
    var body: some View {
        NavigationLink(destination: Text("Список \(title)")) {
            HStack {
                Label(
                    title: { Text(title)
                            .fontWeight(.bold)
                    },
                    icon: { Image(systemName: "square.stack.3d.up")
                            .foregroundStyle(Color.primary)
                    }
                )
            }
        }
        .navigationLinkIndicatorVisibility(.hidden)
    }
}

struct TaskScopeNavigationButton: View {
    let title: String
    let icon: String
    let color: Color
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(color.gradient)
                    Spacer()
                    Text("\(count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.primary.gradient)
                }
                
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary.gradient)
            }
            .contentShape(Rectangle())
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
        }
        .buttonStyle(.plain)
    }
}
