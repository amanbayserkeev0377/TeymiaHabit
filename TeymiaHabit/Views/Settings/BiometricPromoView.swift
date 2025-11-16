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
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(.bottom, 30)
                
                VStack(spacing: 16) {
                    Text("enable".localized + " \(privacyManager.biometricDisplayName)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                    
                    Text("biometric_unlock_description".localized(with: privacyManager.biometricDisplayName))
                        .font(.body)
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
                        Text("enable".localized + " \(privacyManager.biometricDisplayName)")
                            .font(.headline)
                            .fontWeight(.medium)
                            .fontDesign(.rounded)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(#colorLiteral(red: 0.3, green: 0.8, blue: 0.4, alpha: 1)),
                                        Color(#colorLiteral(red: 0.1, green: 0.5, blue: 0.2, alpha: 1))
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                in: RoundedRectangle(cornerRadius: 30)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        HapticManager.shared.playSelection()
                        onDismiss()
                    } label: {
                        Text("not_now".localized)
                            .font(.body)
                            .fontDesign(.rounded)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
    
    @ViewBuilder
    private var biometricIcon: some View {
        let size: CGFloat = 80
        
        let baseImage: Image = {
            switch privacyManager.biometricType {
            case .faceID:
                Image("faceid")
            case .touchID:
                Image("touchid")
            case .opticID:
                Image("opticid")
            default:
                Image("key")
            }
        }()
        
        baseImage
            .resizable()
            .frame(width: size, height: size)
    }
}
