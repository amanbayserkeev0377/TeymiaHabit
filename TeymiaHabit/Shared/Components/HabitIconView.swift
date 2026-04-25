import SwiftUI

struct HabitIconView: View {
    let iconName: String?
    let color: Color
    var size: CGFloat = 20
    var showBackground: Bool = true
    
    private let fallbackIcon = "book"
    
    private var resolvedIcon: String {
        guard let name = iconName, !name.isEmpty else { return fallbackIcon }
        
        return UIImage(systemName: name) != nil ? name : fallbackIcon
    }
    
    var body: some View {
        ZStack {
            if showBackground {
                Circle()
                    .fill(color.opacity(0.15))
            }
            
            iconImage
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundStyle(color.gradient)
        }
        .frame(width: size * 2, height: size * 2)
    }
    
    @ViewBuilder
    private var iconImage: some View {
        if let name = iconName, !name.isEmpty {
            if UIImage(named: name) != nil {
                Image(name)
                    .resizable()
            } else if UIImage(systemName: name) != nil {
                Image(systemName: name)
                    .font(.system(size: size))
            } else {
                Image(systemName: fallbackIcon)
                    .font(.system(size: size))
            }
        } else {
            Image(systemName: fallbackIcon)
                .font(.system(size: size))
        }
    }
}
