import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
#endif

extension Color {
    private enum Constants {
        static let lightAmount: CGFloat = 0.4
        static let darkAmount: CGFloat = 0.05
    }

    func lightened(by amount: CGFloat) -> Color {
        applyAdjustment(factor: amount)
    }
    
    func darkened(by amount: CGFloat) -> Color {
        applyAdjustment(factor: -amount)
    }
    
    private func applyAdjustment(factor: CGFloat) -> Color {
        let pColor = PlatformColor(self)
        return Color(pColor.adjustedBrightness(by: factor))
    }
    
    var ringGradientPair: (dark: Color, light: Color) {
        (
            self.darkened(by: Constants.darkAmount),
            self.lightened(by: Constants.lightAmount)
        )
    }
}

extension PlatformColor {
    func adjustedBrightness(by factor: CGFloat) -> PlatformColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        #if os(macOS)
        let compatibleColor = self.usingColorSpace(.deviceRGB) ?? self
        compatibleColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        #else
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        #endif
        
        return PlatformColor(
            hue: h,
            saturation: s,
            brightness: max(0, min(1, b + factor)),
            alpha: a
        )
    }
}
