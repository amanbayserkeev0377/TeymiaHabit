import SwiftUI

struct HabitIconView: View {
    let iconName: String?
    let color: Color
    var size: CGFloat = 20
    var showBackground: Bool = true
    
    private let fallbackIcon = "checkmark"
    
    private var resolvedIcon: String {
        guard let name = iconName else { return fallbackIcon }
        return IconValidator.isValid(systemName: name) ? name : fallbackIcon
    }
    
    var body: some View {
        ZStack {
            if showBackground {
                Circle()
                    .fill(color.opacity(0.15))
            }
            
            Image(systemName: resolvedIcon)
                .font(.system(size: size))
                .foregroundStyle(color.gradient)
        }
        .frame(width: size * 2, height: size * 2)
    }
}
