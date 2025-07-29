import SwiftUI

// MARK: - PIN Dots View с shake анимацией
struct PinDotsView: View {
    let pin: String
    let length: Int
    @State private var shakeAmount: CGFloat = 0
    
    init(pin: String, length: Int = 4) {
        self.pin = pin
        self.length = length
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<length, id: \.self) { index in
                Circle()
                    .fill(pin.count > index ? Color.primary : Color.clear)
                    .overlay(
                        Circle()
                            .stroke(Color.primary, lineWidth: 1)
                    )
                    .frame(width: 16, height: 16)
                    .animation(.easeInOut(duration: 0.3), value: pin.count)
            }
        }
        .offset(x: shakeAmount)
        .onReceive(NotificationCenter.default.publisher(for: .shakePinDots)) { _ in
            shake()
        }
    }
    
    // Рабочая shake анимация
    private func shake() {
        withAnimation(.easeInOut(duration: 0.05).repeatCount(6, autoreverses: true)) {
            shakeAmount = 8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.1)) {
                shakeAmount = 0
            }
        }
    }
}

// MARK: - Notification Extension для удобства
extension Notification.Name {
    static let shakePinDots = Notification.Name("shakePinDots")
}

// MARK: - Функция для вызова shake из любого места
func triggerPinDotsShake() {
    NotificationCenter.default.post(name: .shakePinDots, object: nil)
}

// MARK: - Custom Number Pad (без изменений)
struct CustomNumberPad: View {
    @Environment(\.privacyManager) private var privacyManager
    
    let onNumberTap: (String) -> Void
    let onDeleteTap: () -> Void
    let showBiometricButton: Bool
    let onBiometricTap: (() -> Void)?
    
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
    
    private let numbers = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"]
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            ForEach(numbers, id: \.self) { row in
                HStack(spacing: 20) {
                    ForEach(row, id: \.self) { item in
                        NumberPadButton(
                            item: item,
                            onNumberTap: onNumberTap,
                            onDeleteTap: onDeleteTap
                        )
                    }
                }
            }
            
            HStack(spacing: 20) {
                if showBiometricButton {
                    Button {
                        HapticManager.shared.playSelection()
                        onBiometricTap?()
                    } label: {
                        biometricIcon
                            .font(.title)
                            .foregroundStyle(.primary)
                            .frame(width: 80, height: 80)
                    }
                    .buttonStyle(.plain)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 80, height: 80)
                }
                
                NumberPadButton(item: "0", onNumberTap: onNumberTap, onDeleteTap: onDeleteTap)
                NumberPadButton(item: "delete", onNumberTap: onNumberTap, onDeleteTap: onDeleteTap)
            }
        }
        .padding(.horizontal, 40)
    }
    
    @ViewBuilder
    private var biometricIcon: some View {
        switch privacyManager.biometricType {
        case .faceID: Image(systemName: "faceid")
        case .touchID: Image(systemName: "touchid")
        case .opticID: Image(systemName: "opticid")
        default: Image(systemName: "lock.fill")
        }
    }
}

struct NumberPadButton: View {
    let item: String
    let onNumberTap: (String) -> Void
    let onDeleteTap: () -> Void
    
    var body: some View {
        Button {
            if item == "delete" {
                HapticManager.shared.playSelection()
                onDeleteTap()
            } else if !item.isEmpty {
                HapticManager.shared.playSelection()
                onNumberTap(item)
            }
        } label: {
            if item == "delete" {
                Image(systemName: "delete.left")
                    .font(.title)
                    .foregroundStyle(.primary)
                    .frame(width: 80, height: 80)
            } else if !item.isEmpty {
                ZStack {
                    Circle()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: 80, height: 80)
                    Text(item)
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 80, height: 80)
            }
        }
        .buttonStyle(.plain)
        .disabled(item.isEmpty)
    }
}
