import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \TodoTask.createdAt, order: .reverse)
    private var allTasks: [TodoTask]
    
    @Query(sort: \TaskCategory.title)
    private var categories: [TaskCategory]
    
    var body: some View {
            List {
                Section {
                    TaskNavigationRow(title: "Inbox", icon: "tray.badge.fill", color: .blue, count: count(for: .inbox))
                    TaskNavigationRow(title: "Today", icon: "star.fill", color: .yellow, count: count(for: .today))
                    TaskNavigationRow(title: "Upcoming", icon: "calendar", color: .red, count: count(for: .upcoming))
                    TaskNavigationRow(title: "Anytime", icon: "text.pad.header.badge.clock", color: .mint, count: count(for: .anytime))
                    TaskNavigationRow(title: "Someday", icon: "archivebox.fill", color: .gray, count: count(for: .someday))
                    TaskNavigationRow(title: "Logbook", icon: "book.pages.fill", color: .green, count: count(for: .logbook))
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                
                if !categories.isEmpty {
                    Section("Мои списки") {
                        ForEach(categories) { category in
                            TaskNavigationRow(
                                title: category.title,
                                icon: category.icon,
                                color: .primary,
                                count: category.tasks.count
                            )
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("tasks")
            .toolbar {
                Button(action: addCategory) {
                    Image(systemName: "folder.badge.plus")
                }
                Button(action: addTask) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
    }
    
    
    private func count(for status: TaskStatus) -> Int {
        allTasks.filter { $0.status == status && !$0.isCompleted }.count
    }
    
    private func addTask() {
        
    }
    
    private func addCategory() {
        
    }
}

struct TaskNavigationRow: View {
    let title: String
    let icon: String
    let color: Color
    let count: Int
    
    var body: some View {
        NavigationLink(destination: Text("Список \(title)")) {
            HStack {
                Label(
                    title: { Text(title)
                            .fontWeight(.semibold)
                    },
                    icon: { Image(systemName: icon)
                            .foregroundStyle(color.gradient)
                    }
                )
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
        .navigationLinkIndicatorVisibility(.hidden)
    }
}
