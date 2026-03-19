import Foundation
import SwiftData

@Model
final class TodoTask {
    var id: UUID
    var title: String
    var notes: String?
    var isCompleted: Bool
    var createdAt: Date
    var dueDate: Date?
    
    var statusRawValue: String
    
    @Relationship(deleteRule: .cascade, inverse: \Subtask.parentTask)
    var subtasks: [Subtask] = []
    var category: TaskCategory?

    init(title: String, status: TaskStatus = .inbox) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
        self.statusRawValue = status.rawValue
    }
    
    var status: TaskStatus {
        get { TaskStatus(rawValue: statusRawValue) ?? .inbox }
        set { statusRawValue = newValue.rawValue }
    }
}
