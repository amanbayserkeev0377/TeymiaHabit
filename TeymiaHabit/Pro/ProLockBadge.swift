import SwiftUI

struct ProLockBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image("lock")
                .resizable()
                .frame(width: 12, height: 12)
                .foregroundStyle(.white)
            
            Text("PRO")
                .font(.caption2)
                .fontDesign(.rounded)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(ProGradientColors.gradient(startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
