import SwiftUI

struct FloatingAddButton: View {
    
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.primaryInverse)
                .padding(14)
        }
        .buttonStyle(.plain)
        .contentShape(.circle)
        .glassEffect(.clear.interactive().tint(Color.primary), in: .circle)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
