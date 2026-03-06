import SwiftUI

struct ProLockBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.system(size: 12))
                .foregroundStyle(.white.gradient)
            
            Text("PRO")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.white.gradient)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(ProGradientColors.gradient())
        .clipShape(Capsule())
    }
}

struct ProIconLock: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(ProGradientColors.gradient())
                .frame(width: 20, height: 20)
            
            Image(systemName: "lock.fill")
                .font(.system(size: 10))
                .foregroundStyle(.white.gradient)
        }
        .overlay {
            Circle()
                .stroke(Color.rowBackground, lineWidth: 2)
                .frame(width: 20, height: 20)
        }
    }
}
