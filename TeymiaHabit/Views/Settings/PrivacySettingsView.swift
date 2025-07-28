import SwiftUI
import LocalAuthentication

struct PrivacySettingsView: View {
    @Environment(\.privacyManager) private var privacyManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.globalPin) private var globalPin
    
    @State private var isSettingUpPrivacy = false
    @State private var showingDisableConfirmation = false
    @State private var pinAction: PinAction = .setup
    
    // PIN setup flow states
    @State private var isAwaitingConfirmation = false
    @State private var firstPin = ""
    
    enum PinAction {
        case setup
        case change
        case verify
    }
    
    var body: some View {
        settingsContent
            .navigationTitle("passcode_faceid".localized)
            .navigationBarTitleDisplayMode(.inline)
            .alert("Отключить код-пароль?", isPresented: $showingDisableConfirmation) {
                Button("Отключить", role: .destructive) {
                    disableProtection()
                }
                Button("Отмена", role: .cancel) { }
            } message: {
                Text("Это отключит защиту приложения. Вы сможете включить её снова в любое время.")
            }
    }
    
    // MARK: - Settings Content
    @ViewBuilder
    private var settingsContent: some View {
        List {
            // 3D Icon Section
            Section {
                HStack {
                    Spacer()
                    
                    Image("3d_shield_green")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 125)
                    
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            .listSectionSeparator(.hidden)
            
            // PIN Code Section
            Section {
                if !privacyManager.isPrivacyEnabled || !privacyManager.hasPinSet {
                    // Turn Passcode On Button
                    Button {
                        startPinSetup()
                    } label: {
                        Label {
                            Text("Turn Passcode On")
                                .font(.body)
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: "checkmark.shield")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(#colorLiteral(red: 0.3, green: 0.8, blue: 0.4, alpha: 1)),
                                            Color(#colorLiteral(red: 0.1, green: 0.5, blue: 0.2, alpha: 1))
                                        ],
                                        startPoint: .topTrailing,
                                        endPoint: .bottomLeading
                                    )
                                )
                                .frame(width: 30, height: 30)
                        }
                    }
                } else {
                    // Change PIN
                    Button {
                        startPinChange()
                    } label: {
                        Label {
                            Text("Change passcode")
                                .font(.body)
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: "key")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(#colorLiteral(red: 0.95, green: 0.85, blue: 0.15, alpha: 1)),
                                            Color(#colorLiteral(red: 0.75, green: 0.55, blue: 0.05, alpha: 1))
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 30, height: 30)
                        }
                    }
                    
                    // Disable PIN
                    Button {
                        showingDisableConfirmation = true
                    } label: {
                        Label {
                            Text("Disable passcode")
                                .font(.body)
                                .foregroundStyle(.red)
                        } icon: {
                            Image(systemName: "xmark.shield")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(#colorLiteral(red: 1, green: 0.3, blue: 0.3, alpha: 1)),
                                            Color(#colorLiteral(red: 0.8, green: 0.1, blue: 0.1, alpha: 1))
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 30, height: 30)
                        }
                    }
                }
            }
            
            // Auto-Lock Section (только когда PIN включен) - NavigationLink
            if privacyManager.isPrivacyEnabled && privacyManager.hasPinSet {
                Section {
                    NavigationLink {
                        RequestPasscodeSettingsView()
                    } label: {
                        HStack {
                            Label {
                                Text("Request Passcode")
                                    .font(.body)
                            } icon: {
                                Image(systemName: "timer")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                Color(#colorLiteral(red: 0.4, green: 0.7, blue: 0.95, alpha: 1)),
                                                Color(#colorLiteral(red: 0.12, green: 0.35, blue: 0.6, alpha: 1))
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 30, height: 30)
                            }
                            
                            Spacer()
                            
                            Text(currentAutoLockDisplayName)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            // Biometric Authentication Section (только когда PIN включен)
            if privacyManager.isPrivacyEnabled && privacyManager.hasPinSet && privacyManager.biometricType != .none {
                Section {
                    HStack {
                        Label {
                            Text(privacyManager.biometricDisplayName)
                                .font(.body)
                        } icon: {
                            biometricIcon
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(#colorLiteral(red: 0.3, green: 0.8, blue: 0.4, alpha: 1)),
                                            Color(#colorLiteral(red: 0.1, green: 0.5, blue: 0.2, alpha: 1))
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 30, height: 30)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { privacyManager.isBiometricEnabled },
                            set: { enabled in
                                if enabled {
                                    privacyManager.enableBiometricsForPin()
                                } else {
                                    privacyManager.disableBiometricsForPin()
                                }
                            }
                        ))
                        .withToggleColor()
                    }
                }
            }
        }
    }
    
    // MARK: - Auto-Lock Display Name
    @AppStorage("autoLockDuration") private var autoLockDuration = AutoLockDuration.immediate.rawValue
    
    private var currentAutoLockDisplayName: String {
        let duration = AutoLockDuration(rawValue: autoLockDuration) ?? .immediate
        return duration.displayName
    }
    
    // MARK: - Biometric Icon
    @ViewBuilder
    private var biometricIcon: some View {
        switch privacyManager.biometricType {
        case .faceID:
            Image(systemName: "faceid")
        case .touchID:
            Image(systemName: "touchid")
        case .opticID:
            Image(systemName: "opticid")
        default:
            Image(systemName: "key.fill")
        }
    }
    
    // MARK: - PIN Actions
    private func startPinSetup() {
        pinAction = .setup
        isAwaitingConfirmation = false
        
        globalPin.showPin("Введите пароль", { pin in
            handlePinComplete(pin)
        }, {
            globalPin.hidePin()
        })
    }

    private func startPinChange() {
        pinAction = .verify
        
        globalPin.showPin("Введите текущий пароль", { pin in
            handlePinComplete(pin)
        }, {
            globalPin.hidePin()
        })
    }
    
    private func handlePinComplete(_ pin: String) {
        switch pinAction {
        case .setup:
            if !isAwaitingConfirmation {
                firstPin = pin
                isAwaitingConfirmation = true
                globalPin.showPin("Повторите пароль", { confirmPin in
                    handlePinComplete(confirmPin)
                }, { globalPin.hidePin() })
            } else {
                if firstPin == pin {
                    PinManager.shared.setPin(pin)
                    HapticManager.shared.playSelection()
                    completeSetup()
                } else {
                    HapticManager.shared.play(.error)
                    triggerPinDotsShake()
                    isAwaitingConfirmation = false
                    firstPin = ""
                    // Небольшая задержка чтобы shake успел отработать
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        globalPin.showPin("Введите пароль", { retryPin in
                            handlePinComplete(retryPin)
                        }, { globalPin.hidePin() })
                    }
                }
            }
            
        case .change:
            if !isAwaitingConfirmation {
                firstPin = pin
                isAwaitingConfirmation = true
                globalPin.showPin("Повторите пароль", { confirmPin in
                    handlePinComplete(confirmPin)
                }, { globalPin.hidePin() })
            } else {
                if firstPin == pin {
                    PinManager.shared.setPin(pin)
                    HapticManager.shared.playSelection()
                    globalPin.hidePin()
                } else {
                    HapticManager.shared.play(.error)
                    triggerPinDotsShake()
                    isAwaitingConfirmation = false
                    firstPin = ""
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        globalPin.showPin("Введите новый пароль", { retryPin in
                            handlePinComplete(retryPin)
                        }, { globalPin.hidePin() })
                    }
                }
            }
            
        case .verify:
            if PinManager.shared.validatePin(pin) {
                HapticManager.shared.playSelection()
                pinAction = .change
                isAwaitingConfirmation = false
                firstPin = ""
                globalPin.showPin("Введите новый пароль", { newPin in
                    handlePinComplete(newPin)
                }, { globalPin.hidePin() })
            } else {
                HapticManager.shared.play(.error)
                triggerPinDotsShake()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    globalPin.showPin("Введите текущий пароль", { retryPin in
                        handlePinComplete(retryPin)
                    }, { globalPin.hidePin() })
                }
            }
        }
    }
    
    private func completeSetup() {
        Task {
            let _ = await privacyManager.setupPrivacy()
            await MainActor.run {
                globalPin.hidePin()
            }
        }
    }
    
    private func disableProtection() {
        isSettingUpPrivacy = true
        
        Task {
            _ = await privacyManager.disablePrivacy()
            await MainActor.run {
                isSettingUpPrivacy = false
            }
        }
    }
}

// MARK: - Auto-Lock Settings View
struct RequestPasscodeSettingsView: View {
    @AppStorage("autoLockDuration") private var autoLockDuration = AutoLockDuration.immediate.rawValue
    
    private var selectedDuration: AutoLockDuration {
        AutoLockDuration(rawValue: autoLockDuration) ?? .immediate
    }
    
    var body: some View {
        List {
            ForEach(AutoLockDuration.allCases, id: \.rawValue) { duration in
                Button {
                    withAnimation(.easeInOut) {
                        autoLockDuration = duration.rawValue
                    }
                    HapticManager.shared.playSelection()
                } label: {
                    HStack {
                        Text(duration.displayName)
                            .tint(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                            .withAppGradient()
                            .opacity(selectedDuration == duration ? 1 : 0)
                            .animation(.easeInOut, value: selectedDuration == duration)
                    }
                }
            }
        }
        .navigationTitle("Request Passcode")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Auto-Lock Duration Enum
enum AutoLockDuration: Int, CaseIterable {
    case immediate = 0
    case oneMinute = 60
    case fiveMinutes = 300
    case fifteenMinutes = 900
    case thirtyMinutes = 1800
    case oneHour = 3600
    
    var displayName: String {
        switch self {
        case .immediate:
            return "Immediate"
        case .oneMinute:
            return "1 minute"
        case .fiveMinutes:
            return "5 minutes"
        case .fifteenMinutes:
            return "15 minutes"
        case .thirtyMinutes:
            return "30 minutes"
        case .oneHour:
            return "1 hour"
        }
    }
    
    static var `default`: AutoLockDuration { .immediate }
}

