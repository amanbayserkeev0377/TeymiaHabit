import Foundation

enum CompletionSound: String, CaseIterable, Identifiable {
    case `default`, chime, chord, click, droplet, echo, flow, glow, horizon, marimba, slide, sparkle, success, sunrise, surge, touch, veil, violin

    var id: String { rawValue }

    var displayName: LocalizedStringResource {
        switch self {
        case .default: return "default_sound"
        case .chime: return "Chime"
        case .chord: return "Chord"
        case .click: return "Click"
        case .droplet: return "Droplet"
        case .echo: return "Echo"
        case .flow: return "Flow"
        case .glow: return "Glow"
        case .horizon: return "Horizon"
        case .marimba: return "Marimba"
        case .slide: return "Slide"
        case .sparkle: return "Sparkle"
        case .success: return "Success"
        case .sunrise: return "Sunrise"
        case .surge: return "Surge"
        case .touch: return "Touch"
        case .veil: return "Veil"
        case .violin: return "Violin"
        }
    }

    var requiresPro: Bool { self != .default }
    var fileExtension: String { "wav" }
}

extension CompletionSound: HabitSoundProtocol {}
