import SwiftUI

struct HabitIconView: View {
    let iconName: String?
    let iconColor: HabitIconColor
    var size: CGFloat = 20
    var showBackground: Bool = true
    
    private let fallbackIcon = "checkmark"
    
    // Check if icon exists as SF Symbol, otherwise use fallback
    private var resolvedIcon: String {
        guard let name = iconName else { return fallbackIcon }
        if UIImage(systemName: name) != nil {
            return name
        }
        return fallbackIcon
    }
        
    var body: some View {
        let gradient = LinearGradient(
            colors: [iconColor.lightColor, iconColor.darkColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        ZStack {
            if showBackground {
                Circle()
                    .fill(gradient.opacity(0.1))
            }
            
            Image(systemName: resolvedIcon)
                .font(.system(size: size))
                .foregroundStyle(gradient)
        }
        .frame(width: size * 2, height: size * 2)
    }
}
