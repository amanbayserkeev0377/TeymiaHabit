import SwiftUI

#if canImport(UIKit)
import UIKit
typealias NativeColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias NativeColor = NSColor
#endif

enum HabitIconColor: String, CaseIterable, Codable {
    // MARK: - Basic Colors
    case primary, red, orange, yellow, mint, green, blue, purple
    case pink, brown, gray, softLavender, sky, coral, bluePink, oceanBlue
    case antarctica, sweetMorning, lusciousLime, celestial, yellowOrange, cloudBurst, candy, colorPicker
    
    var baseColor: Color {
        switch self {
        case .primary: .appPrimary
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .mint: .mint
        case .green: .green
        case .blue: .blue
        case .purple: .purple
        case .softLavender: .softLavender
        case .pink: .pink
        case .sky: .sky
        case .brown: .brown
        case .gray: .gray
        case .coral: .coral
        case .bluePink: .bluePink
        case .oceanBlue: .oceanBlue
        case .antarctica: .antarctica
        case .sweetMorning: .sweetMorning
        case .lusciousLime: .lusciousLime
        case .celestial: .celestial
        case .yellowOrange: .yellowOrange
        case .cloudBurst: .cloudBurst
        case .candy: .candy
        case .colorPicker: .colorPicker
        }
    }
    
    var lightColor: Color { baseColor.lightened(by: 0.4) }
    var darkColor: Color { baseColor.darkened(by: 0.05) }
}

extension Color {
    func lightened(by amount: CGFloat = 0.2) -> Color {
        applyAdjustment(factor: amount)
    }
    
    func darkened(by amount: CGFloat = 0.2) -> Color {
        applyAdjustment(factor: -amount)
    }
    
    private func applyAdjustment(factor: CGFloat) -> Color {
        #if canImport(UIKit)
        let native = NativeColor(self)
        #elseif canImport(AppKit)
        let native = NativeColor(self)
        #endif
        
        return Color(native.adjustedBrightness(by: factor))
    }
}

extension NativeColor {
    func adjustedBrightness(by factor: CGFloat) -> NativeColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        
        #if canImport(UIKit)
        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return self }
        #elseif canImport(AppKit)
        guard let rgbColor = self.usingColorSpace(.deviceRGB) else { return self }
        rgbColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        #endif
        
        return NativeColor(
            hue: h,
            saturation: s,
            brightness: max(0, min(1, b + factor)),
            alpha: a
        )
    }
}
