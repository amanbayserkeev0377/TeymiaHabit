import SwiftUI
import LocalAuthentication

struct PrivacyLockView: View {
    @Environment(\.privacyManager) private var privacyManager
    @State private var isAuthenticating = false
    @State private var enteredPin = ""
    @State private var authManager = PinAuthManager()
    @State private var pinDots = PinDotsView(pin: "")
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                Spacer()
                
                VStack(spacing: 20) {
                    Image("TeymiaHabitBlank")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                    
                    Text("Введите пароль")
                        .font(.title3)
                        .foregroundStyle(.primary)
                    
                    PinDotsView(pin: enteredPin)
                }
                
                Spacer(minLength: 50)
                
                // ✅ Клавиатура отдельно
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
        .onAppear { handleViewAppear() }
        .onChange(of: privacyManager.isAppLocked) { _, newValue in
            if !newValue { resetAuthStates() }
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
        resetAuthStates()
        
        switch privacyManager.authenticationType {
        case .systemAuth:
            authenticateWithSystem()
        case .customPin:
            break
        case .both:
            if privacyManager.canUseBiometrics && privacyManager.isBiometricEnabled {
                authenticateWithBiometrics()
            }
        }
    }
    
    private func resetAuthStates() {
        isAuthenticating = false
        enteredPin = ""
        authManager.reset()
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
        guard !isAuthenticating else { return }
        isAuthenticating = true
        
        Task {
            await privacyManager.authenticate()
            await MainActor.run {
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
