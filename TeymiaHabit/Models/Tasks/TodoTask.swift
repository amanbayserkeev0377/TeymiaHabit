import Foundation
import SwiftData

@Model
final class TodoTask {
    var title: String = ""
    var notes: String?
    var dueDate: Date?
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var list: TaskList?
    
    @Relationship(deleteRule: .cascade)
    var subtasks: [Subtask]? = []

    init(title: String, dueDate: Date? = nil) {
        self.title = title
        self.dueDate = dueDate
        self.subtasks = []
    }
}
