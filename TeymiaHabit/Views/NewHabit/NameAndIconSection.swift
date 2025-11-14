import SwiftUI

struct HabitIdentitySection: View {
    @Binding var selectedIcon: String?
    @Binding var selectedColor: HabitIconColor
    @Binding var title: String
    
    let onShowPaywall: () -> Void

    @State private var showingIconPicker = false

    var body: some View {
        VStack(spacing: 20) {
            Button {
                HapticManager.shared.playSelection()
                showingIconPicker = true
            } label: {
                IconPreviewView(iconName: selectedIcon, color: selectedColor)
            }
            .buttonStyle(.plain)
            
            TextField("habit_name".localized, text: $title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(Color(.secondarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingIconPicker) {
            IconPickerView(
                selectedIcon: $selectedIcon,
                selectedColor: $selectedColor,
                onShowPaywall: onShowPaywall
            )
        }
    }
}

struct IconPreviewView: View {
    let iconName: String?
    let color: HabitIconColor
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.color.gradient.opacity(0.1))
                .frame(width: 80, height: 80)
                .shadow(color: color.color.opacity(0.5), radius: 10, x: 0, y: 5)
            
            Image(iconName ?? "check")
                .resizable()
                .frame(width: 36, height: 36)
                .foregroundStyle(color.color.gradient)
        }
    }
}
