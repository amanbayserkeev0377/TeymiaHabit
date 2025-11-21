import SwiftUI

extension Image {
    func settingsIcon() -> some View {
        self
            .resizable()
            .frame(width: 18, height: 18)
            .foregroundStyle(Color.primary)
    }
}
