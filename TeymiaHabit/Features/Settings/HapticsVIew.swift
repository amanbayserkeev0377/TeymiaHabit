import SwiftUI

struct HapticsRowView: View {
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    
    var body: some View {
        Toggle(isOn: $hapticsEnabled) {
            Label(
                title: { Text("settings_haptics") },
                icon: {
                    Image(systemName: "waveform.badge.checkmark")
                        .iconStyle()
                        .symbolEffect(.variableColor.iterative, value: hapticsEnabled)
                }
            )
        }
    }
}
