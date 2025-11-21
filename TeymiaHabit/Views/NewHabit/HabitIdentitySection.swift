import SwiftUI

struct HabitIdentitySection: View {
    @Binding var selectedIcon: String?
    @Binding var selectedColor: HabitIconColor
    @Binding var title: String

    var body: some View {
        Section {
            IconPreviewView(iconName: selectedIcon, color: selectedColor)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
        .listSectionSpacing(14)
        
        Section {
            TextField("habit_name".localized, text: $title)
                .font(.headline)
                .fontDesign(.rounded)
                .multilineTextAlignment(.center)
                .submitLabel(.done)
                .background(Color.mainRowBackground)
        }
        .listRowBackground(Color.mainRowBackground)
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
        HStack {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(color.color.gradient.opacity(0.07))
                    .frame(width: 80, height: 80)
                
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
            
            Spacer()
        }
    }
}
