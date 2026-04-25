import SwiftUI

struct CustomSection<Content: View>: View {
    let title: String?
    let content: Content
    
    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title = title {
                Text(title.uppercased())
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
            }
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.rowBackground)
            .clipShape(.rect(cornerRadius: 24))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
    }
}

struct CustomRow<RightContent: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let action: (() -> Void)?
    let showChevron: Bool
    let rightContent: RightContent
    
    @ScaledMetric private var chevronSize: CGFloat = 14
    
    init(
        title: String,
        icon: String,
        iconColor: Color = .primary,
        action: (() -> Void)? = nil,
        showChevron: Bool = true,
        @ViewBuilder rightContent: () -> RightContent = { EmptyView() }
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.action = action
        self.showChevron = showChevron
        self.rightContent = rightContent()
    }
    
    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 16) {
                RowIcon(iconName: icon)
                
                Text(LocalizedStringKey(title))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                rightContent
                
                if showChevron {
                    Image("ui-chevron.right")
                        .resizable()
                        .frame(width: chevronSize, height: chevronSize)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(.rect)
        }
        .buttonStyle(RowButtonStyle(isEnabled: action != nil))
        .disabled(action == nil)
    }
}

struct RowButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(isEnabled && configuration.isPressed ? Color.primary.opacity(0.05) : Color.clear)
    }
}

struct CustomDivider: View {
    var body: some View {
        Rectangle()
            .fill(.primary.opacity(0.1))
            .frame(height: 1)
            .padding(.leading, 54)
            .padding(.trailing, 16)
    }
}
