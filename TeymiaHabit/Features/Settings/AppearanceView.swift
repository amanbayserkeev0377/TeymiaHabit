import SwiftUI

struct AppearanceRowView: View {
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    
    var body: some View {
        NavigationLink(destination: AppearanceView()) {
            HStack {
                Label(
                    title: { Text("settings_appearance") },
                    icon: { RowIcon(systemName: themeMode.iconName) }
                )
                Spacer()
                Text(themeMode.localizedName).foregroundStyle(Color.secondary)
            }
        }
    }
}

struct AppearanceView: View {
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    
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
                                        .font(.footnote)
                                        .fontWeight(.medium)
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
        }
        .navigationTitle("settings_appearance")
    }
}

enum ThemeMode: Int, CaseIterable {
    case system = 0, light, dark
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var localizedName: LocalizedStringResource {
        switch self {
        case .system: "appearance_system"
        case .light:  "appearance_light"
        case .dark:   "appearance_dark"
        }
    }
    
    var iconName: String {
        switch self {
        case .system: "swirl.circle.righthalf.filled"
        case .light:  "sun.max"
        case .dark:   "moon.stars"
        }
    }
}
