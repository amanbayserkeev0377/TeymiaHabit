import SwiftUI

struct HapticsRowView: View {
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    
    var body: some View {
        Toggle(isOn: $hapticsEnabled) {
            Label(
                title: { Text("settings_haptics") },
                icon: {
                    RowIcon(systemName: "waveform")
                        .symbolEffect(.variableColor.iterative, value: hapticsEnabled)
                }
            )
        }
    }
}
