import SwiftUI

/// Reusable habit icon view component
/// Supports both Asset images and emoji characters
/// Default: 24pt icon with 48pt circle background (HIG compliant touch target)
struct HabitIconView: View {
    let iconName: String?
    let color: HabitIconColor
    let size: CGFloat
    let showBackground: Bool
    
    init(
        iconName: String?,
        color: HabitIconColor,
        size: CGFloat = 22,
        showBackground: Bool = true
    ) {
        self.iconName = iconName
        self.color = color
        self.size = size
        self.showBackground = showBackground
    }
    
    // Clean icon name from old formats (sf_, img_) and fallback to "check"
    private var cleanIconName: String {
        guard let iconName = iconName, !iconName.isEmpty else {
            return "check"
        }
        
        // Remove old prefixes
        let cleaned = iconName
            .replacingOccurrences(of: "sf_", with: "")
            .replacingOccurrences(of: "img_", with: "")
        
        // If it's an old SF Symbol name (contains dots), use fallback
        if cleaned.contains(".") {
            return "check"
        }
        
        return cleaned
    }
    
    private var isEmoji: Bool {
        cleanIconName.count == 1
    }
    
    var body: some View {
        Group {
            if isEmoji {
                Text(cleanIconName)
                    .font(.system(size: size))
            } else {
                Image(cleanIconName)
                    .resizable()
                    .frame(width: size, height: size)
                    .foregroundStyle(color.color.gradient)
            }
        }
        .frame(width: size * 1.8, height: size * 1.8)
        .background(
            Group {
                if showBackground {
                    Circle()
                        .fill(color.color.gradient.opacity(0.07))
                }
            }
        )
    }
}
