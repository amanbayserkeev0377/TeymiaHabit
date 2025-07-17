import SwiftUI

// MARK: - Universal Icon Extension

extension View {
    @ViewBuilder
    func universalIcon(
        iconId: String?,
        baseSize: CGFloat,
        color: HabitIconColor,
        colorScheme: ColorScheme
    ) -> some View {
        let safeIconId = iconId ?? "checkmark"
        
        if safeIconId.hasPrefix("sf_") {
            // SF Symbol
            let symbolName = String(safeIconId.dropFirst(3))
            Image(systemName: symbolName)
                .font(.system(size: baseSize, weight: .medium))
                .foregroundStyle(color.adaptiveGradient(for: colorScheme))
        } else if safeIconId.hasPrefix("img_") {
            // 3D Image
            let imageName = String(safeIconId.dropFirst(4))
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: baseSize * 1.6, height: baseSize * 1.6)
        } else {
            // Fallback: treat as SF Symbol
            Image(systemName: safeIconId)
                .font(.system(size: baseSize, weight: .medium))
                .foregroundStyle(color.adaptiveGradient(for: colorScheme))
        }
    }
}
