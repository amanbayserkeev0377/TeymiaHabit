import SwiftUI
import LocalAuthentication

struct PrivacyLockView: View {
    @Environment(\.privacyManager) private var privacyManager
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var isAuthenticating = false
    @State private var enteredPin = ""
    @State private var authManager = PinAuthManager()
    @State private var hasTriedBiometricOnAppear = false
    @State private var lastScenePhase: ScenePhase = .inactive
    
    // MARK: - Design Constants
    
    private enum DesignConstants {
        static let appIconSize: CGFloat = 80
        static let minimumSpacing: CGFloat = 50
        static let contentSpacing: CGFloat = 30
        static let horizontalPadding: CGFloat = 40
        static let pinLength = 4
        static let pinEntryDelay: Double = 0.1
        static let pinClearDelay: Double = 0.5
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                Spacer()
                
                headerContent
                
                Spacer(minLength: DesignConstants.minimumSpacing)
                
                numberPad
                
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
            handleScenePhaseChange(from: lastScenePhase, to: newPhase)
            lastScenePhase = newPhase
        }
    }
    
    // MARK: - View Components
    
    private var headerContent: some View {
        VStack(spacing: DesignConstants.contentSpacing) {
            Image("TeymiaHabitBlank")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: DesignConstants.appIconSize, height: DesignConstants.appIconSize)
            
            Text("enter_passcode".localized)
                .font(.title3)
                .fontDesign(.rounded)
                .foregroundStyle(.primary)
            
            PinDotsView(pin: enteredPin)
        }
    }
    
    private var numberPad: some View {
        CustomNumberPad(
            onNumberTap: addDigit,
            onDeleteTap: removeDigit,
            showBiometricButton: shouldShowBiometricButton,
            onBiometricTap: shouldShowBiometricButton ? authenticateWithBiometrics : nil
        )
        .padding(.horizontal, DesignConstants.horizontalPadding)
        .safeAreaPadding(.bottom, 20)
    }
    
    // MARK: - Computed Properties
    
    private var shouldShowBiometricButton: Bool {
        switch privacyManager.authenticationType {
        case .systemAuth, .customPin:
            return false
        case .both:
            return privacyManager.canUseBiometrics && privacyManager.isBiometricEnabled
        }
    }
    
    private var canUseBiometrics: Bool {
        privacyManager.canUseBiometrics && privacyManager.isBiometricEnabled
    }
    
    // MARK: - Lifecycle Methods
    
    private func handleViewAppear() {
        resetAuthStates()
        attemptInitialAuthentication()
    }
    
    private func attemptInitialAuthentication() {
        switch privacyManager.authenticationType {
        case .systemAuth:
            authenticateWithSystem()
            
        case .customPin:
            break
            
        case .both:
            if canUseBiometrics {
                hasTriedBiometricOnAppear = true
                authenticateWithBiometrics()
            }
        }
    }
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            hasTriedBiometricOnAppear = false
            
        case .active:
            handleSceneActivation(from: oldPhase)
            
        case .inactive:
            hasTriedBiometricOnAppear = false
            
        @unknown default:
            break
        }
    }
    
    private func handleSceneActivation(from fromPhase: ScenePhase) {
        let shouldTryBiometric = privacyManager.isAppLocked &&
                                !isAuthenticating &&
                                !hasTriedBiometricOnAppear &&
                                (fromPhase == .background || fromPhase == .inactive)
        
        guard shouldTryBiometric else { return }
        
        attemptBiometricOnSceneActive()
    }
    
    private func attemptBiometricOnSceneActive() {
        switch privacyManager.authenticationType {
        case .systemAuth:
            authenticateWithSystem()
            
        case .customPin:
            break
            
        case .both:
            if canUseBiometrics {
                hasTriedBiometricOnAppear = true
                authenticateWithBiometrics()
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    private func authenticateWithSystem() {
        guard !isAuthenticating else { return }
        performAuthentication()
    }
    
    private func authenticateWithBiometrics() {
        guard !isAuthenticating else { return }
        performAuthentication()
    }
    
    private func performAuthentication() {
        isAuthenticating = true
        
        Task {
            await privacyManager.authenticate()
            await MainActor.run {
                isAuthenticating = false
            }
        }
    }
    
    // MARK: - PIN Entry Methods
    
    private func handlePinEntry(_ pin: String) {
        let success = authManager.handlePinEntry(pin) {
            triggerPinShakeAnimation()
        }
        
        if success {
            privacyManager.isAppLocked = false
        } else {
            clearPinAfterDelay()
        }
    }
    
    private func addDigit(_ digit: String) {
        guard enteredPin.count < DesignConstants.pinLength else { return }
        enteredPin += digit
        
        if enteredPin.count == DesignConstants.pinLength {
            processPinEntry()
        }
    }
    
    private func removeDigit() {
        guard !enteredPin.isEmpty else { return }
        enteredPin = String(enteredPin.dropLast())
    }
    
    private func processPinEntry() {
        DispatchQueue.main.asyncAfter(deadline: .now() + DesignConstants.pinEntryDelay) {
            handlePinEntry(enteredPin)
        }
    }
    
    private func clearPinAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + DesignConstants.pinClearDelay) {
            enteredPin = ""
        }
    }
    
    // MARK: - Helper Methods
    
    private func resetAuthStates() {
        isAuthenticating = false
        enteredPin = ""
    }
    
    private func triggerPinShakeAnimation() {
        triggerPinDotsShake() // Global function from PinCodeView
        HapticManager.shared.play(.error)
    }
}
