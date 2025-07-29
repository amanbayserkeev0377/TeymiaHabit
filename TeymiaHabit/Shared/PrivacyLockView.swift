import SwiftUI
import LocalAuthentication

struct PrivacyLockView: View {
    @Environment(\.privacyManager) private var privacyManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var isAuthenticating = false
    @State private var enteredPin = ""
    @State private var authManager = PinAuthManager()
    @State private var hasTriedBiometricOnAppear = false
    @State private var lastScenePhase: ScenePhase = .inactive // ✅ ДОБАВЛЕНО: Отслеживаем предыдущую фазу
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                Spacer()
                
                VStack(spacing: 30) {
                    Image("TeymiaHabitBlank")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                    
                    Text("enter_passcode".localized)
                        .font(.title3)
                        .foregroundStyle(.primary)
                    
                    PinDotsView(pin: enteredPin)
                }
                
                Spacer(minLength: 50)
                
                CustomNumberPad(
                    onNumberTap: addDigit,
                    onDeleteTap: removeDigit,
                    showBiometricButton: shouldShowBiometricButton,
                    onBiometricTap: shouldShowBiometricButton ? authenticateWithBiometrics : nil
                )
                .padding(.horizontal, 40)
                
                Spacer()
                Spacer()
            }
        }
        .onAppear {
            handleViewAppear()
        }
        .onChange(of: privacyManager.isAppLocked) { _, newValue in
            if !newValue {
                resetAuthStates()
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // ✅ ИСПРАВЛЕНИЕ 2: Улучшенная логика обработки scene phase
            print("🔐 Scene phase changed: \(lastScenePhase) -> \(newPhase)")
            
            switch newPhase {
            case .background:
                hasTriedBiometricOnAppear = false
                print("🔐 App went to background - resetting biometric flag")
                
            case .active:
                // ✅ Запускаем биометрию только если:
                // 1. Приложение заблокировано
                // 2. Мы не аутентифицируемся сейчас
                // 3. Не пробовали биометрию еще
                // 4. Пришли из background или inactive (не из другого active состояния)
                if privacyManager.isAppLocked &&
                   !isAuthenticating &&
                   !hasTriedBiometricOnAppear &&
                   (lastScenePhase == .background || lastScenePhase == .inactive) {
                    print("🔐 Scene became active from \(lastScenePhase) while locked - starting biometric")
                    handleBiometricOnSceneActive()
                }
                
            case .inactive:
                hasTriedBiometricOnAppear = false 
                print("🔐 App became inactive - resetting biometric flag")
                
            @unknown default:
                break
            }
            
            lastScenePhase = newPhase
        }
    }
    
    private var shouldShowBiometricButton: Bool {
        switch privacyManager.authenticationType {
        case .systemAuth: return false
        case .customPin: return false
        case .both: return privacyManager.canUseBiometrics && privacyManager.isBiometricEnabled
        }
    }
    
    private func handleViewAppear() {
        print("🔐 PrivacyLockView appeared")
        print("🔐 AuthType: \(privacyManager.authenticationType)")
        print("🔐 CanUseBiometrics: \(privacyManager.canUseBiometrics)")
        print("🔐 BiometricEnabled: \(privacyManager.isBiometricEnabled)")
        print("🔐 hasTriedBiometricOnAppear: \(hasTriedBiometricOnAppear)")
        
        resetAuthStates()
        
        // ✅ При первом появлении всегда пробуем биометрию
        switch privacyManager.authenticationType {
        case .systemAuth:
            print("🔐 Starting system auth")
            authenticateWithSystem()
        case .customPin:
            print("🔐 Custom PIN only - no auto biometric")
            break
        case .both:
            if privacyManager.canUseBiometrics && privacyManager.isBiometricEnabled {
                print("🔐 Starting biometric auth on appear")
                hasTriedBiometricOnAppear = true
                authenticateWithBiometrics()
            } else {
                print("🔐 Biometric not available - canUse: \(privacyManager.canUseBiometrics), enabled: \(privacyManager.isBiometricEnabled)")
            }
        }
    }
    
    // ✅ ДОБАВЛЕНО: Отдельный метод для биометрии при смене scene phase
    private func handleBiometricOnSceneActive() {
        switch privacyManager.authenticationType {
        case .systemAuth:
            print("🔐 Starting system auth on scene active")
            authenticateWithSystem()
        case .customPin:
            print("🔐 Custom PIN only - no biometric on scene active")
            break
        case .both:
            if privacyManager.canUseBiometrics && privacyManager.isBiometricEnabled {
                print("🔐 Starting biometric auth on scene active")
                hasTriedBiometricOnAppear = true
                authenticateWithBiometrics()
            }
        }
    }
    
    private func resetAuthStates() {
        isAuthenticating = false
        enteredPin = ""
        authManager.reset()
        // ✅ НЕ сбрасываем hasTriedBiometricOnAppear здесь, только при фазах приложения
    }
    
    private func authenticateWithSystem() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        
        Task {
            await privacyManager.authenticate()
            await MainActor.run {
                isAuthenticating = false
            }
        }
    }
    
    private func authenticateWithBiometrics() {
        guard !isAuthenticating else {
            print("🔐 Already authenticating - skipping biometric request")
            return
        }
        
        print("🔐 Starting biometric authentication...")
        isAuthenticating = true
        
        Task {
            await privacyManager.authenticate()
            await MainActor.run {
                print("🔐 Biometric authentication completed")
                isAuthenticating = false
            }
        }
    }
    
    private func handlePinEntry(_ pin: String) {
        let success = authManager.handlePinEntry(pin) {
            // Shake animation callback
            triggerPinDotsShake()
        }
        
        if success {
            privacyManager.isAppLocked = false
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                enteredPin = ""
            }
        }
    }
    
    private func addDigit(_ digit: String) {
        guard enteredPin.count < 4 else { return }
        enteredPin += digit
        
        if enteredPin.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                handlePinEntry(enteredPin)
            }
        }
    }
    
    private func removeDigit() {
        guard !enteredPin.isEmpty else { return }
        enteredPin = String(enteredPin.dropLast())
    }
}

// ✅ ДОБАВЛЕНО: Функция для PinDotsView shake animation (если не существует)
extension PrivacyLockView {
    private func triggerPinDotsShake() {
        // Implement shake animation for PIN dots
        // This should trigger the shake animation in PinDotsView
        HapticManager.shared.play(.error)
    }
}
