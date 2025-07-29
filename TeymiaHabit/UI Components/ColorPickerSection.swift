import SwiftUI

// MARK: - Reusable Color Picker Section Component

/// Configurable color picker grid component with Pro feature support
/// Used in both habit icon selection and app color customization
struct ColorPickerSection: View {
    @Binding var selectedColor: HabitIconColor
    @State private var customColor = HabitIconColor.customColor
    @ObservedObject private var colorManager = AppColorManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ProManager.self) private var proManager
    
    // MARK: - Configuration Properties
    
    var columnsCount: Int = 7
    var buttonSize: CGFloat = 32
    var spacing: CGFloat = 12
    var showCustomPicker: Bool = true
    var onProRequired: (() -> Void)? = nil // Callback for paywall presentation
    var enableProLocks: Bool = true // Enable Pro locks (false for IconPickerView)
    
    // MARK: - Constants
    
    /// Free colors available without Pro subscription
    private let freeColors: Set<HabitIconColor> = [
        .primary, .celestial, .brown, .red, .orange
    ]
    
    private enum DesignConstants {
        static let selectedBorderScale: CGFloat = 0.9
        static let selectedButtonScale: CGFloat = 1.1
        static let lockIconScale: CGFloat = 0.5
        static let customPickerLockScale: CGFloat = 0.35
        static let lockedOpacity: Double = 0.8
        static let animationDuration: Double = 0.2
    }
    
    // MARK: - Computed Properties
    
    private var colorColumns: [GridItem] {
        Array(repeating: GridItem(.flexible()), count: columnsCount)
    }
    
    // MARK: - Body
    
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
    /// - Parameter color: The habit icon color to display
    /// - Returns: A configured color selection button
    private func colorButton(for color: HabitIconColor) -> some View {
        let isLocked = enableProLocks && !proManager.isPro && !freeColors.contains(color)
        let isSelected = selectedColor == color && !isLocked
        
        return Button {
            if isLocked {
                onProRequired?()
            } else {
                selectedColor = color
                HapticManager.shared.playSelection()
            }
        } label: {
            ZStack {
                // Base circular color button
                Circle()
                    .fill(color.adaptiveGradient(for: colorScheme))
                    .frame(width: buttonSize, height: buttonSize)
                    .opacity(isLocked ? DesignConstants.lockedOpacity : 1.0)
                    .overlay(
                        // Selection border
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 2)
                            .frame(
                                width: buttonSize * DesignConstants.selectedBorderScale,
                                height: buttonSize * DesignConstants.selectedBorderScale
                            )
                            .opacity(isSelected ? 1 : 0)
                            .animation(.easeInOut(duration: DesignConstants.animationDuration), value: isSelected)
                    )
                
                // Pro lock overlay
                if isLocked {
                    lockOverlay
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: color, isLocked: isLocked))
        .scaleEffect(isSelected ? DesignConstants.selectedButtonScale : 1.0)
        .animation(.easeInOut(duration: DesignConstants.animationDuration), value: isSelected)
    }
    
    /// Custom color picker with Pro lock support
    private var customColorPicker: some View {
        let isLocked = enableProLocks && !proManager.isPro
        
        return ZStack {
            // Base color picker
            ColorPicker("", selection: $customColor)
                .labelsHidden()
                .disabled(isLocked)
                .onChange(of: customColor) { _, newColor in
                    if !isLocked {
                        HabitIconColor.customColor = newColor
                        selectedColor = .colorPicker
                        HapticManager.shared.playSelection()
                    }
                }
                .accessibilityLabel(customPickerAccessibilityLabel(isLocked: isLocked))
            
            // Pro lock overlay for custom picker
            if isLocked {
                Button {
                    onProRequired?()
                } label: {
                    customPickerLockOverlay
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    /// Lock overlay for regular color buttons
    private var lockOverlay: some View {
        Circle()
            .fill(.clear)
            .frame(width: buttonSize, height: buttonSize)
            .overlay(
                Image(systemName: "lock.fill")
                    .font(.system(size: buttonSize * DesignConstants.lockIconScale, weight: .medium))
                    .foregroundStyle(.white)
            )
    }
    
    /// Lock overlay for custom color picker
    private var customPickerLockOverlay: some View {
        Circle()
            .fill(.clear)
            .frame(width: buttonSize, height: buttonSize)
            .overlay(
                Image(systemName: "lock.fill")
                    .font(.system(size: buttonSize * DesignConstants.customPickerLockScale, weight: .medium))
                    .foregroundStyle(.white)
            )
    }
    
    // MARK: - Helper Methods
    
    /// Generates accessibility label for color button
    /// - Parameters:
    ///   - color: The color being labeled
    ///   - isLocked: Whether the color is locked behind Pro
    /// - Returns: Localized accessibility label
    private func accessibilityLabel(for color: HabitIconColor, isLocked: Bool) -> String {
        if isLocked {
            return "Pro color: \(color.rawValue)"
        } else {
            return "\(color.rawValue.localized) color"
        }
    }
    
    /// Generates accessibility label for custom color picker
    /// - Parameter isLocked: Whether the picker is locked behind Pro
    /// - Returns: Localized accessibility label
    private func customPickerAccessibilityLabel(isLocked: Bool) -> String {
        if isLocked {
            return "Pro feature: Custom color picker"
        } else {
            return "custom_color_picker".localized
        }
    }
}

// MARK: - Convenience Initializers

extension ColorPickerSection {
    /// Creates color picker for habit icon selection (no Pro locks)
    /// - Parameter selectedColor: Binding to the selected color
    /// - Returns: Configured ColorPickerSection for icon selection
    static func forIconPicker(selectedColor: Binding<HabitIconColor>) -> ColorPickerSection {
        ColorPickerSection(
            selectedColor: selectedColor,
            columnsCount: 8,
            buttonSize: 32,
            spacing: 12,
            showCustomPicker: true,
            onProRequired: nil,
            enableProLocks: false // No Pro restrictions for habit icon colors
        )
    }
    
    /// Creates color picker for app color customization (with Pro locks)
    /// - Parameters:
    ///   - selectedColor: Binding to the selected color
    ///   - onProRequired: Callback when Pro feature is accessed
    /// - Returns: Configured ColorPickerSection for app color selection
    static func forAppColorPicker(
        selectedColor: Binding<HabitIconColor>,
        onProRequired: (() -> Void)? = nil
    ) -> ColorPickerSection {
        ColorPickerSection(
            selectedColor: selectedColor,
            columnsCount: 8,
            buttonSize: 32,
            spacing: 12,
            showCustomPicker: true,
            onProRequired: onProRequired,
            enableProLocks: true // Enable Pro restrictions for app colors
        )
    }
}
