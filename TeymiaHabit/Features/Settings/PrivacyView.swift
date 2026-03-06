import SwiftUI
import LocalAuthentication

struct PrivacyRowView: View {
    var body: some View {
        NavigationLink(destination: PrivacyView()) {
            Label(
                title: { Text("settings_passcode_faceid") },
                icon: { Image(systemName: "faceid").iconStyle() }
            )
        }
    }
}

struct PrivacyView: View {
    @Environment(\.privacyManager) private var privacyManager
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
            .appBackground()
            .navigationTitle("settings_passcode_faceid")
    }
    
    // MARK: - Private Methods
    
    @ViewBuilder
    private var settingsContent: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    
                    Image(systemName: "lock.badge.checkmark.fill")
                        .font(.system(size: 90))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.mainApp.gradient, Color.primary.gradient)
                    
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            .listSectionSeparator(.hidden)
            .listRowSpacing(0)
            
            Section {
                if !privacyManager.isPrivacyEnabled || !privacyManager.hasPinSet {
                    Button {
                        startPinSetup()
                    } label: {
                        Label { Text("turn_passcode_on").foregroundStyle(Color.primary) }
                        icon: { Image(systemName: "shield").iconStyle() }
                    }
                } else {
                    Button {
                        startPinChange()
                    } label: {
                        Label { Text("change_passcode").foregroundStyle(Color.primary) }
                        icon: { Image(systemName: "key").iconStyle() }
                    }
                    
                    Button {
                        startPinDisable()
                    } label: {
                        Label { Text("disable_passcode").foregroundStyle(.red.gradient) }
                        icon: {
                            Image(systemName: "xmark.shield.fill")
                                .font(.footnote).fontWeight(.medium)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.white.gradient, .red.gradient)
                                .frame(width: 30, height: 30)
                                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                            
                        }
                    }
                }
            }
            .listRowBackground(Color.rowBackground)
            
            if privacyManager.isPrivacyEnabled && privacyManager.hasPinSet {
                Section {
                    NavigationLink {
                        RequestPasscodeSettingsView()
                    } label: {
                        HStack {
                            Label { Text("request_passcode") }
                            icon: { Image(systemName: "clock").iconStyle() }
                            
                            Spacer()
                            
                            Text(currentAutoLockDisplayName).foregroundStyle(.secondary)
                        }
                    }
                }
                .listRowBackground(Color.rowBackground)
            }
            
            if privacyManager.isPrivacyEnabled && privacyManager.hasPinSet && privacyManager.biometricType != .none {
                Section {
                    HStack {
                        Label {
                            Text(privacyManager.biometricDisplayName)
                        } icon: {
                            biometricIcon
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.primary)
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
                        .tint(.mainApp)
                    }
                }
                .listRowBackground(Color.rowBackground)
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
            Image(systemName:"opticid")
        default:
            Image(systemName: "key")
        }
    }
    
    private func startPinSetup() {
        pinAction = .setup
        isAwaitingConfirmation = false
        
        globalPin.showPin("create_passcode", { pin in
            handlePinComplete(pin)
        }, {
            globalPin.hidePin()
        })
    }
    
    private func startPinChange() {
        pinAction = .verify
        
        globalPin.showPin("enter_current_passcode", { pin in
            handlePinComplete(pin)
        }, {
            globalPin.hidePin()
        })
    }
    
    private func startPinDisable() {
        pinAction = .disable
        
        globalPin.showPin("enter_passcode", { pin in
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
                globalPin.showPin("confirm_passcode", { confirmPin in
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
                        globalPin.showPin("create_passcode", { retryPin in
                            handlePinComplete(retryPin)
                        }, { globalPin.hidePin() })
                    }
                }
            }
            
        case .change:
            if !isAwaitingConfirmation {
                firstPin = pin
                isAwaitingConfirmation = true
                globalPin.showPin("confirm_passcode", { confirmPin in
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
                        globalPin.showPin("enter_new_passcode", { retryPin in
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
                globalPin.showPin("enter_new_passcode", { newPin in
                    handlePinComplete(newPin)
                }, { globalPin.hidePin() })
            } else {
                HapticManager.shared.play(.error)
                triggerPinDotsShake()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    globalPin.showPin("enter_current_passcode", { retryPin in
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
                    globalPin.showPin("enter_passcode", { retryPin in
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
                            .foregroundStyle(Color.primary)
                        
                        Spacer()
                        
                        if selectedDuration == duration { SelectionCheckmark() }
                    }
                }
            }
            .listRowBackground(Color.rowBackground)
            .animation(.snappy, value: selectedDuration)
        }
        .appBackground()
        .navigationTitle("request_passcode")
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
            return "immediately"
        case .oneMinute:
            return "1_minute"
        case .fiveMinutes:
            return "5_minutes"
        case .fifteenMinutes:
            return "15_minutes"
        case .thirtyMinutes:
            return "30_minutes"
        case .oneHour:
            return "1_hour"
        }
    }
    
    static var `default`: AutoLockDuration { .immediate }
}
