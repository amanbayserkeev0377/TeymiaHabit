import SwiftUI

struct RowIcon: View {
    let iconName: String
    
    @ScaledMetric private var backgroundSize: CGFloat = 30
    @ScaledMetric private var iconSize: CGFloat = 16
    @ScaledMetric private var cornerRadius: CGFloat = 8
    
    var body: some View {
        Image(iconName)
            .resizable()
            .frame(width: iconSize, height: iconSize)
            .foregroundStyle(.secondarySurface)
            .frame(width: backgroundSize, height: backgroundSize)
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
    }
}
