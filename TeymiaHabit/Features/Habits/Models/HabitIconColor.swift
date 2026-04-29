import SwiftUI

enum HabitIconColor: String, CaseIterable, Codable {
    // MARK: - Basic Colors
    case primary, red, orange, yellow, mint, green, blue, purple
    case pink, brown, gray, softLavender, sky, coral, bluePink, oceanBlue
    case antarctica, sweetMorning, lusciousLime, celestial, yellowOrange, cloudBurst, candy, colorPicker
    
    var baseColor: Color {
        switch self {
        case .primary: .blackWhite
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .mint: .mint
        case .green: .green
        case .blue: .blue
        case .purple: .purple
        case .softLavender: .softLavender
        case .pink: .pink
        case .sky: .sky
        case .brown: .brown
        case .gray: .gray
        case .coral: .coral
        case .bluePink: .bluePink
        case .oceanBlue: .oceanBlue
        case .antarctica: .antarctica
        case .sweetMorning: .sweetMorning
        case .lusciousLime: .lusciousLime
        case .celestial: .celestial
        case .yellowOrange: .yellowOrange
        case .cloudBurst: .cloudBurst
        case .candy: .candy
        case .colorPicker: .colorPicker
        }
    }
}
