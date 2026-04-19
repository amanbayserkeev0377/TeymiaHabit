import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

enum IconValidator {
    static func isValid(systemName: String) -> Bool {
        #if canImport(UIKit)
        return UIImage(systemName: systemName) != nil
        #elseif canImport(AppKit)
        return NSImage(systemSymbolName: systemName, accessibilityDescription: nil) != nil
        #else
        return true
        #endif
    }
}
