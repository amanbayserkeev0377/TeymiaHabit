import Foundation
import SwiftData

@Model
final class TaskCategory {
    var id: UUID
    var title: String
    var icon: String
    
    @Relationship(deleteRule: .cascade, inverse: \TodoTask.category)
    var tasks: [TodoTask] = []
    
    init(title: String, icon: String = "list.bullet.circle") {
        self.id = UUID()
        self.title = title
        self.icon = icon
    }
}
