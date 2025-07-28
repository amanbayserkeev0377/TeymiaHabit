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
    
    func setPin(_ pin: String) {
        let hashedPin = hashPin(pin)
        UserDefaults.standard.set(hashedPin, forKey: pinKey)
        isPinEnabled = true
        print("🔐 PIN set successfully")
    }
    
    func validatePin(_ pin: String) -> Bool {
        guard let storedHash = UserDefaults.standard.string(forKey: pinKey) else {
            return false
        }
        
        let enteredHash = hashPin(pin)
        let isValid = enteredHash == storedHash
        print("🔐 PIN validation: \(isValid ? "SUCCESS" : "FAILED")")
        return isValid
    }
    
    func removePin() {
        UserDefaults.standard.removeObject(forKey: pinKey)
        isPinEnabled = false
        print("🔐 PIN removed")
    }
    
    private func hashPin(_ pin: String) -> String {
        let data = Data(pin.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Упрощенный PIN Auth Manager (без ошибок)
@Observable
final class PinAuthManager {
    var attemptCount: Int = 0
    private let maxAttempts = 5
    
    func handlePinEntry(_ pin: String, onShake: @escaping () -> Void) -> Bool {
        if PinManager.shared.validatePin(pin) {
            HapticManager.shared.playSelection()
            attemptCount = 0
            return true
        } else {
            HapticManager.shared.play(.error)
            onShake() // Вызываем shake анимацию
            attemptCount += 1
            return false
        }
    }
    
    func reset() {
        attemptCount = 0
    }
    
    var isLocked: Bool {
        attemptCount >= maxAttempts
    }
}
