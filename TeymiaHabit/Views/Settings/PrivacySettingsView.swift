import SwiftUI
import LocalAuthentication

struct PrivacySettingsView: View {
    @Environment(\.privacyManager) private var privacyManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.globalPin) private var globalPin
    
    @State private var pinAction: PinAction = .setup
    @State private var isAwaitingConfirmation = false
    @State private var firstPin = ""
    
    @AppStorage("autoLockDuration") private var autoLockDuration = AutoLockDuration.immediate.rawValue
    
    enum PinAction {
        case setup
        case change
        case verify
        case disable
    }
    
    var body: some View {
        settingsContent
            .navigationTitle("passcode_faceid".localized)
            .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Private Methods
    
    @ViewBuilder
    private var settingsContent: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    
                    Image("lock.password")
                        .resizable()
                        .frame(
                            width: UIScreen.main.bounds.width * 0.25,
                            height: UIScreen.main.bounds.width * 0.25
                        )
                        .foregroundStyle(.gray.gradient)
                    
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            .listSectionSeparator(.hidden)
            
            Section {
                if !privacyManager.isPrivacyEnabled || !privacyManager.hasPinSet {
                    Button {
                        startPinSetup()
                    } label: {
                        Label {
                            Text("turn_passcode_on")
                                .font(.body)
                                .foregroundStyle(Color(UIColor.label))
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
                    Button {
                        startPinChange()
                    } label: {
                        Label {
                            Text("change_passcode".localized)
                                .font(.body)
                                .foregroundStyle(Color(UIColor.label))
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
                    
                    Button {
                        startPinDisable()
                    } label: {
                        Label {
                            Text("disable_passcode".localized)
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
            
            if privacyManager.isPrivacyEnabled && privacyManager.hasPinSet {
                Section {
                    NavigationLink {
                        RequestPasscodeSettingsView()
                    } label: {
                        HStack {
                            Label {
                                Text("request_passcode".localized)
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
    
    private var currentAutoLockDisplayName: String {
        let duration = AutoLockDuration(rawValue: autoLockDuration) ?? .immediate
        return duration.displayName
    }
    
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
    
    private func startPinSetup() {
        pinAction = .setup
        isAwaitingConfirmation = false
        
        globalPin.showPin("create_passcode".localized, { pin in
            handlePinComplete(pin)
        }, {
            globalPin.hidePin()
        })
    }

    private func startPinChange() {
        pinAction = .verify
        
        globalPin.showPin("enter_current_passcode".localized, { pin in
            handlePinComplete(pin)
        }, {
            globalPin.hidePin()
        })
    }
    
    private func startPinDisable() {
        pinAction = .disable
        
        globalPin.showPin("enter_passcode".localized, { pin in
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
                globalPin.showPin("confirm_passcode".localized, { confirmPin in
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        globalPin.showPin("create_passcode".localized, { retryPin in
                            handlePinComplete(retryPin)
                        }, { globalPin.hidePin() })
                    }
                }
            }
            
        case .change:
            if !isAwaitingConfirmation {
                firstPin = pin
                isAwaitingConfirmation = true
                globalPin.showPin("confirm_passcode".localized, { confirmPin in
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
                        globalPin.showPin("enter_new_passcode".localized, { retryPin in
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
                globalPin.showPin("enter_new_passcode".localized, { newPin in
                    handlePinComplete(newPin)
                }, { globalPin.hidePin() })
            } else {
                HapticManager.shared.play(.error)
                triggerPinDotsShake()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    globalPin.showPin("enter_current_passcode".localized, { retryPin in
                        handlePinComplete(retryPin)
                    }, { globalPin.hidePin() })
                }
            }
            
        case .disable:
            if PinManager.shared.validatePin(pin) {
                HapticManager.shared.playSelection()
                globalPin.hidePin()
                disableProtection()
            } else {
                HapticManager.shared.play(.error)
                triggerPinDotsShake()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    globalPin.showPin("enter_passcode".localized, { retryPin in
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
                if privacyManager.biometricType != .none && !privacyManager.isBiometricEnabled {
                    showBiometricPromo()
                } else {
                    globalPin.hidePin()
                }
            }
        }
    }

    private func showBiometricPromo() {
        globalPin.showBiometricPromo(
            privacyManager.biometricType,
            privacyManager.biometricDisplayName,
            {
                privacyManager.enableBiometricsForPin()
                globalPin.hidePin()
                globalPin.hideBiometricPromo()
            },
            {
                globalPin.hidePin()
                globalPin.hideBiometricPromo()
            }
        )
    }
    
    private func disableProtection() {
        Task {
            _ = await privacyManager.disablePrivacy()
        }
    }
}

// MARK: - Request Passcode Settings

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
        .navigationTitle("request_passcode".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

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
            return "immediately".localized
        case .oneMinute:
            return "1_minute".localized
        case .fiveMinutes:
            return "5_minutes".localized
        case .fifteenMinutes:
            return "15_minutes".localized
        case .thirtyMinutes:
            return "30_minutes".localized
        case .oneHour:
            return "1_hour".localized
        }
    }
    
    static var `default`: AutoLockDuration { .immediate }
}
