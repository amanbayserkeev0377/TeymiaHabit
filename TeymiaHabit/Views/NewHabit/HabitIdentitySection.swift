import SwiftUI

struct HabitIdentitySection: View {
    @Binding var selectedIcon: String?
    @Binding var selectedColor: HabitIconColor
    @Binding var title: String

    var body: some View {
        VStack(spacing: 20) {
            IconPreviewView(iconName: selectedIcon, color: selectedColor)
            
            TextField("habit_name".localized, text: $title)
                .font(.title2)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .multilineTextAlignment(.center)
                .submitLabel(.done)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.vertical, 8)
    }
}

struct IconPreviewView: View {
    let iconName: String?
    let color: HabitIconColor
    
    private var isEmoji: Bool {
        guard let icon = iconName else { return false }
        return icon.count == 1
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.color.gradient.opacity(0.1))
                .frame(width: 80, height: 80)
                .shadow(color: color.color.opacity(0.8), radius: 10, x: 0, y: 4)
            
            if isEmoji {
                Text(iconName ?? "✓")
                    .font(.system(size: 40))
            } else {
                Image(iconName ?? "check")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .foregroundStyle(color.color.gradient)
            }
        }
    }
}
