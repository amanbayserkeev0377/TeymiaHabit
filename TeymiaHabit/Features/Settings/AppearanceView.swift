import SwiftUI

struct AppearanceRowView: View {
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    
    var body: some View {
        NavigationLink(destination: AppearanceView()) {
            HStack {
                Label(
                    title: { Text("settings_appearance") },
                    icon: { Image(systemName: "moon.stars").iconStyle(reversed: true) }
                )
                Spacer()
                Text(themeMode.localizedName).foregroundStyle(Color.secondary)
            }
        }
    }
}

struct AppearanceView: View {
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        List {
            Section {
                ForEach(ThemeMode.allCases, id: \.self) { mode in
                    Button {
                        themeMode = mode
                        HapticManager.shared.playSelection()
                    } label: {
                        HStack {
                            Label(
                                title: { Text(mode.localizedName).foregroundStyle(Color.primary) },
                                icon: {
                                    Image(systemName: mode.iconName)
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(Color.primary.gradient)
                                }
                            )
                            Spacer()
                            if themeMode == mode { SelectionCheckmark() }
                        }
                    }
                }
            }
            .animation(.snappy, value: themeMode)
            .listRowBackground(Color.rowBackground)
            
            // Theme
            Section {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Button {
                        withAnimation(.snappy) {
                            themeManager.currentTheme = theme
                        }
                        HapticManager.shared.playSelection()
                    } label: {
                        HStack {
                            Text(theme.localizedName).foregroundStyle(Color.primary)
                            
                            Spacer()
                            
                            if themeManager.currentTheme == theme { SelectionCheckmark() }
                        }
                    }
                }
            } header: {
                Text("appearance_theme")
            }
            .listRowBackground(Color.rowBackground)
        }
        .appBackground()
        .navigationTitle("settings_appearance")
    }
}

// MARK: - UI Helpers
struct AppBackground: ViewModifier {
    let type: ThemeBackgroundType
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(type == .main ? Color.mainBackground : Color.groupedBackground)
    }
}

extension View {
    func appBackground(_ type: ThemeBackgroundType = .grouped) -> some View {
        self.modifier(AppBackground(type: type))
    }
}

extension Color {
    static var mainBackground: Color { Color(ThemeManager.shared.colorName(for: "Background")) }
    static var rowBackground: Color { Color(ThemeManager.shared.colorName(for: "RowBackground")) }
    static var groupedBackground: Color { Color(ThemeManager.shared.colorName(for: "GroupedBackground")) }
}

enum ThemeBackgroundType { case main, grouped }
