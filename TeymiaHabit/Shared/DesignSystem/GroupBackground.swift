import SwiftUI

struct GroupBackground: ViewModifier {
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(color)
    }
}

extension View {
    func groupBackground(_ color: Color = .group) -> some View {
        modifier(GroupBackground(color: color))
    }
}
