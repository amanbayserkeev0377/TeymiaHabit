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
                Spacer()
                
                VStack(spacing: 16) {
                    ZStack {
                        Image("TeymiaHabitBlank")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.mainApp)
                        
                        HStack {
                            Spacer()
                            Button(role: .close) { onDismiss() } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 22))
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.primary)
                                    .frame(width: 44, height: 44)
                            }
                            .glassEffect(.clear.interactive(), in: .circle)
                            .padding(.trailing, 16)
                            .offset(y: -20)
                        }
                    }
                    
                    Text(title)
                        .font(.title3)
                        .fontWeight(.medium)
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                    
                    PinDotsView(pin: pin)
                }
                
                Spacer(minLength: 40)
                
                CustomNumberPad(
                    onNumberTap: addDigit,
                    onDeleteTap: removeDigit,
                    showBiometricButton: false
                )
                
                Spacer()
            }
            .padding(16)
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
