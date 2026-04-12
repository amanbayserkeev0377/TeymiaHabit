import SwiftUI

struct AppearanceView: View {
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    
    var body: some View {
        List {
            Section {
                ForEach(ThemeMode.allCases, id: \.self) { mode in
                    Button {
                        themeMode = mode
                    } label: {
                        HStack {
                            Label(
                                title: { Text(mode.localizedName).foregroundStyle(Color.primary) },
                                icon: {
                                    RowIcon(iconName: mode.iconName)
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
        case .system: "iphone"
        case .light:  "sun.max"
        case .dark:   "moon.stars"
        }
    }
}
