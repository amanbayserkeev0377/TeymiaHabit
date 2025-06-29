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
    // MARK: - ✅ УЛУЧШЕННЫЕ Dark Colors (контраст 3.0+)
    var darkColor: Color {
        switch self {
        case .primary:
            return Color(#colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1))    // darkColor
        case .red:
            return Color(#colorLiteral(red: 0.6, green: 0.1, blue: 0.08, alpha: 1))  // ✅ темнее: было 0.75→0.6
        case .orange:
            return Color(#colorLiteral(red: 0.75, green: 0.35, blue: 0, alpha: 1))   // ✅ темнее: было 0.9→0.75
        case .yellow:
            return Color(#colorLiteral(red: 0.7, green: 0.5, blue: 0, alpha: 1))     // ✅ темнее: было 0.851→0.7
        case .mint:
            return Color(#colorLiteral(red: 0.0, green: 0.45, blue: 0.38, alpha: 1)) // ✅ темнее: было 0.643→0.45
        case .green:
            return Color(#colorLiteral(red: 0.08, green: 0.45, blue: 0.24, alpha: 1)) // ✅ темнее: было 0.627→0.45
        case .blue:
            return Color(#colorLiteral(red: 0.08, green: 0.3, blue: 0.55, alpha: 1))  // ✅ темнее: было 0.467→0.3
        case .purple:
            return Color(#colorLiteral(red: 0.4, green: 0.2, blue: 0.5, alpha: 1))    // ✅ темнее: было 0.302→0.2
        case .softLavender:
            return Color(#colorLiteral(red: 0.35, green: 0.38, blue: 0.6, alpha: 1))  // ✅ темнее: было 0.48→0.38
        case .pink:
            return Color(#colorLiteral(red: 0.7, green: 0.25, blue: 0.45, alpha: 1))  // ✅ темнее: было 0.4→0.25
        case .sky:
            return Color(#colorLiteral(red: 0.1, green: 0.45, blue: 0.7, alpha: 1))   // ✅ темнее: было 0.6→0.45
        case .brown:
            return Color(#colorLiteral(red: 0.4, green: 0.28, blue: 0.22, alpha: 1))  // ✅ темнее: было 0.38→0.28
        case .gray:
            return Color(#colorLiteral(red: 0.3, green: 0.3, blue: 0.3, alpha: 1))    // ✅ темнее: было 0.451→0.3
        case .colorPicker:
            return Self.customColor
        }
    }
    
    // MARK: - ✅ УЛУЧШЕННЫЕ Light Colors (контраст 3.0+)
    var lightColor: Color {
        switch self {
        case .primary:
            return Color(#colorLiteral(red: 0.8, green: 0.8, blue: 0.82, alpha: 1))   // lightColor
        case .red:
            return Color(#colorLiteral(red: 1.0, green: 0.55, blue: 0.5, alpha: 1))   // ✅ светлее: было 0.45→0.55
        case .orange:
            return Color(#colorLiteral(red: 1.0, green: 0.8, blue: 0.3, alpha: 1))    // ✅ светлее: было 0.7→0.8
        case .yellow:
            return Color(#colorLiteral(red: 1.0, green: 0.9, blue: 0.1, alpha: 1))    // ✅ светлее: было 0.839→0.9
        case .mint:
            return Color(#colorLiteral(red: 0.3, green: 0.9, blue: 0.8, alpha: 1))    // ✅ светлее: было 0.784→0.9
        case .green:
            return Color(#colorLiteral(red: 0.4, green: 0.9, blue: 0.6, alpha: 1))    // ✅ светлее: было 0.820→0.9
        case .blue:
            return Color(#colorLiteral(red: 0.45, green: 0.75, blue: 1.0, alpha: 1))  // ✅ светлее: было 0.659→0.75
        case .purple:
            return Color(#colorLiteral(red: 0.8, green: 0.6, blue: 0.95, alpha: 1))   // ✅ светлее: было 0.482→0.6
        case .softLavender:
            return Color(#colorLiteral(red: 0.8, green: 0.82, blue: 0.95, alpha: 1))  // ✅ светлее: было 0.733→0.82
        case .pink:
            return Color(#colorLiteral(red: 1.0, green: 0.75, blue: 0.9, alpha: 1))   // ✅ светлее: было 0.671→0.75
        case .sky:
            return Color(#colorLiteral(red: 0.5, green: 0.9, blue: 1.0, alpha: 1))    // ✅ светлее: было 0.824→0.9
        case .brown:
            return Color(#colorLiteral(red: 0.9, green: 0.75, blue: 0.65, alpha: 1))  // ✅ светлее: было 0.62→0.75
        case .gray:
            return Color(#colorLiteral(red: 0.85, green: 0.85, blue: 0.87, alpha: 1)) // ✅ светлее: было 0.780→0.85
        case .colorPicker:
            return Self.customColor
        }
    }
    
    // MARK: - ✅ ИСПРАВЛЕННЫЕ градиенты с ЕДИНОЙ ПРАВИЛЬНОЙ логикой
    
    func adaptiveGradient(
            for colorScheme: ColorScheme,
            lightOpacity: Double = 1.0,
            darkOpacity: Double = 1.0
        ) -> LinearGradient {
            // ✅ ЕДИНАЯ ЛОГИКА для ВСЕХ цветов (включая primary)
            let topColor = colorScheme == .dark ? darkColor : lightColor
            let bottomColor = colorScheme == .dark ? lightColor : darkColor
            
            return LinearGradient(
                colors: [
                    topColor.opacity(colorScheme == .dark ? darkOpacity : lightOpacity),
                    bottomColor.opacity(colorScheme == .dark ? lightOpacity : darkOpacity)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
}
