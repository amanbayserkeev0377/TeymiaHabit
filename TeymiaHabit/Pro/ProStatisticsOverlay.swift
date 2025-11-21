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
                Image("lock")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(ProGradientColors.gradient(startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            }
            .allowsHitTesting(false)
        }
        .background {
            TransparentBlurView(removeAllFilters: true)
                .blur(radius: 2, opaque: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
