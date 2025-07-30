import SwiftUI

struct XmarkView: View {
    var action: () -> Void
    
    var size: CGFloat = 30
    var iconColor: Color = Color(.systemGray)
    var backgroundColor: Color = Color(.systemGray5)
    var cornerRadius: CGFloat = 15
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(iconColor)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(backgroundColor)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Extensions

extension View {
    func withDismissButton(onDismiss: @escaping () -> Void) -> some View {
        self.overlay(
            XmarkView(action: onDismiss)
                .padding(.top, 8)
                .padding(.trailing, 8),
            alignment: .topTrailing
        )
    }
}
