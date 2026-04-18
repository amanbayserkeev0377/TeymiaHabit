import SwiftUI

struct AppBackground: ViewModifier {
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(color)
    }
}

extension View {
    func appBackground(_ color: Color = .groupBackground) -> some View {
        modifier(AppBackground(color: color))
    }
}
