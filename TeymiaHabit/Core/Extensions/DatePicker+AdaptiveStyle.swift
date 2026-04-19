import SwiftUI

extension View {
    func adaptiveWheelStyle() -> some View {
        #if os(iOS)
        return self.datePickerStyle(.wheel)
        #else
        return self.datePickerStyle(.field)
        #endif
    }
}
