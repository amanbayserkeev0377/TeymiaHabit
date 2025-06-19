import SwiftUI

// MARK: - Reusable Color Picker Section Component
struct ColorPickerSection: View {
    @Binding var selectedColor: HabitIconColor
    @State private var customColor = HabitIconColor.customColor
    @ObservedObject private var colorManager = AppColorManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var columnsCount: Int = 7
    var buttonSize: CGFloat = 32
    var spacing: CGFloat = 12
    var showCustomPicker: Bool = true
    
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
    
    /// Individual color button (copied from IconPickerView)
    private func colorButton(for color: HabitIconColor) -> some View {
        Button {
            selectedColor = color
        } label: {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color.color)
                .frame(width: buttonSize, height: buttonSize)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .opacity(selectedColor == color ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(color.rawValue.localized) color")
    }
    
    /// Custom color picker (copied from IconPickerView)
    private var customColorPicker: some View {
        ColorPicker("", selection: $customColor)
            .labelsHidden()
            .onChange(of: customColor) { _, newColor in
                HabitIconColor.customColor = newColor
                selectedColor = .colorPicker
            }
            .frame(width: buttonSize, height: buttonSize)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        selectedColor == .colorPicker ? Color.primary : Color.clear, 
                        lineWidth: 2
                    )
            )
            .accessibilityLabel("custom_color_picker".localized)
    }
}

// MARK: - Convenience initializers
extension ColorPickerSection {
    /// For IconPickerView usage (7 columns on iPhone, 10 on iPad)
    static func forIconPicker(selectedColor: Binding<HabitIconColor>) -> ColorPickerSection {
        ColorPickerSection(
            selectedColor: selectedColor,
            columnsCount: 7, // Consistent with iPhone layout
            buttonSize: 32,
            spacing: 12
        )
    }
    
    /// For AppColorPickerView usage (7 columns)
    static func forAppColorPicker(selectedColor: Binding<HabitIconColor>) -> ColorPickerSection {
        ColorPickerSection(
            selectedColor: selectedColor,
            columnsCount: 7,
            buttonSize: 32,
            spacing: 12
        )
    }
    
    /// For compact usage (5 columns)
    static func compact(selectedColor: Binding<HabitIconColor>) -> ColorPickerSection {
        ColorPickerSection(
            selectedColor: selectedColor,
            columnsCount: 5,
            buttonSize: 28,
            spacing: 10
        )
    }
}
