import SwiftUI

struct ColorPickerSection: View {
    @Binding var selectedColor: HabitIconColor
    @Environment(AppColorManager.self) private var colorManager
    @Environment(ProManager.self) private var proManager
    
    var columnsCount: Int = 8
    var buttonSize: CGFloat = 32
    var spacing: CGFloat = 12
    var onProRequired: (() -> Void)? = nil
    var enableProLocks: Bool = true
    var isForAppColor: Bool
    
    private let freeColors: Set<HabitIconColor> = [
        .primary, .gray, .red, .orange, .yellow
    ]
    
    private var colorColumns: [GridItem] {
        Array(repeating: GridItem(.flexible()), count: columnsCount)
    }
    
    var body: some View {
        LazyVGrid(columns: colorColumns, spacing: spacing) {
            ForEach(colorManager.getAvailableColors().filter { $0 != .colorPicker }, id: \.self) { color in
                colorButton(for: color)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func colorButton(for color: HabitIconColor) -> some View {
        let isLocked = enableProLocks && !proManager.isPro && !freeColors.contains(color)
        let isSelected = selectedColor == color && !isLocked
        
        let backgroundStyle: AnyShapeStyle = if isForAppColor {
            AnyShapeStyle(color.color)
        } else {
            AnyShapeStyle(LinearGradient(
                colors: [color.lightColor, color.darkColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        }
        
        return Button {
            if isLocked {
                onProRequired?()
            } else {
                selectedColor = color
                HapticManager.shared.playSelection()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(backgroundStyle)
                    .frame(width: buttonSize, height: buttonSize)
                    .opacity(isLocked ? 0.6 : 1.0)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.primaryInverse, lineWidth: 2)
                            .frame(width: buttonSize * 0.9, height: buttonSize * 0.9)
                            .opacity(isSelected ? 1 : 0)
                    )
                
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: buttonSize * 0.6))
                        .foregroundStyle(.white.gradient)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - Extensions

extension ColorPickerSection {
    static func forIconPicker(selectedColor: Binding<HabitIconColor>) -> ColorPickerSection {
        ColorPickerSection(
            selectedColor: selectedColor,
            columnsCount: 6,
            buttonSize: 44,
            spacing: 12,
            onProRequired: nil,
            enableProLocks: false,
            isForAppColor: false
        )
    }
}
