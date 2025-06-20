import SwiftUI

// MARK: - Ring Color Mode Enum
enum RingColorMode: String, CaseIterable {
    case habitColors = "habitColors"     // Use each habit's color
    case appColor = "appColor"           // Use app color
    case customGradient = "customGradient" // Custom gradient
}

final class AppColorManager: ObservableObject {
    static let shared = AppColorManager()
    
    // Existing app color properties
    @Published private(set) var selectedColor: HabitIconColor
    @AppStorage("selectedAppColor") private var selectedColorId: String?
    
    // New ring color properties
    @Published var ringColorMode: RingColorMode = .appColor
    @Published var customGradientColor1: Color = .blue
    @Published var customGradientColor2: Color = .purple
    
    @AppStorage("ringColorMode") private var ringColorModeStorage: String = RingColorMode.appColor.rawValue
    @AppStorage("customGradientColor1Data") private var customGradientColor1Data: Data?
    @AppStorage("customGradientColor2Data") private var customGradientColor2Data: Data?
    
    private let availableColors: [HabitIconColor] = [
        .primary,
        .red,
        .orange,
        .yellow,
        .mint,
        .green,
        .blue,
        .purple,
        .softLavender,
        .pink,
        .sky,
        .brown,
        .gray,
        .colorPicker
    ]
    
    private init() {
        selectedColor = .primary
        
        // Load existing app color
        if let savedColorId = selectedColorId,
           let color = HabitIconColor(rawValue: savedColorId) {
            selectedColor = color
        }
        
        // Load ring color mode
        if let mode = RingColorMode(rawValue: ringColorModeStorage) {
            ringColorMode = mode
        }
        
        // Load custom gradient colors
        loadCustomGradientColors()
    }
    
    // MARK: - Existing Methods
    func setAppColor(_ color: HabitIconColor) {
        selectedColor = color
        selectedColorId = color.rawValue
    }
    
    func getAvailableColors() -> [HabitIconColor] {
        return availableColors
    }
    
    // MARK: - New Ring Color Methods
    func setRingColorMode(_ mode: RingColorMode) {
        ringColorMode = mode
        ringColorModeStorage = mode.rawValue
    }
    
    func setCustomGradientColors(color1: Color, color2: Color) {
        customGradientColor1 = color1
        customGradientColor2 = color2
        saveCustomGradientColors()
    }
    
    // Main method to get ring colors based on current settings
    func getRingColors(isCompleted: Bool, isExceeded: Bool, habit: Habit? = nil) -> [Color] {
        // Always use green colors for completed/exceeded states
        if isCompleted || isExceeded {
            return getCompletedColors(isExceeded: isExceeded)
        }
        
        // For in-progress states, use user's customization
        switch ringColorMode {
        case .habitColors:
            let baseColor = habit?.iconColor.color ?? selectedColor.color
            return generateProgressColors(from: baseColor)
            
        case .appColor:
            return generateProgressColors(from: selectedColor.color)
            
        case .customGradient:
            return generateCustomGradientProgressColors()
        }
    }
    
    // MARK: - Private Helper Methods
    
    // Always green colors for completed/exceeded (hardcoded)
    private func getCompletedColors(isExceeded: Bool) -> [Color] {
        if isExceeded {
            // Darker green for exceeded
            return [
                Color(#colorLiteral(red: 0.1803921569, green: 0.5450980392, blue: 0.3411764706, alpha: 1)),
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1)),
                Color(#colorLiteral(red: 0.1411764706, green: 0.4274509804, blue: 0.2666666667, alpha: 1)),
                Color(#colorLiteral(red: 0.2470588235, green: 0.6196078431, blue: 0.1960784314, alpha: 1)),
                Color(#colorLiteral(red: 0.1803921569, green: 0.5450980392, blue: 0.3411764706, alpha: 1))
            ]
        } else {
            // Regular green for completed
            return [
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1)),
                Color(#colorLiteral(red: 0.1803921569, green: 0.5450980392, blue: 0.3411764706, alpha: 1)),
                Color(#colorLiteral(red: 0.8196078431, green: 1, blue: 0.8352941176, alpha: 1)),
                Color(#colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)),
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1))
            ]
        }
    }
    
    // Generate colors for in-progress state from base color (for big rings)
    private func generateProgressColors(from baseColor: Color) -> [Color] {
        return [
            baseColor.opacity(0.9),  // Dark start
            baseColor,               // Full bright
            baseColor.opacity(0.2),  // Very light
            baseColor.opacity(0.5),  // Medium
            baseColor.opacity(0.9)   // Back to dark for smooth gradient
        ]
    }
    
    // Generate custom gradient colors for in-progress state (for big rings)
    private func generateCustomGradientProgressColors() -> [Color] {
        return [
            customGradientColor1.opacity(0.9),   // Dark start with first color
            customGradientColor1,                 // Full bright first color
            customGradientColor2.opacity(0.3),   // Light second color
            customGradientColor2,                 // Full bright second color
            customGradientColor1.opacity(0.9)    // Back to dark first color (seamless loop)
        ]
    }
    
    // Generate mirrored colors for small rings (day progress items)
    func getMirroredRingColors(isCompleted: Bool, isExceeded: Bool, habit: Habit? = nil) -> [Color] {
        // Always use green colors for completed/exceeded states
        if isCompleted || isExceeded {
            return getCompletedColors(isExceeded: isExceeded)
        }
        
        // For in-progress states, use mirrored version
        switch ringColorMode {
        case .habitColors:
            let baseColor = habit?.iconColor.color ?? selectedColor.color
            return generateMirroredProgressColors(from: baseColor)
            
        case .appColor:
            return generateMirroredProgressColors(from: selectedColor.color)
            
        case .customGradient:
            return generateMirroredCustomGradientProgressColors()
        }
    }

    // Mirrored version for small rings (lighter start)
    private func generateMirroredProgressColors(from baseColor: Color) -> [Color] {
        return [
            baseColor.opacity(0.3),  // Light start
            baseColor.opacity(0.5),  // Medium
            baseColor.opacity(0.9),  // Dark
            baseColor,               // Full bright
            baseColor.opacity(0.3)   // Back to light for smooth cycle
        ]
    }

    // Mirrored custom gradient for small rings (starts with second color)
    private func generateMirroredCustomGradientProgressColors() -> [Color] {
        return [
            customGradientColor2.opacity(0.4),   // Light start with second color
            customGradientColor2.opacity(0.7),   // Medium second color
            customGradientColor1.opacity(0.3),   // Light first color
            customGradientColor1,                 // Full bright first color
            customGradientColor2.opacity(0.4)    // Back to light second color (seamless loop)
        ]
    }
    
    // MARK: - Color Data Persistence
    private func saveCustomGradientColors() {
        if let color1Data = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(customGradientColor1), requiringSecureCoding: false) {
            customGradientColor1Data = color1Data
        }
        
        if let color2Data = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(customGradientColor2), requiringSecureCoding: false) {
            customGradientColor2Data = color2Data
        }
    }
    
    private func loadCustomGradientColors() {
        if let color1Data = customGradientColor1Data,
           let uiColor1 = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: color1Data) {
            customGradientColor1 = Color(uiColor1)
        }
        
        if let color2Data = customGradientColor2Data,
           let uiColor2 = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: color2Data) {
            customGradientColor2 = Color(uiColor2)
        }
    }
    
    // MARK: - UI Component Colors (не кольца!)
    func getComponentColor(for habit: Habit? = nil) -> Color {
        switch ringColorMode {
        case .habitColors:
            // Для Habit Colors - используем цвет привычки
            return habit?.iconColor.color ?? selectedColor.color
            
        case .appColor, .customGradient:
            // Для App Theme и Custom Gradient - всегда цвет приложения
            // (Custom Gradient применяется только к кольцам, компоненты остаются app color)
            return selectedColor.color
        }
    }
}
