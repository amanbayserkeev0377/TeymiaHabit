import SwiftUI

struct SoundRow: View {
    var body: some View {
        NavigationLink(destination: SoundView()) {
            Label(
                title: { Text("settings_sounds") },
                icon: { RowIcon(iconName: "speaker.wave.1") }
            )
        }
    }
}
