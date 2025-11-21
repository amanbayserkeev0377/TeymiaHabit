import SwiftUI

struct ThemeOption {
    let name: String
    let iconName: String
    
    static let system = ThemeOption(name: "appearance_system".localized, iconName: "circle.half")
    static let light = ThemeOption(name: "appearance_light".localized, iconName: "sun")
    static let dark = ThemeOption(name: "appearance_dark".localized, iconName: "moon")
    
    static let allOptions = [system, light, dark]
}

struct AppearanceSection: View {
    @ObservedObject private var colorManager = AppColorManager.shared
    @Environment(ProManager.self) private var proManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationLink {
            AppColorPickerView()
        } label: {
            HStack {
                Label(
                    title: { Text("appearance".localized) },
                    icon: {
                        Image("paintbrush")
                            .settingsIcon()
                    }
                )
                
                Spacer()
                
                Circle()
                    .fill(colorManager.selectedColor.color.gradient)
                    .frame(width: 22, height: 22)
            }
        }
    }
}

struct AppColorPickerView: View {
    @ObservedObject private var colorManager = AppColorManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ProManager.self) private var proManager
    @State private var showingPaywall = false
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    
    // Direct access to AppIconManager without @ObservedObject
    private let iconManager = AppIconManager.shared
    @State private var currentIcon: AppIcon = .main
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(ThemeMode.allCases, id: \.self) { mode in
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                themeMode = mode
                            }
                            HapticManager.shared.playSelection()
                        } label: {
                            HStack {
                                Label(
                                    title: { Text(ThemeOption.allOptions[mode.rawValue].name) },
                                    icon: {
                                        Image(ThemeOption.allOptions[mode.rawValue].iconName)
                                            .resizable()
                                            .frame(width: 16, height: 16)
                                            .foregroundStyle(Color.primary)
                                    }
                                )
                                Spacer()
                                Image("check")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .withAppGradient()
                                    .opacity(themeMode == mode ? 1 : 0)
                                    .animation(.easeInOut, value: themeMode == mode)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("appearance_mode".localized)
                }
                .listRowBackground(Color.mainRowBackground)
                
                Section {
                    ColorPickerSection.forAppColorPicker(
                        selectedColor: Binding(
                            get: { colorManager.selectedColor },
                            set: { colorManager.setAppColor($0) }
                        ),
                        onProRequired: {
                            showingPaywall = true
                        }
                    )
                } header: {
                    Text("app_color".localized)
                }
                .listRowBackground(Color.mainRowBackground)
                
                Section {
                    AppIconGridView(
                        selectedIcon: currentIcon,
                        onIconSelected: { icon in
                            let isLocked = !proManager.isPro && icon.requiresPro
                            if isLocked {
                                showingPaywall = true
                            } else {
                                iconManager.setAppIcon(icon)
                                currentIcon = icon
                            }
                        },
                        onProRequired: {
                            showingPaywall = true
                        }
                    )
                } header: {
                    Text("app_icon".localized)
                }
                .listRowBackground(Color.mainRowBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Color.mainGroupBackground)
            .navigationTitle("appearance".localized)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                currentIcon = iconManager.currentIcon
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }
}

// MARK: - App Icon Components

struct AppIconGridView: View {
    let selectedIcon: AppIcon
    let onIconSelected: (AppIcon) -> Void
    let onProRequired: () -> Void
    
    @Environment(ProManager.self) private var proManager
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(AppIcon.allIcons, id: \.id) { icon in
                AppIconButton(
                    icon: icon,
                    isSelected: selectedIcon.id == icon.id,
                    isLocked: !proManager.isPro && icon.requiresPro,
                    onTap: {
                        onIconSelected(icon)
                    }
                )
            }
        }
        .padding(.vertical, 8)
    }
}

struct AppIconButton: View {
    @ObservedObject private var colorManager = AppColorManager.shared
    
    let icon: AppIcon
    let isSelected: Bool
    let isLocked: Bool
    let onTap: () -> Void
    
    private let iconSize: CGFloat = 60
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Image(icon.previewImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize, height: iconSize)
                        .opacity(isLocked ? 0.7 : 1.0)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isSelected && !isLocked ? colorManager.selectedColor.color : Color.clear,
                                    lineWidth: 1.5
                                )
                                .frame(width: iconSize * 1.05, height: iconSize * 1.05)
                        )
                    
                    if isLocked {
                        VStack {
                            ProLockBadge()
                                .scaleEffect(0.7)
                            Spacer()
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
