import SwiftUI

struct ProStatisticsOverlay: View {
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(ProGradientColors.gradient(startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            onTap()
        }
    }
}
