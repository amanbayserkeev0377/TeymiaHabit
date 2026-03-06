import SwiftUI

struct ProStatisticsOverlay: View {
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap()
                }
            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.primary)
                    .frame(width: 60, height: 60)
                    .buttonStyle(.glass)
            }
            .allowsHitTesting(false)
        }
        .background {
            TransparentBlurView(removeAllFilters: true)
                .blur(radius: 4, opaque: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
