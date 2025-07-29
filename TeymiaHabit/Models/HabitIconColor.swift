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
    
    // MARK: - Extended Palette
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
    
    // MARK: - Special Cases
    case colorPicker = "colorPicker" // Custom user-defined color
    
    /// Custom color set by user through color picker
    static var customColor: Color = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
        ? #colorLiteral(red: 0.1882352941, green: 0.7843137255, blue: 0.6705882353, alpha: 1)
        : #colorLiteral(red: 0.0, green: 0.6431372549, blue: 0.5490196078, alpha: 1)
    })
    
    // MARK: - Adaptive Color (automatically switches based on color scheme)
    
    /// Primary color that adapts to current color scheme
    var color: Color {
        switch self {
        case .primary:
            return .primary
        case .red:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 0.9607843137, green: 0.3803921569, blue: 0.3411764706, alpha: 1)
                : #colorLiteral(red: 0.8431372549, green: 0.231372549, blue: 0.1921568627, alpha: 1)
            })
        case .orange:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 1, green: 0.6235294118, blue: 0.03921568627, alpha: 1)
                : #colorLiteral(red: 0.9019607843, green: 0.5490196078, blue: 0, alpha: 1)
            })
        case .yellow:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 0.95, green: 0.85, blue: 0.15, alpha: 1)
                : #colorLiteral(red: 0.7843137255, green: 0.6274509804, blue: 0, alpha: 1)
            })
        case .mint:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 0.1882352941, green: 0.7843137255, blue: 0.6705882353, alpha: 1)
                : #colorLiteral(red: 0.0, green: 0.6431372549, blue: 0.5490196078, alpha: 1)
            })
        case .green:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 0.3058823529, green: 0.8196078431, blue: 0.5176470588, alpha: 1)
                : #colorLiteral(red: 0.1411764706, green: 0.6274509804, blue: 0.3411764706, alpha: 1)
            })
        case .blue:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 0.3568627451, green: 0.6588235294, blue: 0.9294117647, alpha: 1)
                : #colorLiteral(red: 0.1490196078, green: 0.4666666667, blue: 0.6784313725, alpha: 1)
            })
        case .purple:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 0.737254902, green: 0.4823529412, blue: 0.8588235294, alpha: 1)
                : #colorLiteral(red: 0.5411764706, green: 0.3019607843, blue: 0.6352941176, alpha: 1)
            })
        case .softLavender:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 0.713, green: 0.733, blue: 0.878, alpha: 1)
                : #colorLiteral(red: 0.576, green: 0.596, blue: 0.773, alpha: 1)
            })
        case .pink:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 0.9882352941, green: 0.6705882353, blue: 0.8196078431, alpha: 1)
                : #colorLiteral(red: 0.8705882353, green: 0.4, blue: 0.6117647059, alpha: 1)
            })
        case .sky:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 0.3882352941, green: 0.8235294118, blue: 1, alpha: 1)
                : #colorLiteral(red: 0.2509803922, green: 0.6823529412, blue: 0.8784313725, alpha: 1)
            })
        case .brown:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 0.611, green: 0.466, blue: 0.392, alpha: 1)
                : #colorLiteral(red: 0.694, green: 0.541, blue: 0.454, alpha: 1)
            })
        case .gray:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 0.4196078431, green: 0.4666666667, blue: 0.8392156863, alpha: 1)
                : #colorLiteral(red: 0.2352941176, green: 0.2784313725, blue: 0.5607843137, alpha: 1)
            })
        case .colorPicker:
            return Self.customColor
        
        // Extended palette colors (keeping original implementation)
        case .coral:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 0.8911940455, green: 0.5065267682, blue: 0.7020475268, alpha: 1)
                : #colorLiteral(red: 0.8046556711, green: 0.4489571452, blue: 0.7656339407, alpha: 1)
            })
        case .bluePink:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 0.6014889116, green: 0.4786262145, blue: 0.8774001837, alpha: 1)
                : #colorLiteral(red: 0.3254901961, green: 0.2039215686, blue: 0.6588235294, alpha: 1)
            })
        case .oceanBlue:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 0.4392156863, green: 0.6666666667, blue: 1, alpha: 1)
                : #colorLiteral(red: 0.4836291671, green: 0.6798911691, blue: 0.9972648025, alpha: 1)
            })
        case .antarctica:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 0.4784313725, green: 0.7176470588, blue: 0.7960784314, alpha: 1)
                : #colorLiteral(red: 0.231372549, green: 0.462745098, blue: 0.537254902, alpha: 1)
            })
        case .sweetMorning:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 1, green: 0.568627451, blue: 0.4352941176, alpha: 1)
                : #colorLiteral(red: 1, green: 0.3725490196, blue: 0.4274509804, alpha: 1)
            })
        case .lusciousLime:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 0.3529411765, green: 0.7490196078, blue: 0.1490196078, alpha: 1)
                : #colorLiteral(red: 0.2352941176, green: 0.4823529412, blue: 0.1019607843, alpha: 1)
            })
        case .celestial:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 0.6901960784, green: 0.7450980392, blue: 0.7725490196, alpha: 1)
                : #colorLiteral(red: 0.3764705882, green: 0.4901960784, blue: 0.5450980392, alpha: 1)
            })
        case .yellowOrange:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 0.9844796062, green: 0.7052091956, blue: 0.1644336283, alpha: 1)
                : #colorLiteral(red: 0.9626899362, green: 0.5305011868, blue: 0.1816505194, alpha: 1)
            })
        case .cloudBurst:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 0.4980392157, green: 0.7176470588, blue: 0.7450980392, alpha: 1)
                : #colorLiteral(red: 0.4980392157, green: 0.7176470588, blue: 0.7450980392, alpha: 1)
            })
        case .candy:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? #colorLiteral(red: 0.7475101948, green: 0.7774429917, blue: 0.8837624788, alpha: 1)
                : #colorLiteral(red: 0.7620564103, green: 0.6589847207, blue: 0.7723631263, alpha: 1)
            })
        }
    }
}

// MARK: - Additional Color Variations (for gradient effects)

extension HabitIconColor {
    
    /// Darker variant of the color (used in gradients and special effects)
    var darkColor: Color {
        switch self {
        case .primary:
            return Color(#colorLiteral(red: 0.1803921569, green: 0.1803921569, blue: 0.1803921569, alpha: 1))
        case .red:
            return Color(#colorLiteral(red: 0.65, green: 0.15, blue: 0.12, alpha: 1))
        case .orange:
            return Color(#colorLiteral(red: 0.7843, green: 0.3922, blue: 0, alpha: 1))
        case .yellow:
            return Color(#colorLiteral(red: 0.75, green: 0.55, blue: 0.05, alpha: 1))
        case .mint:
            return Color(#colorLiteral(red: 0.05, green: 0.5, blue: 0.42, alpha: 1))
        case .green:
            return Color(#colorLiteral(red: 0.12, green: 0.5, blue: 0.28, alpha: 1))
        case .blue:
            return Color(#colorLiteral(red: 0.12, green: 0.35, blue: 0.6, alpha: 1))
        case .purple:
            return Color(#colorLiteral(red: 0.45, green: 0.25, blue: 0.55, alpha: 1))
        case .softLavender:
            return Color(#colorLiteral(red: 0.4, green: 0.42, blue: 0.65, alpha: 1))
        case .pink:
            return Color(#colorLiteral(red: 0.75, green: 0.3, blue: 0.5, alpha: 1))
        case .sky:
            return Color(#colorLiteral(red: 0.15, green: 0.5, blue: 0.75, alpha: 1))
        case .brown:
            return Color(#colorLiteral(red: 0.45, green: 0.32, blue: 0.26, alpha: 1))
        case .gray:
            return Color(#colorLiteral(red: 0.15, green: 0.2, blue: 0.45, alpha: 1))
        case .colorPicker:
            return Self.customColor
        
        // Extended palette dark variants
        case .coral:
            return Color(#colorLiteral(red: 0.7098039216, green: 0.1215686275, blue: 0.1019607843, alpha: 1))
        case .bluePink:
            return Color(#colorLiteral(red: 0.2705882353, green: 0.4078431373, blue: 0.862745098, alpha: 1))
        case .oceanBlue:
            return Color(#colorLiteral(red: 0.1137254902, green: 0.768627451, blue: 0.9843137255, alpha: 1))
        case .antarctica:
            return Color(#colorLiteral(red: 0.1176470588, green: 0.6823529412, blue: 0.5960784314, alpha: 1))
        case .sweetMorning:
            return Color(#colorLiteral(red: 1, green: 0.3725490196, blue: 0.4274509804, alpha: 1))
        case .lusciousLime:
            return Color(#colorLiteral(red: 0, green: 0.5725490196, blue: 0.2705882353, alpha: 1))
        case .celestial:
            return Color(#colorLiteral(red: 0.2705882353, green: 0.3529411765, blue: 0.3921568627, alpha: 1))
        case .yellowOrange:
            return Color(#colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1))
        case .cloudBurst:
            return Color(#colorLiteral(red: 0.4980392157, green: 0.7176470588, blue: 0.7450980392, alpha: 1))
        case .candy:
            return Color(#colorLiteral(red: 0.768627451, green: 0.568627451, blue: 0.6941176471, alpha: 1))
        }
    }
    
    /// Lighter variant of the color (used in gradients and special effects)
    var lightColor: Color {
        switch self {
        case .primary:
            return Color(#colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1))
        case .red:
            return Color(#colorLiteral(red: 0.95, green: 0.5, blue: 0.45, alpha: 1))
        case .orange:
            return Color(#colorLiteral(red: 1, green: 0.706, blue: 0, alpha: 1))
        case .yellow:
            return Color(#colorLiteral(red: 0.95, green: 0.85, blue: 0.15, alpha: 1))
        case .mint:
            return Color(#colorLiteral(red: 0.25, green: 0.85, blue: 0.75, alpha: 1))
        case .green:
            return Color(#colorLiteral(red: 0.35, green: 0.85, blue: 0.55, alpha: 1))
        case .blue:
            return Color(#colorLiteral(red: 0.4, green: 0.7, blue: 0.95, alpha: 1))
        case .purple:
            return Color(#colorLiteral(red: 0.75, green: 0.55, blue: 0.9, alpha: 1))
        case .softLavender:
            return Color(#colorLiteral(red: 0.75, green: 0.77, blue: 0.9, alpha: 1))
        case .pink:
            return Color(#colorLiteral(red: 0.95, green: 0.7, blue: 0.85, alpha: 1))
        case .sky:
            return Color(#colorLiteral(red: 0.45, green: 0.85, blue: 0.95, alpha: 1))
        case .brown:
            return Color(#colorLiteral(red: 0.85, green: 0.7, blue: 0.6, alpha: 1))
        case .gray:
            return Color(#colorLiteral(red: 0.55, green: 0.6, blue: 0.9, alpha: 1))
        case .colorPicker:
            return Self.customColor
        
        // Extended palette light variants
        case .coral:
            return Color(#colorLiteral(red: 0.9764705882, green: 0.5568627451, blue: 0.9647058824, alpha: 1))
        case .bluePink:
            return Color(#colorLiteral(red: 0.6901960784, green: 0.4156862745, blue: 0.7019607843, alpha: 1))
        case .oceanBlue:
            return Color(#colorLiteral(red: 0.5725490196, green: 0.937254902, blue: 0.9921568627, alpha: 1))
        case .antarctica:
            return Color(#colorLiteral(red: 0.8470588235, green: 0.7098039216, blue: 1, alpha: 1))
        case .sweetMorning:
            return Color(#colorLiteral(red: 1, green: 0.7647058824, blue: 0.4431372549, alpha: 1))
        case .lusciousLime:
            return Color(#colorLiteral(red: 0.9882352941, green: 0.9333333333, blue: 0.1294117647, alpha: 1))
        case .celestial:
            return Color(#colorLiteral(red: 0.6901960784, green: 0.7450980392, blue: 0.7725490196, alpha: 1))
        case .yellowOrange:
            return Color(#colorLiteral(red: 0.9995340705, green: 0.988355577, blue: 0.4726552367, alpha: 1))
        case .cloudBurst:
            return Color(#colorLiteral(red: 0.8235294118, green: 0.9529411765, blue: 0.9333333333, alpha: 1))
        case .candy:
            return Color(#colorLiteral(red: 0.737254902, green: 0.9058823529, blue: 0.9882352941, alpha: 1))
        }
    }
    
    /// Creates adaptive gradient based on current color scheme
    /// - Parameter colorScheme: Current color scheme (light/dark)
    /// - Returns: LinearGradient that adapts to the color scheme
    func adaptiveGradient(for colorScheme: ColorScheme) -> LinearGradient {
        let topColor = colorScheme == .dark ? darkColor : lightColor
        let bottomColor = colorScheme == .dark ? lightColor : darkColor
        
        return LinearGradient(
            colors: [topColor, bottomColor],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
