import SwiftUI

extension View {
    func adaptiveNumberPad() -> some View {
        #if os(iOS)
        return self.keyboardType(.numberPad)
        #else
        return self
        #endif
    }
    
    // Делаем безопасный стиль пикера
    func adaptiveWheelStyle() -> some View {
        #if os(iOS)
        return self.datePickerStyle(.wheel)
        #else
        return self.datePickerStyle(.field)
        #endif
    }
}
