import SwiftUI

struct HapticsSection: View {
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Toggle(isOn: $hapticsEnabled.animation(.easeInOut(duration: 0.3))) {
            Label(
                title: { Text("haptics".localized) },
                icon: {
                    Image("waveform")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(.red.gradient)
                }
            )
        }
        .withToggleColor()
    }
}
