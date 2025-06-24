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
    
    // MARK: - ✅ ИСПРАВЛЕННЫЕ градиенты с ЕДИНОЙ ПРАВИЛЬНОЙ логикой
    
    /// Адаптивный градиент с учетом темы (ИСПРАВЛЕНО)
    func adaptiveGradient(
        for colorScheme: ColorScheme,
        lightOpacity: Double = 1.0,
        darkOpacity: Double = 1.0
    ) -> LinearGradient {
        // ✅ ЕДИНАЯ ЛОГИКА для всего приложения (как в AppColorManager)
        // Light theme: light top → dark bottom
        // Dark theme: dark top → light bottom
        let topColor = colorScheme == .dark ? darkColor : lightColor      // темная тема: темный вверх, светлая тема: светлый вверх
        let bottomColor = colorScheme == .dark ? lightColor : darkColor   // темная тема: светлый низ, светлая тема: темный низ
        
        return LinearGradient(
            colors: [
                topColor.opacity(colorScheme == .dark ? darkOpacity : lightOpacity),     // применяем правильную opacity
                bottomColor.opacity(colorScheme == .dark ? lightOpacity : darkOpacity)   // применяем правильную opacity
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Градиент для колец с правильной инверсией (ИСПРАВЛЕНО)
    func ringGradient(for colorScheme: ColorScheme) -> LinearGradient {
        return LinearGradient(
            colors: colorScheme == .dark
                ? [darkColor, lightColor]   // темная тема: темный → светлый
                : [lightColor, darkColor],  // светлая тема: светлый → темный
            startPoint: .leading,  // для поворота кольца на -90°
            endPoint: .trailing
        )
    }
    
    /// Градиент для кнопок с адаптивной инверсией (ИСПРАВЛЕНО)
    func buttonGradient(
        for colorScheme: ColorScheme,
        lightOpacity: Double = 1.0,
        darkOpacity: Double = 1.0
    ) -> LinearGradient {
        return LinearGradient(
            colors: colorScheme == .dark
                ? [darkColor.opacity(darkOpacity), lightColor.opacity(lightOpacity)]   // темная тема: темный → светлый
                : [lightColor.opacity(lightOpacity), darkColor.opacity(darkOpacity)],  // светлая тема: светлый → темный
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - ✅ СТАНДАРТНЫЕ градиенты (ИСПРАВЛЕНЫ для consistency)
    
    /// Стандартный градиент (ИСПРАВЛЕНО - теперь адаптивный)
    var gradient: LinearGradient {
        return LinearGradient(
            colors: [lightColor, darkColor], // оставляем для backward compatibility, но лучше использовать adaptiveGradient
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Градиент с кастомной прозрачностью (УСТАРЕЛ - используйте adaptiveGradient)
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
    
    /// Получить цвета для градиента с прозрачностью (УСТАРЕЛ)
    func gradientColors(lightOpacity: Double = 1.0, darkOpacity: Double = 1.0) -> [Color] {
        return [
            lightColor.opacity(lightOpacity),
            darkColor.opacity(darkOpacity)
        ]
    }
    
    // MARK: - ✅ ACCESSIBILITY методы (без изменений)
    
    /// Проверить, обеспечивает ли цвет хороший контраст для текста
    func hasGoodTextContrast(in colorScheme: ColorScheme) -> Bool {
        let backgroundColor = colorScheme == .dark ? self.darkColor : self.lightColor
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        return backgroundColor.hasGoodContrast(with: textColor)
    }
    
    /// Получить лучший цвет для текста на этом фоне
    func bestTextColor(in colorScheme: ColorScheme) -> Color {
        let backgroundColor = colorScheme == .dark ? self.darkColor : self.lightColor
        return backgroundColor.bestContrastingTextColor
    }
    
    /// Получить лучший текстовый цвет для градиента
    func bestTextColorForGradient(in colorScheme: ColorScheme) -> Color {
        // Смешиваем светлый и темный цвета для получения среднего
        let lightUIColor = UIColor(lightColor)
        let darkUIColor = UIColor(darkColor)
        
        var lr: CGFloat = 0, lg: CGFloat = 0, lb: CGFloat = 0, la: CGFloat = 0
        var dr: CGFloat = 0, dg: CGFloat = 0, db: CGFloat = 0, da: CGFloat = 0
        
        lightUIColor.getRed(&lr, green: &lg, blue: &lb, alpha: &la)
        darkUIColor.getRed(&dr, green: &dg, blue: &db, alpha: &da)
        
        let avgRed = (lr + dr) / 2
        let avgGreen = (lg + dg) / 2
        let avgBlue = (lb + db) / 2
        
        let averageColor = Color(red: avgRed, green: avgGreen, blue: avgBlue)
        return averageColor.bestContrastingTextColor
    }
}
