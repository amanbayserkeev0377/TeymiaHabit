import Foundation
import UserNotifications

enum NotificationSound: String, CaseIterable, Identifiable {
    case `system`
    case bellsEcho, clear, guitar, happy, magicMarimba, nimbus, pulse, quickChime, retroGame
    
    var id: String { rawValue }
    
    var displayName: LocalizedStringResource {
        switch self {
        case .system: return "sound_system"
        case .bellsEcho: return "Bells Echo"
        case .clear: return "Clear"
        case .guitar: return "Guitar"
        case .happy: return "Happy"
        case .magicMarimba: return "Magic Marimba"
        case .nimbus: return "Nimbus"
        case .pulse: return "Pulse"
        case .quickChime: return "Quick Chime"
        case .retroGame: return "Retro Game"
        }
    }
    
    var requiresPro: Bool { self != .system }
    var fileExtension: String { "wav" }
}

extension NotificationSound {
    var notificationSound: UNNotificationSound {
        if self == .system {
            return .default
        }
        return UNNotificationSound(named: UNNotificationSoundName(rawValue + "." + fileExtension))
    }
}

extension NotificationSound: HabitSoundProtocol {}

protocol HabitSoundProtocol: Identifiable {
    var displayName: LocalizedStringResource { get }
    var requiresPro: Bool { get }
    var rawValue: String { get }
}
