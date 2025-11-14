import SwiftUI

// MARK: - PIN Dots View

struct PinDotsView: View {
    let pin: String
    let length: Int
    @State private var shakeAmount: CGFloat = 0
    
    private enum DesignConstants {
        static let dotSize: CGFloat = 16
        static let dotSpacing: CGFloat = 16
        static let shakeDistance: CGFloat = 8
        static let animationDuration: Double = 0.3
        static let shakeAnimationDuration: Double = 0.05
        static let shakeResetDuration: Double = 0.1
        static let shakeResetDelay: Double = 0.3
        static let shakeRepeatCount = 6
    }
    
    init(pin: String, length: Int = 4) {
        self.pin = pin
        self.length = length
    }
    
    var body: some View {
        HStack(spacing: DesignConstants.dotSpacing) {
            ForEach(0..<length, id: \.self) { index in
                pinDot(at: index)
            }
        }
        .offset(x: shakeAmount)
        .onReceive(NotificationCenter.default.publisher(for: .shakePinDots)) { _ in
            shake()
        }
    }
    
    private func pinDot(at index: Int) -> some View {
        Circle()
            .fill(pin.count > index ? Color.primary : Color.clear)
            .overlay(
                Circle()
                    .stroke(Color.primary, lineWidth: 1)
            )
            .frame(width: DesignConstants.dotSize, height: DesignConstants.dotSize)
            .animation(.easeInOut(duration: DesignConstants.animationDuration), value: pin.count)
    }
    
    private func shake() {
        withAnimation(.easeInOut(duration: DesignConstants.shakeAnimationDuration).repeatCount(DesignConstants.shakeRepeatCount, autoreverses: true)) {
            shakeAmount = DesignConstants.shakeDistance
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + DesignConstants.shakeResetDelay) {
            withAnimation(.easeInOut(duration: DesignConstants.shakeResetDuration)) {
                shakeAmount = 0
            }
        }
    }
}

// MARK: - Custom Number Pad

struct CustomNumberPad: View {
    @Environment(\.privacyManager) private var privacyManager
    
    let onNumberTap: (String) -> Void
    let onDeleteTap: () -> Void
    let showBiometricButton: Bool
    let onBiometricTap: (() -> Void)?
    
    private enum DesignConstants {
        static let buttonSize: CGFloat = 80
        static let buttonSpacing: CGFloat = 20
        static let horizontalPadding: CGFloat = 40
    }
    
    private let numbers = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"]
    ]
    
    init(
        onNumberTap: @escaping (String) -> Void,
        onDeleteTap: @escaping () -> Void,
        showBiometricButton: Bool = false,
        onBiometricTap: (() -> Void)? = nil
    ) {
        self.onNumberTap = onNumberTap
        self.onDeleteTap = onDeleteTap
        self.showBiometricButton = showBiometricButton
        self.onBiometricTap = onBiometricTap
    }
    
    var body: some View {
        VStack(spacing: DesignConstants.buttonSpacing) {
            ForEach(numbers, id: \.self) { row in
                HStack(spacing: DesignConstants.buttonSpacing) {
                    ForEach(row, id: \.self) { item in
                        NumberPadButton(
                            item: item,
                            size: DesignConstants.buttonSize,
                            onNumberTap: onNumberTap,
                            onDeleteTap: onDeleteTap
                        )
                    }
                }
            }
            
            HStack(spacing: DesignConstants.buttonSpacing) {
                if showBiometricButton {
                    biometricButton
                } else {
                    emptyButtonSpace
                }
                
                NumberPadButton(
                    item: "0",
                    size: DesignConstants.buttonSize,
                    onNumberTap: onNumberTap,
                    onDeleteTap: onDeleteTap
                )
                
                NumberPadButton(
                    item: "delete",
                    size: DesignConstants.buttonSize,
                    onNumberTap: onNumberTap,
                    onDeleteTap: onDeleteTap
                )
            }
        }
        .padding(.horizontal, DesignConstants.horizontalPadding)
    }
    
    private var biometricButton: some View {
        Button {
            HapticManager.shared.playSelection()
            onBiometricTap?()
        } label: {
            biometricIcon
                .font(.title)
                .foregroundStyle(.primary)
                .frame(width: DesignConstants.buttonSize, height: DesignConstants.buttonSize)
        }
        .buttonStyle(.plain)
    }
    
    private var emptyButtonSpace: some View {
        Color.clear
            .frame(width: DesignConstants.buttonSize, height: DesignConstants.buttonSize)
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
            Image(systemName: "lock.fill")
        }
    }
}

// MARK: - Number Pad Button

struct NumberPadButton: View {
    let item: String
    let size: CGFloat
    let onNumberTap: (String) -> Void
    let onDeleteTap: () -> Void
    
    init(
        item: String,
        size: CGFloat = 80,
        onNumberTap: @escaping (String) -> Void,
        onDeleteTap: @escaping () -> Void
    ) {
        self.item = item
        self.size = size
        self.onNumberTap = onNumberTap
        self.onDeleteTap = onDeleteTap
    }
    
    var body: some View {
        Button {
            handleButtonTap()
        } label: {
            buttonContent
        }
        .buttonStyle(.plain)
        .disabled(item.isEmpty)
    }
    
    @ViewBuilder
    private var buttonContent: some View {
        if item == "delete" {
            deleteButtonContent
        } else if !item.isEmpty {
            numberButtonContent
        } else {
            emptyButtonContent
        }
    }
    
    private var deleteButtonContent: some View {
        Image(systemName: "delete.left")
            .font(.title)
            .foregroundStyle(.primary)
            .frame(width: size, height: size)
    }
    
    private var numberButtonContent: some View {
        ZStack {
            Circle()
                .fill(Color.secondary.opacity(0.1))
                .frame(width: size, height: size)
            Text(item)
                .font(.title)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
    }
    
    private var emptyButtonContent: some View {
        Color.clear
            .frame(width: size, height: size)
    }
    
    private func handleButtonTap() {
        HapticManager.shared.playSelection()
        
        if item == "delete" {
            onDeleteTap()
        } else if !item.isEmpty {
            onNumberTap(item)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let shakePinDots = Notification.Name("shakePinDots")
}

// MARK: - Global Functions

func triggerPinDotsShake() {
    NotificationCenter.default.post(name: .shakePinDots, object: nil)
}
