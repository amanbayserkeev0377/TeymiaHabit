#if os(iOS)
import SwiftUI

struct AppIconRow: View {
    var body: some View {
        NavigationLink(destination: AppIconView()) {
            Label(
                title: { Text("settings_app_icon") },
                icon: { RowIcon(iconName: "app.specular") }
            )
        }
    }
}

struct AppIconView: View {
    @Environment(AppIconManager.self) private var appIconManager
    @State private var currentIcon: AppIcon = .main
    
    var body: some View {
        Form {
            Section {
                ForEach(AppIcon.allCases) { icon in
                    Button {
                        iconSelection(icon)
                    } label: {
                        HStack(spacing: 16) {
                            AppIconImage(icon: icon)
                            
                            Text(icon.title)
                                .foregroundStyle(Color.primary)
                            
                            Spacer()
                            
                            if currentIcon == icon {
                                SelectionCheckmark()
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("settings_app_icon")
        .onAppear {
            currentIcon = appIconManager.currentIcon
        }
    }
    
    private func iconSelection(_ icon: AppIcon) {
            appIconManager.setAppIcon(icon)
            withAnimation(.spring()) {
                currentIcon = icon
            }
    }
}

struct AppIconImage: View {
    let icon: AppIcon
    
    var body: some View {
        ZStack {
            Image(icon.previewImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
        }
    }
}
#endif
