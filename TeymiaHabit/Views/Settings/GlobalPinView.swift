import SwiftUI

struct GlobalPinView: View {
    let title: String
    @Binding var pin: String
    let onPinComplete: (String) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(.regularMaterial))
                    }
                }
                .padding(.top, 40)
                .padding(.horizontal, 40)
                
                Spacer()
                
                VStack(spacing: 30) {
                    Image("TeymiaHabitBlank")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                    
                    Text(title)
                        .font(.title3)
                        .foregroundStyle(.primary)
                    
                    PinDotsView(pin: pin)
                }
                
                Spacer(minLength: 50)
                
                CustomNumberPad(
                    onNumberTap: addDigit,
                    onDeleteTap: removeDigit,
                    showBiometricButton: false
                )
                .padding(.horizontal, 40)
                
                Spacer()
                Spacer()
            }
        }
    }
    
    private func addDigit(_ digit: String) {
        guard pin.count < 4 else { return }
        pin += digit
        
        if pin.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onPinComplete(pin)
            }
        }
    }
    
    private func removeDigit() {
        guard !pin.isEmpty else { return }
        pin = String(pin.dropLast())
    }
}
