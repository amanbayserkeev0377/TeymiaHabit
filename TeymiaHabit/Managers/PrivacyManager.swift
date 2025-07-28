import Foundation
import LocalAuthentication
import SwiftUI

// MARK: - Privacy Settings Model
@Observable
final class PrivacySettings {
    var isPrivacyEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "privacy_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "privacy_enabled") }
    }
    
    var biometricType: LABiometryType {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return context.biometryType
    }
    
    var isPasscodeSet: Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }
    
    // PIN Settings
    var pinEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "pin_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "pin_enabled") }
    }
    
    var biometricEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "biometric_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "biometric_enabled") }
    }
}

// MARK: - Authentication Type
enum AuthenticationType {
    case systemAuth // Face ID + system passcode
    case customPin  // Custom 4-digit PIN
    case both      // Face ID + custom PIN fallback
}

// MARK: - Privacy Manager
@Observable
final class PrivacyManager {
    let privacySettings = PrivacySettings()
    private let context = LAContext()
    
    // App state management
    var isAppLocked: Bool = false
    var shouldShowPrivacySetup: Bool = false
    var authenticationError: String?
    
    // Authentication type
    var authenticationType: AuthenticationType {
        if PinManager.shared.isPinEnabled && privacySettings.biometricEnabled {
            return .both
        } else if PinManager.shared.isPinEnabled {
            return .customPin
        } else {
            return .systemAuth
        }
    }
    
    // Biometric info
    var biometricType: LABiometryType {
        privacySettings.biometricType
    }
    
    var isPrivacyEnabled: Bool {
        get { privacySettings.isPrivacyEnabled }
        set {
            privacySettings.isPrivacyEnabled = newValue
            if !newValue {
                isAppLocked = false
            }
        }
    }
    
    var canUseBiometrics: Bool {
        switch authenticationType {
        case .systemAuth:
            return privacySettings.isPasscodeSet && biometricType != .none
        case .customPin:
            return false // Only PIN, no biometrics
        case .both:
            return biometricType != .none && privacySettings.biometricEnabled
        }
    }
    
    var biometricDisplayName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Biometrics"
        }
    }
    
    // PIN related properties
    var hasPinSet: Bool {
        PinManager.shared.hasPinSet
    }
    
    var isPinEnabled: Bool {
        PinManager.shared.isPinEnabled
    }
    
    var isBiometricEnabled: Bool {
        get { privacySettings.biometricEnabled }
        set { privacySettings.biometricEnabled = newValue }
    }
    
    static let shared = PrivacyManager()
    
    private init() {
        // Initial setup - app locking handled by checkAndLockOnAppStart()
    }
    
    // MARK: - Setup & State Management
    
    func checkAndLockOnAppStart() {
        guard isPrivacyEnabled else {
            print("🔐 Privacy not enabled, no lock on app start")
            return
        }
        
        let duration = autoLockDuration
        print("🔐 App start - checking lock with duration: \(duration.displayName)")
        
        // ✅ ИСПРАВЛЕНИЕ: Проверяем нужно ли блокировать на старте
        if duration == .immediate {
            // Immediate - всегда блокируем при запуске
            print("🔐 Immediate mode - locking on app start")
            isAppLocked = true
        } else {
            // Другие режимы - проверяем время
            let now = Date()
            let lastTime = lastActiveTime
            let timeInterval = now.timeIntervalSince(lastTime)
            let requiredInterval = TimeInterval(duration.rawValue)
            
            print("🔐 App start time check: \(Int(timeInterval))s elapsed, need \(Int(requiredInterval))s")
            print("🔐 Last active: \(lastTime)")
            print("🔐 Current time: \(now)")
            
            if timeInterval >= requiredInterval {
                print("🔐 ✅ Locking on app start - enough time elapsed")
                isAppLocked = true
            } else {
                print("🔐 ❌ Not locking on app start - not enough time elapsed")
                isAppLocked = false
            }
        }
    }
    
    func lockApp() {
        guard isPrivacyEnabled else { return }
        isAppLocked = true
        authenticationError = nil
    }
    
    // MARK: - Authentication
    func authenticate() async {
        guard isPrivacyEnabled else {
            print("🔐 Privacy not enabled, skipping authentication")
            return
        }
        
        print("🔐 Starting authentication with type: \(authenticationType)")
        print("🔐 Current lock state: \(isAppLocked)")
        
        switch authenticationType {
        case .systemAuth:
            await authenticateWithSystem()
        case .customPin:
            // PIN authentication handled in PrivacyLockView
            break
        case .both:
            await authenticateWithBiometrics()
        }
    }
    
    // System authentication (original method)
    private func authenticateWithSystem() async {
        do {
            let success = try await authenticateUserWithSystem()
            await MainActor.run {
                print("🔐 System authentication result: \(success)")
                if success {
                    print("✅ System authentication successful - unlocking app")
                    isAppLocked = false
                    authenticationError = nil
                } else {
                    print("❌ System authentication failed")
                    authenticationError = "authentication_failed".localized
                }
            }
        } catch {
            print("❌ System authentication error: \(error)")
            await MainActor.run {
                authenticationError = error.localizedDescription
            }
        }
    }
    
    // Biometric authentication (for both mode)
    private func authenticateWithBiometrics() async {
        do {
            let success = try await authenticateUserWithBiometrics()
            await MainActor.run {
                print("🔐 Biometric authentication result: \(success)")
                if success {
                    print("✅ Biometric authentication successful - unlocking app")
                    isAppLocked = false
                    authenticationError = nil
                } else {
                    print("❌ Biometric authentication failed - fallback to PIN")
                    // Don't set error, just let PIN input handle it
                }
            }
        } catch {
            print("❌ Biometric authentication error: \(error) - fallback to PIN")
            await MainActor.run {
                // Don't set authenticationError, let user try PIN
            }
        }
    }
    
    // PIN authentication
    func authenticateWithPin(_ pin: String) -> Bool {
        let success = PinManager.shared.validatePin(pin)
        if success {
            print("✅ PIN authentication successful - unlocking app")
            isAppLocked = false
            authenticationError = nil
        } else {
            print("❌ PIN authentication failed")
            authenticationError = "Неверный код-пароль"
        }
        return success
    }
    
    private func authenticateUserWithSystem() async throws -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "use_passcode".localized
        
        let policy: LAPolicy = privacySettings.isPasscodeSet && biometricType != .none ?
            .deviceOwnerAuthenticationWithBiometrics :
            .deviceOwnerAuthentication
        
        let reason = "privacy_auth_reason".localized
        return try await context.evaluatePolicy(policy, localizedReason: reason)
    }
    
    private func authenticateUserWithBiometrics() async throws -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "" // Disable fallback to show our PIN
        
        let reason = "privacy_auth_reason".localized
        return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
    }
    
    // MARK: - Privacy Setup
    func setupPrivacy() async -> Bool {
        switch authenticationType {
        case .systemAuth:
            return await setupSystemAuth()
        case .customPin, .both:
            // PIN setup handled by PIN setup flow
            await MainActor.run {
                isPrivacyEnabled = true
                isAppLocked = false
            }
            return true
        }
    }
    
    private func setupSystemAuth() async -> Bool {
        // Check if device supports authentication
        guard privacySettings.isPasscodeSet else {
            await MainActor.run {
                shouldShowPrivacySetup = true
            }
            return false
        }
        
        // Test authentication before enabling
        do {
            let success = try await authenticateUserWithSystem()
            if success {
                await MainActor.run {
                    isPrivacyEnabled = true
                    isAppLocked = false
                }
                return true
            }
            return false
        } catch {
            await MainActor.run {
                authenticationError = error.localizedDescription
            }
            return false
        }
    }
    
    func disablePrivacy() async -> Bool {
        guard isPrivacyEnabled else { return true }
        
        // Require authentication to disable privacy
        switch authenticationType {
        case .systemAuth:
            return await disableWithSystemAuth()
        case .customPin, .both:
            // PIN verification handled in settings UI
            await MainActor.run {
                isPrivacyEnabled = false
                isAppLocked = false
                // Also disable PIN when disabling privacy
                PinManager.shared.removePin()
                privacySettings.biometricEnabled = false
            }
            return true
        }
    }
    
    private func disableWithSystemAuth() async -> Bool {
        do {
            let success = try await authenticateUserWithSystem()
            if success {
                await MainActor.run {
                    isPrivacyEnabled = false
                    isAppLocked = false
                }
                return true
            }
            return false
        } catch {
            await MainActor.run {
                authenticationError = error.localizedDescription
            }
            return false
        }
    }
    
    // MARK: - PIN Management
    func enableBiometricsForPin() {
        privacySettings.biometricEnabled = true
        print("🔐 Biometrics enabled for PIN authentication")
    }
    
    func disableBiometricsForPin() {
        privacySettings.biometricEnabled = false
        print("🔐 Biometrics disabled for PIN authentication")
    }
}

// MARK: - Environment Key
private struct PrivacyManagerKey: EnvironmentKey {
    typealias Value = PrivacyManager
    static let defaultValue: PrivacyManager = PrivacyManager.shared
}

extension EnvironmentValues {
    var privacyManager: PrivacyManager {
        get { self[PrivacyManagerKey.self] }
        set { self[PrivacyManagerKey.self] = newValue }
    }
}

// MARK: - Privacy Manager (дополнения для Auto-Lock)
extension PrivacyManager {
    
    // MARK: - Auto-Lock Support
    private var autoLockDuration: AutoLockDuration {
        let rawValue = UserDefaults.standard.integer(forKey: "autoLockDuration")
        return AutoLockDuration(rawValue: rawValue) ?? .immediate
    }
    
    private var lastActiveTime: Date {
        get {
            let time = UserDefaults.standard.object(forKey: "lastActiveTime") as? Date ?? Date()
            print("🔐 Getting lastActiveTime: \(time)")
            return time
        }
        set {
            print("🔐 Setting lastActiveTime: \(newValue)")
            UserDefaults.standard.set(newValue, forKey: "lastActiveTime")
        }
    }
    
    func updateLastActiveTime() {
        lastActiveTime = Date()
        print("🔐 Updated lastActiveTime to now")
    }
    
    func checkAutoLockStatus() {
        guard isPrivacyEnabled else {
            print("🔐 Privacy not enabled, skipping auto-lock check")
            return
        }
        
        let duration = autoLockDuration
        print("🔐 Checking auto-lock with duration: \(duration.displayName) (\(duration.rawValue)s)")
        
        // ✅ ИСПРАВЛЕНИЕ: Immediate не должен блокировать при проверке
        guard duration != .immediate else {
            print("🔐 Immediate mode - no auto-lock check needed")
            return
        }
        
        let now = Date()
        let lastTime = lastActiveTime
        let timeInterval = now.timeIntervalSince(lastTime)
        let requiredInterval = TimeInterval(duration.rawValue)
        
        print("🔐 Time check: \(Int(timeInterval))s elapsed, need \(Int(requiredInterval))s")
        print("🔐 Last active: \(lastTime)")
        print("🔐 Current time: \(now)")
        print("🔐 Currently locked: \(isAppLocked)")
        
        let shouldLock = timeInterval >= requiredInterval
        
        if shouldLock && !isAppLocked {
            print("🔐 ✅ Auto-lock triggered after \(duration.displayName)")
            lockApp()
        } else if shouldLock {
            print("🔐 ⚠️ Should lock but already locked")
        } else {
            print("🔐 ❌ Not enough time elapsed for auto-lock")
        }
    }
    
    func handleAppWillResignActive() {
        print("🔐 handleAppWillResignActive called")
        updateLastActiveTime()
        
        let duration = autoLockDuration
        print("🔐 Current auto-lock setting: \(duration.displayName)")
        
        // ✅ ИСПРАВЛЕНИЕ: Immediate блокирует только здесь
        if duration == .immediate {
            print("🔐 ✅ Immediate lock triggered on resign active")
            lockApp()
        } else {
            print("🔐 ❌ Non-immediate mode, not locking on resign")
        }
    }
    
    func handleAppDidBecomeActive() {
        print("🔐 handleAppDidBecomeActive called")
        // ✅ ИСПРАВЛЕНИЕ: Immediate НЕ проверяется здесь
        checkAutoLockStatus()
    }
}
