import SwiftUI

// MARK: - PIN Dots View

/// Visual representation of PIN input progress with shake animation for errors
struct PinDotsView: View {
    let pin: String
    let length: Int
    @State private var shakeAmount: CGFloat = 0
    
    // Design constants
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
    
    /// Creates PIN dots view
    /// - Parameters:
    ///   - pin: Current PIN string
    ///   - length: Total PIN length (default: 4)
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
    
    /// Individual PIN dot that shows filled/empty state
    /// - Parameter index: Position of the dot
    /// - Returns: Styled circle representing PIN digit
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
    
    /// Triggers shake animation for incorrect PIN feedback
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

/// Custom numeric keypad with optional biometric authentication button
struct CustomNumberPad: View {
    @Environment(\.privacyManager) private var privacyManager
    
    let onNumberTap: (String) -> Void
    let onDeleteTap: () -> Void
    let showBiometricButton: Bool
    let onBiometricTap: (() -> Void)?
    
    // Design constants
    private enum DesignConstants {
        static let buttonSize: CGFloat = 80
        static let buttonSpacing: CGFloat = 20
        static let horizontalPadding: CGFloat = 40
    }
    
    /// Number grid layout (3x3 for digits 1-9)
    private let numbers = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"]
    ]
    
    /// Creates custom number pad
    /// - Parameters:
    ///   - onNumberTap: Callback for number button taps
    ///   - onDeleteTap: Callback for delete button tap
    ///   - showBiometricButton: Whether to show biometric authentication button
    ///   - onBiometricTap: Callback for biometric button tap
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
            // Number rows (1-9)
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
            
            // Bottom row: biometric/empty, 0, delete
            HStack(spacing: DesignConstants.buttonSpacing) {
                // Left slot: biometric button or empty space
                if showBiometricButton {
                    biometricButton
                } else {
                    emptyButtonSpace
                }
                
                // Center: zero button
                NumberPadButton(
                    item: "0",
                    size: DesignConstants.buttonSize,
                    onNumberTap: onNumberTap,
                    onDeleteTap: onDeleteTap
                )
                
                // Right: delete button
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
    
    /// Biometric authentication button
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
    
    /// Empty space when biometric button is not shown
    private var emptyButtonSpace: some View {
        Color.clear
            .frame(width: DesignConstants.buttonSize, height: DesignConstants.buttonSize)
    }
    
    /// Biometric icon based on device capability
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

/// Individual button for the custom number pad
struct NumberPadButton: View {
    let item: String
    let size: CGFloat
    let onNumberTap: (String) -> Void
    let onDeleteTap: () -> Void
    
    /// Creates number pad button
    /// - Parameters:
    ///   - item: Button content ("0"-"9", "delete", or empty string)
    ///   - size: Button size (width and height)
    ///   - onNumberTap: Callback for number taps
    ///   - onDeleteTap: Callback for delete button tap
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
    
    /// Button content based on item type
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
    
    /// Delete button (backspace icon)
    private var deleteButtonContent: some View {
        Image(systemName: "delete.left")
            .font(.title)
            .foregroundStyle(.primary)
            .frame(width: size, height: size)
    }
    
    /// Number button (digit with background circle)
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
    
    /// Empty button space
    private var emptyButtonContent: some View {
        Color.clear
            .frame(width: size, height: size)
    }
    
    /// Handles button tap with haptic feedback
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
    /// Posted to trigger PIN dots shake animation
    static let shakePinDots = Notification.Name("shakePinDots")
}

// MARK: - Global Functions

/// Triggers PIN dots shake animation from anywhere in the app
func triggerPinDotsShake() {
    NotificationCenter.default.post(name: .shakePinDots, object: nil)
}
