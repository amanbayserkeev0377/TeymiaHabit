import SwiftUI

// MARK: - Reusable Color Picker Section Component
struct ColorPickerSection: View {
    @Binding var selectedColor: HabitIconColor
    @State private var customColor = HabitIconColor.customColor
    @ObservedObject private var colorManager = AppColorManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ProManager.self) private var proManager
    
    var columnsCount: Int = 7
    var buttonSize: CGFloat = 32
    var spacing: CGFloat = 12
    var showCustomPicker: Bool = true
    var onProRequired: (() -> Void)? = nil // Callback для показа paywall
    var enableProLocks: Bool = true // Включить Pro замки (false для IconPickerView)
    
    // ✅ Бесплатные цвета (первые 5)
    private let freeColors: Set<HabitIconColor> = [
        .primary, .red, .orange, .yellow, .mint
    ]
    
    // Computed properties
    private var colorColumns: [GridItem] {
        Array(repeating: GridItem(.flexible()), count: columnsCount)
    }
    
    var body: some View {
        LazyVGrid(columns: colorColumns, spacing: spacing) {
            // Regular colors (excluding colorPicker)
            ForEach(colorManager.getAvailableColors().filter { $0 != .colorPicker }, id: \.self) { color in
                colorButton(for: color)
            }
            
            // Custom color picker (if enabled)
            if showCustomPicker {
                customColorPicker
            }
        }
    }
    
    // MARK: - Components
    
    /// Individual color button with circular design, haptic feedback and Pro lock support
    private func colorButton(for color: HabitIconColor) -> some View {
        let isLocked = enableProLocks && !proManager.isPro && !freeColors.contains(color)
        
        return Button {
            if isLocked {
                onProRequired?()
            } else {
                selectedColor = color
                // Add haptic feedback - will work everywhere this component is used
                HapticManager.shared.playSelection()
            }
        } label: {
            ZStack {
                // Base circular color button
                Circle()
                    .fill(color.adaptiveGradient(for: colorScheme, lightOpacity: 0.8, darkOpacity: 1.0))
                    .frame(width: buttonSize, height: buttonSize)
                    .opacity(isLocked ? 0.7 : 1.0) // Слегка приглушаем заблокированные цвета
                    .overlay(
                        // Circular stroke for selected state (bigger, closer to edges)
                        Circle()
                            .strokeBorder(
                                Color.white, 
                                lineWidth: 2
                            )
                            .frame(width: buttonSize * 0.9, height: buttonSize * 0.9)
                            .opacity(selectedColor == color && !isLocked ? 1 : 0)
                            .animation(.easeInOut(duration: 0.2), value: selectedColor == color)
                    )
                
                // Pro lock overlay for circular design
                if isLocked {
                    Circle()
                        .fill(.clear) // Прозрачный фон, чтобы цвет был виден
                        .frame(width: buttonSize, height: buttonSize)
                        .overlay(
                            Image(systemName: "lock.fill")
                                .font(.system(size: buttonSize * 0.5, weight: .medium))
                                .foregroundStyle(.white)
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isLocked ? "Pro color: \(color.rawValue)" : "\(color.rawValue.localized) color")
        .scaleEffect(selectedColor == color && !isLocked ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: selectedColor == color)
    }
    
    /// Custom color picker with Pro lock support
    private var customColorPicker: some View {
        let isLocked = enableProLocks && !proManager.isPro
        
        return ZStack {
            // Base color picker
            ColorPicker("", selection: $customColor)
                .labelsHidden()
                .disabled(isLocked)
                .opacity(isLocked ? 0.7 : 1.0) // Слегка приглушаем заблокированный picker
                .onChange(of: customColor) { _, newColor in
                    if !isLocked {
                        HabitIconColor.customColor = newColor
                        selectedColor = .colorPicker
                        HapticManager.shared.playSelection()
                    }
                }
                .accessibilityLabel(isLocked ? "Pro feature: Custom color picker" : "custom_color_picker".localized)
            
            // Pro lock overlay for custom picker
            if isLocked {
                Button {
                    onProRequired?()
                } label: {
                    Circle()
                        .fill(.clear) // Прозрачный фон
                        .frame(width: buttonSize, height: buttonSize)
                        .overlay(
                            Image(systemName: "lock.fill")
                                .font(.system(size: buttonSize * 0.35, weight: .medium))
                                .foregroundStyle(.white)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Convenience initializers
extension ColorPickerSection {
    /// For IconPickerView usage (без Pro замков)
    static func forIconPicker(selectedColor: Binding<HabitIconColor>) -> ColorPickerSection {
        ColorPickerSection(
            selectedColor: selectedColor,
            columnsCount: 7, // Consistent with iPhone layout
            buttonSize: 32,
            spacing: 12,
            showCustomPicker: true,
            onProRequired: nil,
            enableProLocks: false // ✅ Отключаем замки для выбора цвета иконки привычки
        )
    }
    
    /// For AppColorPickerView usage (с Pro замками)
    static func forAppColorPicker(selectedColor: Binding<HabitIconColor>, onProRequired: (() -> Void)? = nil) -> ColorPickerSection {
        ColorPickerSection(
            selectedColor: selectedColor,
            columnsCount: 7,
            buttonSize: 32,
            spacing: 12,
            showCustomPicker: true,
            onProRequired: onProRequired,
            enableProLocks: true // ✅ Включаем замки для выбора цвета приложения
        )
    }
    
    /// For compact usage (5 columns)
    static func compact(selectedColor: Binding<HabitIconColor>, enableProLocks: Bool = false, onProRequired: (() -> Void)? = nil) -> ColorPickerSection {
        ColorPickerSection(
            selectedColor: selectedColor,
            columnsCount: 5,
            buttonSize: 28,
            spacing: 10,
            showCustomPicker: true,
            onProRequired: onProRequired,
            enableProLocks: enableProLocks
        )
    }
}
