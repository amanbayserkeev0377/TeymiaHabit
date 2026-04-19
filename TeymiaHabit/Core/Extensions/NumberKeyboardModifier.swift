import SwiftUI

struct NumberKeyboardModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content.keyboardType(.numberPad)
        #else
        content
        #endif
    }
}

extension View {
    func numberKeyboardOnly() -> some View {
        self.modifier(NumberKeyboardModifier())
    }
}
