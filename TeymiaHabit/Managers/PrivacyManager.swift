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
    
    // ✅ ИСПРАВЛЕНИЕ: Отслеживание состояния приложения
    private var lastActiveTime: Date = Date()
    private var hasJustLaunched: Bool = true // Для отличия первого запуска от возврата из фона
    
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
        // Initial setup handled by checkAndLockOnAppStart()
    }
    
    // MARK: - Setup & State Management
    
    func checkAndLockOnAppStart() {
        guard isPrivacyEnabled else {
            print("🔐 Privacy not enabled, app starts unlocked")
            return
        }
        
        let duration = autoLockDuration
        print("🔐 checkAndLockOnAppStart - duration: \(duration.displayName)")
        
        if hasJustLaunched {
            // ✅ При первом запуске приложения
            hasJustLaunched = false
            
            if duration == .immediate {
                // Immediate - всегда блокируем при запуске
                print("🔐 First launch with immediate lock - locking app")
                isAppLocked = true
            } else {
                // Другие режимы - проверяем время последней активности
                let now = Date()
                let lastTime = getLastActiveTime()
                let timeInterval = now.timeIntervalSince(lastTime)
                let requiredInterval = TimeInterval(duration.rawValue)
                
                let shouldLock = timeInterval >= requiredInterval
                print("🔐 First launch - time since last active: \(timeInterval)s, required: \(requiredInterval)s, should lock: \(shouldLock)")
                
                isAppLocked = shouldLock
            }
        } else {
            // ✅ При возврате из фона - только проверяем время
            checkAutoLockStatus()
        }
        
        updateLastActiveTime()
    }
    
    func lockApp() {
        guard isPrivacyEnabled else { return }
        print("🔐 Manually locking app")
        isAppLocked = true
        authenticationError = nil
    }
    
    // MARK: - Authentication
    func authenticate() async {
        guard isPrivacyEnabled else {
            return
        }
        
        print("🔐 Starting authentication - type: \(authenticationType)")
        
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
                if success {
                    print("🔐 System authentication successful")
                    isAppLocked = false
                    authenticationError = nil
                    updateLastActiveTime()
                } else {
                    print("🔐 System authentication failed")
                    authenticationError = "authentication_failed".localized
                }
            }
        } catch {
            await MainActor.run {
                print("🔐 System authentication error: \(error)")
                authenticationError = error.localizedDescription
            }
        }
    }
    
    // Biometric authentication (for both mode)
    private func authenticateWithBiometrics() async {
        do {
            let success = try await authenticateUserWithBiometrics()
            await MainActor.run {
                if success {
                    print("🔐 Biometric authentication successful")
                    isAppLocked = false
                    authenticationError = nil
                    updateLastActiveTime()
                } else {
                    print("🔐 Biometric authentication failed - user can try PIN")
                    // Don't set error, just let PIN input handle it
                }
            }
        } catch {
            await MainActor.run {
                print("🔐 Biometric authentication error: \(error)")
                // Don't set authenticationError, let user try PIN
            }
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
                updateLastActiveTime()
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
        print("🔐 Updated last active time: \(now)")
    }
    
    func checkAutoLockStatus() {
        guard isPrivacyEnabled else {
            print("🔐 Privacy not enabled, skipping auto-lock check")
            return
        }
        
        let duration = autoLockDuration
        print("🔐 Checking auto-lock status - duration: \(duration.displayName)")
        
        guard duration != .immediate else {
            print("🔐 Immediate lock setting - no time check needed")
            return
        }
        
        let now = Date()
        let lastTime = getLastActiveTime()
        let timeInterval = now.timeIntervalSince(lastTime)
        let requiredInterval = TimeInterval(duration.rawValue)
        let shouldLock = timeInterval >= requiredInterval
        
        print("🔐 Time since last active: \(timeInterval)s, required: \(requiredInterval)s, should lock: \(shouldLock)")
        
        if shouldLock && !isAppLocked {
            print("🔐 Auto-locking app due to timeout")
            lockApp()
        }
    }
    
    func handleAppWillResignActive() {
        updateLastActiveTime()
        
        let duration = autoLockDuration
        print("🔐 App will resign active - duration: \(duration.displayName)")
        
        if duration == .immediate {
            print("🔐 Immediate lock on resign active")
            lockApp()
        } else {
            print("🔐 Delayed lock - will check on become active")
        }
    }
    
    func handleAppDidBecomeActive() {
        print("🔐 handleAppDidBecomeActive called")
        print("🔐 isPrivacyEnabled: \(isPrivacyEnabled)")
        print("🔐 Current isAppLocked: \(isAppLocked)")
        
        hasJustLaunched = false // После первого возврата из фона
        checkAutoLockStatus()
        
        print("🔐 After checkAutoLockStatus: \(isAppLocked)")
        
        // Обновляем время только если не заблокированы
        if !isAppLocked {
            updateLastActiveTime()
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
