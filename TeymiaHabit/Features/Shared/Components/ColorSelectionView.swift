import SwiftUI

struct ColorSelectionView: View {
    @Binding var selectedColor: HabitIconColor
    
    var buttonSize: CGFloat = 32
    var spacing: CGFloat = 12
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: spacing) {
                ForEach(HabitIconColor.allCases, id: \.self) { iconColor in
                    colorButton(for: iconColor)
                }
            }
            .padding(24)
        }
        .frame(height: buttonSize + 36)
        .glassEffect(.clear.interactive(false), in: .capsule)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        .clipShape(.capsule)
        .padding()
    }
    
    private func colorButton(for color: HabitIconColor) -> some View {
        
        let isSelected = selectedColor == color
        
        return Button {
            selectedColor = color
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.lightColor, color.darkColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)
                    )
                    .frame(width: buttonSize, height: buttonSize)
                    .overlay(
                        Circle()
                            .strokeBorder(.primaryInverse, lineWidth: 2)
                            .frame(width: buttonSize * 0.9, height: buttonSize * 0.9)
                            .opacity(isSelected ? 1 : 0)
                    )
                    .scaleEffect(isSelected ? 1.07 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
        }
        .buttonStyle(.plain)
    }
    
}
