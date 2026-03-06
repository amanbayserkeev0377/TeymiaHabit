import SwiftUI

extension Image {
    func iconStyle(reversed: Bool = false) -> some View {
        let primary = reversed ? Color.blackGray.gradient : Color.orangeWhite.gradient
        let secondary = reversed ? Color.orangeWhite.gradient : Color.blackGray.gradient
        
        return self
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .symbolRenderingMode(.palette)
            .foregroundStyle(primary, secondary)
    }
}
