import SwiftUI

/// Color options for habit icons with adaptive dark/light mode support
/// Each color automatically adapts to the current color scheme
enum HabitIconColor: String, CaseIterable, Codable {
    // MARK: - Basic Colors
    case primary = "primary"
    case red = "red"
    case orange = "orange"
    case yellow = "yellow"
    case mint = "mint"
    case green = "green"
    case blue = "blue"
    case purple = "purple"
    case pink = "pink"
    case brown = "brown"
    case gray = "gray"
    case softLavender = "softLavender"
    case sky = "sky"
    case coral = "coral"
    case bluePink = "bluePink"
    case oceanBlue = "oceanBlue"
    case antarctica = "antarctica"
    case sweetMorning = "sweetMorning"
    case lusciousLime = "lusciousLime"
    case celestial = "celestial"
    case yellowOrange = "yellowOrange"
    case cloudBurst = "cloudBurst"
    case candy = "candy"
    case colorPicker = "colorPicker" // Custom user-defined color
    
    /// Custom color set by user through color picker
    static var customColor: Color = .orange
    
    // MARK: - Adaptive Color (automatically switches based on color scheme)
    
    var color: Color {
        switch self {
        case .primary:
            return .primary
        case .red:
            return .red
        case .orange:
            return .orange
        case .yellow:
            return .yellow
        case .mint:
            return .mint
        case .green:
            return .green
        case .blue:
            return .blue
        case .purple:
            return .purple
        case .softLavender:
            return .teal
        case .pink:
            return .pink
        case .sky:
            return .cyan
        case .brown:
            return .brown
        case .gray:
            return .gray
        case .colorPicker:
            return Self.customColor
        case .coral:
            return .indigo
        case .bluePink:
            return Color(#colorLiteral(red: 0.5673828125, green: 0.7475585341, blue: 0.4226074517, alpha: 1))
        case .oceanBlue:
            return Color(#colorLiteral(red: 0.3796386719, green: 0.5205078125, blue: 0.6577149034, alpha: 1))
        case .antarctica:
            return Color(#colorLiteral(red: 0.537254902, green: 0.4039215686, blue: 0.7019607843, alpha: 1))
        case .sweetMorning:
            return Color(#colorLiteral(red: 0.7620564103, green: 0.6589847207, blue: 0.7723631263, alpha: 1))
        case .lusciousLime:
            return Color(#colorLiteral(red: 0.5932617784, green: 0.2797851264, blue: 0.4050292969, alpha: 1))
        case .celestial:
            return Color(#colorLiteral(red: 0.1328122914, green: 0.5205078721, blue: 0.3911133111, alpha: 1))
        case .yellowOrange:
            return Color(#colorLiteral(red: 0.9707030654, green: 0.5556641221, blue: 0.5283203125, alpha: 1))
        case .cloudBurst:
            return Color(#colorLiteral(red: 0.9160156846, green: 0.6655272841, blue: 0, alpha: 1))
        case .candy:
            return Color(#colorLiteral(red: 0.3254901961, green: 0.2039215686, blue: 0.6588235294, alpha: 1))
        }
    }
}
