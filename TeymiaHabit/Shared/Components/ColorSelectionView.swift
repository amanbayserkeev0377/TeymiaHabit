import SwiftUI

struct ColorSelectionView: View {
    @Binding var selectedColor: HabitIconColor
    @Binding var hexColor: String?
    @State private var pickedColor: Color = .red
    
    var buttonSize: CGFloat = 32
    var spacing: CGFloat = 12
    
    private var displayColors: [HabitIconColor] {
        HabitIconColor.allCases.filter { $0 != .colorPicker }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: spacing) {
                    ForEach(displayColors, id: \.self) { iconColor in
                        colorButton(for: iconColor)
                    }
                }
                .padding(.horizontal, 16)
                .onAppear {
                    if let hex = hexColor {
                        pickedColor = Color(hex: hex)
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 16)
            
            ColorPicker("", selection: $pickedColor)
                .scaleEffect(1.2)
                .labelsHidden()
                .overlay(
                    Circle()
                        .strokeBorder(Color(.systemBackground), lineWidth: 2)
                        .frame(width: buttonSize * 0.9, height: buttonSize * 0.9)
                        .opacity(hexColor != nil ? 1 : 0)
                )
                .onChange(of: pickedColor) { _, newValue in
                    withAnimation {
                        hexColor = newValue.toHex()
                    }
                }
                .padding(.horizontal, 16)
        }
        .frame(height: buttonSize + 36)
        .glassEffect(.regular.interactive(false), in: .capsule)
        .sensoryFeedback(.selection, trigger: selectedColor)
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 4)
        .clipShape(.capsule)
    }
    
    private func colorButton(for color: HabitIconColor) -> some View {
        let isSelected = selectedColor == color && hexColor == nil
        
        return Button {
            withAnimation {
                selectedColor = color
                hexColor = nil
            }
        } label: {
            Circle()
                .fill(color.baseColor)
                .frame(width: buttonSize, height: buttonSize)
                .overlay(
                    Circle()
                        .strokeBorder(Color(.systemBackground), lineWidth: 2)
                        .frame(width: buttonSize * 0.9, height: buttonSize * 0.9)
                        .opacity(isSelected ? 1 : 0)
                )
                .scaleEffect(isSelected ? 1.07 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain)
        .contentShape(.circle)
    }
}
