import Foundation
import SwiftData

@Model
final class Subtask {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var parentTask: TodoTask?
    
    init(title: String, isCompleted: Bool = false) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
    }
}
