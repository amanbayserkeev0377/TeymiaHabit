import Foundation
import SwiftData

@Model
final class TaskGroup {
    var title: String = ""
    var createdAt: Date = Date()
    
    @Relationship(deleteRule: .cascade, inverse: \TaskList.group)
    var lists: [TaskList]? = []
    
    init(title: String) {
        self.title = title
        self.createdAt = Date()
        self.lists = []
    }
}
