import SwiftUI

enum HabitIconColor: String, CaseIterable, Codable {
    case primary = "primary"
    case red = "red"
    case orange = "orange"
    case yellow = "yellow"
    case mint = "mint"
    case green = "green"
    case blue = "blue"
    case purple = "purple"
    case softLavender = "softLavender"
    case pink = "pink"
    case sky = "sky"
    case brown = "brown"
    case gray = "gray"
    case colorPicker = "colorPicker"
    
    static var customColor: Color = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? #colorLiteral(red: 0.1882352941, green: 0.7843137255, blue: 0.6705882353, alpha: 1)
            : #colorLiteral(red: 0.0, green: 0.6431372549, blue: 0.5490196078, alpha: 1)
    })
    
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
                    : #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)
            })
        case .yellow:
            return Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? #colorLiteral(red: 1, green: 0.8392156863, blue: 0.03921568627, alpha: 1)
                    : #colorLiteral(red: 0.8509803922, green: 0.6509803922, blue: 0, alpha: 1)
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
                    ? #colorLiteral(red: 0.7803921569, green: 0.7803921569, blue: 0.8039215686, alpha: 1)
                    : #colorLiteral(red: 0.4509803922, green: 0.4509803922, blue: 0.4509803922, alpha: 1)
            })
        case .colorPicker:
            return Self.customColor
        }
    }
}

extension HabitIconColor {
    // Dark
    var darkColor: Color {
        switch self {
        case .primary:
            return .primary
        case .red:
            return Color(#colorLiteral(red: 0.75, green: 0.18, blue: 0.15, alpha: 1))
        case .orange:
            return Color(#colorLiteral(red: 0.9, green: 0.5, blue: 0, alpha: 1))
        case .yellow:
            return Color(#colorLiteral(red: 0.8509803922, green: 0.6509803922, blue: 0, alpha: 1))
        case .mint:
            return Color(#colorLiteral(red: 0.0, green: 0.6431372549, blue: 0.5490196078, alpha: 1))
        case .green:
            return Color(#colorLiteral(red: 0.1411764706, green: 0.6274509804, blue: 0.3411764706, alpha: 1))
        case .blue:
            return Color(#colorLiteral(red: 0.1490196078, green: 0.4666666667, blue: 0.6784313725, alpha: 1))
        case .purple:
            return Color(#colorLiteral(red: 0.5411764706, green: 0.3019607843, blue: 0.6352941176, alpha: 1))
        case .softLavender:
            return Color(#colorLiteral(red: 0.576, green: 0.596, blue: 0.773, alpha: 1))
        case .pink:
            return Color(#colorLiteral(red: 0.8705882353, green: 0.4, blue: 0.6117647059, alpha: 1))
        case .sky:
            return Color(#colorLiteral(red: 0.2509803922, green: 0.6823529412, blue: 0.8784313725, alpha: 1))
        case .brown:
            return Color(#colorLiteral(red: 0.52, green: 0.38, blue: 0.31, alpha: 1))
        case .gray:
            return Color(#colorLiteral(red: 0.4509803922, green: 0.4509803922, blue: 0.4509803922, alpha: 1))
        case .colorPicker:
            return Self.customColor
        }
    }
    
    /// Light
    var lightColor: Color {
        switch self {
        case .primary:
            return .primary
        case .red:
            return Color(#colorLiteral(red: 0.98, green: 0.45, blue: 0.4, alpha: 1))
        case .orange:
            return Color(#colorLiteral(red: 1, green: 0.7, blue: 0.2, alpha: 1))
        case .yellow:
            return Color(#colorLiteral(red: 1, green: 0.8392156863, blue: 0.03921568627, alpha: 1))
        case .mint:
            return Color(#colorLiteral(red: 0.1882352941, green: 0.7843137255, blue: 0.6705882353, alpha: 1))
        case .green:
            return Color(#colorLiteral(red: 0.3058823529, green: 0.8196078431, blue: 0.5176470588, alpha: 1))
        case .blue:
            return Color(#colorLiteral(red: 0.3568627451, green: 0.6588235294, blue: 0.9294117647, alpha: 1))
        case .purple:
            return Color(#colorLiteral(red: 0.737254902, green: 0.4823529412, blue: 0.8588235294, alpha: 1))
        case .softLavender:
            return Color(#colorLiteral(red: 0.713, green: 0.733, blue: 0.878, alpha: 1))
        case .pink:
            return Color(#colorLiteral(red: 0.9882352941, green: 0.6705882353, blue: 0.8196078431, alpha: 1))
        case .sky:
            return Color(#colorLiteral(red: 0.3882352941, green: 0.8235294118, blue: 1, alpha: 1))
        case .brown:
            return Color(#colorLiteral(red: 0.78, green: 0.62, blue: 0.52, alpha: 1))
        case .gray:
            return Color(#colorLiteral(red: 0.7803921569, green: 0.7803921569, blue: 0.8039215686, alpha: 1))
        case .colorPicker:
            return Self.customColor
        }
    }
    
    /// Градиент из светлого и темного цвета (с возможностью opacity)
    var gradient: LinearGradient {
        return LinearGradient(
            colors: [lightColor, darkColor],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Градиент с кастомной прозрачностью
    func gradient(lightOpacity: Double = 1.0, darkOpacity: Double = 1.0) -> LinearGradient {
        return LinearGradient(
            colors: [
                lightColor.opacity(lightOpacity),
                darkColor.opacity(darkOpacity)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Получить цвета для градиента с прозрачностью
    func gradientColors(lightOpacity: Double = 1.0, darkOpacity: Double = 1.0) -> [Color] {
        return [
            lightColor.opacity(lightOpacity),
            darkColor.opacity(darkOpacity)
        ]
    }
}
