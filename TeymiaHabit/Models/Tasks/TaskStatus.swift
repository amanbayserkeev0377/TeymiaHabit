import Foundation

enum TaskStatus: String, Codable, CaseIterable {
    case inbox
    case today
    case upcoming
    case anytime
    case someday
    case logbook
}
