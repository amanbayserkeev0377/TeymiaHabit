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
