import SwiftUI

struct HabitIconView: View {
    let iconName: String?
    let iconColor: HabitIconColor
    let size: CGFloat
    let showBackground: Bool
    
    private let fallbackIcon = "ui-checkmark"
    
    init(
        iconName: String?,
        iconColor: HabitIconColor,
        size: CGFloat = 20,
        showBackground: Bool = true
    ) {
        self.iconName = iconName
        self.iconColor = iconColor
        self.size = size
        self.showBackground = showBackground
    }
    
    private var finalIconName: String {
        guard let name = iconName, !name.isEmpty else { return fallbackIcon }
        
        let cleaned = name
            .replacingOccurrences(of: "sf_", with: "")
            .replacingOccurrences(of: "img_", with: "")
        
        if UIImage(named: cleaned) != nil {
            return cleaned
        } else {
            return fallbackIcon
        }
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
            
            Image(finalIconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundStyle(gradient)
        }
        .frame(width: size * 2, height: size * 2)
    }
}
