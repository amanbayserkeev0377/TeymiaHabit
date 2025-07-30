import Foundation
import SwiftUI
import CryptoKit

@Observable
final class PinManager {
    static let shared = PinManager()
    
    private let pinKey = "user_pin_hash"
    private let pinEnabledKey = "pin_enabled"
    
    var isPinEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: pinEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: pinEnabledKey) }
    }
    
    var hasPinSet: Bool {
        UserDefaults.standard.string(forKey: pinKey) != nil
    }
    
    private init() {}
    
    // MARK: - PIN Management
    
    func setPin(_ pin: String) {
        let hashedPin = hashPin(pin)
        UserDefaults.standard.set(hashedPin, forKey: pinKey)
        isPinEnabled = true
    }
    
    func validatePin(_ pin: String) -> Bool {
        guard let storedHash = UserDefaults.standard.string(forKey: pinKey) else {
            return false
        }
        
        return hashPin(pin) == storedHash
    }
    
    func removePin() {
        UserDefaults.standard.removeObject(forKey: pinKey)
        isPinEnabled = false
    }
    
    // MARK: - Private Methods
    
    private func hashPin(_ pin: String) -> String {
        let data = Data(pin.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - PIN Authentication Manager

@Observable
final class PinAuthManager {
    func handlePinEntry(_ pin: String, onShake: @escaping () -> Void) -> Bool {
        if PinManager.shared.validatePin(pin) {
            HapticManager.shared.playSelection()
            return true
        } else {
            HapticManager.shared.play(.error)
            onShake()
            return false
        }
    }
}
