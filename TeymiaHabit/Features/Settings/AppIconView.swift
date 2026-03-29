import SwiftUI

struct AppIconRowView: View {
    var body: some View {
        NavigationLink(destination: AppIconView()) {
            Label(
                title: { Text("settings_app_icon") },
                icon: { RowIcon(systemName: "checkmark.app") }
            )
        }
    }
}

struct AppIconView: View {
    @Environment(ProManager.self) private var proManager
    @State private var showingPaywall = false
    @State private var currentIcon: AppIcon = .main
    private let iconManager = AppIconManager.shared
    
    var body: some View {
        List {
            Section {
                ForEach(AppIcon.allCases) { icon in
                    Button {
                        iconSelection(icon)
                    } label: {
                        HStack(spacing: 16) {
                            AppIconImage(
                                icon: icon,
                                isLocked: icon.requiresPro && !proManager.isPro
                            )
                            
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
        .navigationTitle("settings_app_icon")
        .onAppear {
            currentIcon = iconManager.currentIcon
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    private func iconSelection(_ icon: AppIcon) {
        if !proManager.isPro && icon.requiresPro {
            showingPaywall = true
        } else {
            iconManager.setAppIcon(icon)
            withAnimation(.spring()) {
                currentIcon = icon
            }
        }
    }
}

struct AppIconImage: View {
    let icon: AppIcon
    let isLocked: Bool
    
    var body: some View {
        ZStack {
            Image(icon.previewImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .blur(radius: isLocked ? 1.7 : 0)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
        }
        .overlay(alignment: .topTrailing) {
            if isLocked {
                ProIconLock()
                    .offset(x: 6, y: -6)
            }
        }
    }
}
