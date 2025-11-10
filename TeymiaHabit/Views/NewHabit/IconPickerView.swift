import SwiftUI

// MARK: - Icon Picker View

struct IconPickerView: View {
    @Binding var selectedIcon: String?
    @Binding var selectedColor: HabitIconColor
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(ProManager.self) private var proManager
    @ObservedObject private var colorManager = AppColorManager.shared
    
    let onShowPaywall: () -> Void
    
    private let defaultIcon = "check"
    
    // MARK: - Adaptive Properties
    
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible()), count: 7)
    }
    
    private var buttonSize: CGFloat {
        horizontalSizeClass == .compact ? 44 : 52
    }
    
    private func isSelected(_ icon: String) -> Bool {
        selectedIcon == icon
    }
    
    // MARK: - Data
    
    // Add your icon names here as they appear in Assets
    private let icons: [String] = [
        "check", "star", "heart", "flame"
        // TODO: Add more icons from Assets
    ]
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(icons, id: \.self) { icon in
                        iconButton(for: icon)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
            
            VStack(spacing: 16) {
                ColorPickerSection.forIconPicker(selectedColor: $selectedColor)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .primary.opacity(0.2), radius: 20, x: 0, y: -10)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .navigationTitle("icon_and_color".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedIcon == nil {
                selectedIcon = defaultIcon
            }
        }
    }
    
    // MARK: - View Components
    
    private func iconImage(for icon: String) -> some View {
        Group {
            if let uiImage = UIImage(named: icon) {
                Image(uiImage: uiImage)
                    .resizable()
            } else {
                // Fallback to default icon
                Image(defaultIcon)
                    .resizable()
            }
        }
    }
    
    private func iconButton(for icon: String) -> some View {
        let isSelected = isSelected(icon)
        
        return Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedIcon = icon
            }
            HapticManager.shared.playSelection()
        } label: {
            iconImage(for: icon)
                .frame(width: buttonSize * 0.6, height: buttonSize * 0.6)
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            isSelected
                            ? selectedColor.color.opacity(0.1)
                            : Color(UIColor.secondarySystemGroupedBackground)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            isSelected ? selectedColor.color : Color(.separator).opacity(0.5),
                            lineWidth: isSelected ? 1.5 : 0.7
                        )
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
