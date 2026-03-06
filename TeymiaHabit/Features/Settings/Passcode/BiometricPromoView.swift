import SwiftUI

struct BiometricPromoView: View {
    @Environment(\.privacyManager) private var privacyManager
    let onEnable: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                Spacer()
                
                biometricIcon
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(#colorLiteral(red: 0.3, green: 0.8, blue: 0.4, alpha: 1)),
                                Color(#colorLiteral(red: 0.1, green: 0.5, blue: 0.2, alpha: 1))
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.bottom, 30)
                
                VStack(spacing: 16) {
                    Text("enable" + " \(privacyManager.biometricDisplayName)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                    
                    Text("biometric_unlock_description \(privacyManager.biometricDisplayName)")
                        .fontWeight(.medium)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                Spacer()
                
                VStack(spacing: 16) {
                    Button {
                        HapticManager.shared.playSelection()
                        onEnable()
                    } label: {
                        Text("enable" + " \(privacyManager.biometricDisplayName)")
                            .font(.headline)
                            .fontWeight(.medium)
                            .fontDesign(.rounded)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(#colorLiteral(red: 0.3, green: 0.8, blue: 0.4, alpha: 1)),
                                        Color(#colorLiteral(red: 0.1, green: 0.5, blue: 0.2, alpha: 1))
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: Capsule())
                    
                    Button {
                        HapticManager.shared.playSelection()
                        onDismiss()
                    } label: {
                        Text("not_now")
                            .fontDesign(.rounded)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: Capsule())
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
    
    @ViewBuilder
    private var biometricIcon: some View {
        let size: CGFloat = 80
        
        switch privacyManager.biometricType {
        case .faceID:
            Image(systemName: "faceid")
                .font(.system(size: size))
        case .touchID:
            Image(systemName: "touchid")
                .font(.system(size: size))
        case .opticID:
            Image(systemName:"opticid")
                .font(.system(size: size))
        default:
            Image(systemName: "key")
                .font(.system(size: size))
        }
    }
}
