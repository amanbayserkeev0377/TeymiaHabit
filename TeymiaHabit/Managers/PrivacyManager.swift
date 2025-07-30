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
    static let shared = PrivacyManager()
    
    let privacySettings = PrivacySettings()
    private let context = LAContext()
    
    var isAppLocked: Bool = false
    var shouldShowPrivacySetup: Bool = false
    var authenticationError: String?
    
    private var lastActiveTime: Date = Date()
    private var hasJustLaunched: Bool = true
    
    var authenticationType: AuthenticationType {
        if PinManager.shared.isPinEnabled && privacySettings.biometricEnabled {
            return .both
        } else if PinManager.shared.isPinEnabled {
            return .customPin
        } else {
            return .systemAuth
        }
    }
    
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
            return false
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
    
    private init() {}
    
    // MARK: - App State Management
    
    func checkAndLockOnAppStart() {
        guard isPrivacyEnabled else { return }
        
        let duration = autoLockDuration
        
        if hasJustLaunched {
            hasJustLaunched = false
            
            if duration == .immediate {
                isAppLocked = true
            } else {
                let now = Date()
                let lastTime = getLastActiveTime()
                let timeInterval = now.timeIntervalSince(lastTime)
                let requiredInterval = TimeInterval(duration.rawValue)
                
                let shouldLock = timeInterval >= requiredInterval
                isAppLocked = shouldLock
            }
        } else {
            checkAutoLockStatus()
        }
        
        updateLastActiveTime()
    }
    
    func lockApp() {
        guard isPrivacyEnabled else { return }
        isAppLocked = true
        authenticationError = nil
    }
    
    func handleAppWillResignActive() {
        updateLastActiveTime()
        
        let duration = autoLockDuration
        
        if duration == .immediate {
            lockApp()
        }
    }
    
    func handleAppDidBecomeActive() {
        hasJustLaunched = false
        checkAutoLockStatus()
        
        if !isAppLocked {
            updateLastActiveTime()
        }
    }
    
    // MARK: - Authentication
    
    func authenticate() async {
        guard isPrivacyEnabled else { return }
        
        switch authenticationType {
        case .systemAuth:
            await authenticateWithSystem()
        case .customPin:
            break
        case .both:
            await authenticateWithBiometrics()
        }
    }
    
    private func authenticateWithSystem() async {
        do {
            let success = try await authenticateUserWithSystem()
            await MainActor.run {
                if success {
                    isAppLocked = false
                    authenticationError = nil
                    updateLastActiveTime()
                } else {
                    authenticationError = "authentication_failed".localized
                }
            }
        } catch {
            await MainActor.run {
                authenticationError = error.localizedDescription
            }
        }
    }
    
    private func authenticateWithBiometrics() async {
        do {
            let success = try await authenticateUserWithBiometrics()
            await MainActor.run {
                if success {
                    isAppLocked = false
                    authenticationError = nil
                    updateLastActiveTime()
                }
            }
        } catch {
            // Let user try PIN instead
        }
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
        context.localizedFallbackTitle = ""
        
        let reason = "privacy_auth_reason".localized
        return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
    }
    
    // MARK: - Privacy Setup
    
    func setupPrivacy() async -> Bool {
        switch authenticationType {
        case .systemAuth:
            return await setupSystemAuth()
        case .customPin, .both:
            await MainActor.run {
                isPrivacyEnabled = true
                isAppLocked = false
                updateLastActiveTime()
            }
            return true
        }
    }
    
    private func setupSystemAuth() async -> Bool {
        guard privacySettings.isPasscodeSet else {
            await MainActor.run {
                shouldShowPrivacySetup = true
            }
            return false
        }
        
        do {
            let success = try await authenticateUserWithSystem()
            if success {
                await MainActor.run {
                    isPrivacyEnabled = true
                    isAppLocked = false
                    updateLastActiveTime()
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
        
        switch authenticationType {
        case .systemAuth:
            return await disableWithSystemAuth()
        case .customPin, .both:
            await MainActor.run {
                isPrivacyEnabled = false
                isAppLocked = false
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
    }
    
    func disableBiometricsForPin() {
        privacySettings.biometricEnabled = false
    }
    
    // MARK: - Auto-Lock Support
    
    private var autoLockDuration: AutoLockDuration {
        let rawValue = UserDefaults.standard.integer(forKey: "autoLockDuration")
        return AutoLockDuration(rawValue: rawValue) ?? .immediate
    }
    
    private func getLastActiveTime() -> Date {
        UserDefaults.standard.object(forKey: "lastActiveTime") as? Date ?? Date()
    }
    
    func updateLastActiveTime() {
        let now = Date()
        UserDefaults.standard.set(now, forKey: "lastActiveTime")
    }
    
    func checkAutoLockStatus() {
        guard isPrivacyEnabled else { return }
        
        let duration = autoLockDuration
        
        guard duration != .immediate else { return }
        
        let now = Date()
        let lastTime = getLastActiveTime()
        let timeInterval = now.timeIntervalSince(lastTime)
        let requiredInterval = TimeInterval(duration.rawValue)
        let shouldLock = timeInterval >= requiredInterval
        
        if shouldLock && !isAppLocked {
            lockApp()
        }
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
