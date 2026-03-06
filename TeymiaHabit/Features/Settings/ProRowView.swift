import SwiftUI

struct ProRowView: View {
    @Environment(ProManager.self) private var proManager
    @State private var showingPaywall = false
    
    enum GradientPhase: CaseIterable {
        case first, second, third
        
        var colors: [Color] {
            switch self {
            case .first: return [Color(#colorLiteral(red: 0.4235294118, green: 0.5764705882, blue: 0.9960784314, alpha: 1)), Color(#colorLiteral(red: 0.7803921569, green: 0.3803921569, blue: 0.7568627451, alpha: 1))]
            case .second: return [Color(#colorLiteral(red: 0.3181028366, green: 0.5400418043, blue: 0.9980412126, alpha: 1)), Color(#colorLiteral(red: 0.5766596198, green: 0.4650856853, blue: 0.9760690331, alpha: 1))]
            case .third: return [Color(#colorLiteral(red: 0.4936487675, green: 0.5068361759, blue: 0.9980413318, alpha: 1)), Color(#colorLiteral(red: 0.8374075294, green: 0.424548924, blue: 0.8359348178, alpha: 1))]
            }
        }
    }
    
    var body: some View {
        Section {
            if !proManager.isPro {
                proPromoView
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Pro Promo View
    private var proPromoView: some View {
        Button {
            showingPaywall = true
        } label: {
            HStack {
                Image(systemName: "sparkles.2")
                    .font(.system(size: 24))
                    .symbolEffect(.wiggle, options: .repeat(.periodic(delay: 3.8)))
                
                VStack(alignment: .leading) {
                    Text("Teymia Habit Pro")
                        .font(.title3).bold().minimumScaleFactor(0.8)
                    
                    Text("paywall_unlock_premium")
                        .font(.footnote).fontWeight(.medium).lineLimit(1).minimumScaleFactor(0.8)
                }
                Spacer()
                FreeTrialButton()
            }
            .padding()
            .foregroundStyle(.white.gradient)
            .background {
                ZStack {
                    Color.clear
                        .phaseAnimator(GradientPhase.allCases) { content, phase in
                            content
                                .background {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: phase.colors,
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                }
                        } animation: { _ in
                                .easeInOut(duration: 5).delay(3)
                        }
                    
                    Capsule()
                        .fill(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
                        .overlay {
                            Capsule()
                                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                        }
                        .blendMode(.overlay)
                }
                .clipShape(Capsule())
            }
            .shimmer(.init())
        }
        .buttonStyle(.plain)
        .phaseAnimator([0, 1]) { content, phase in
            content
                .scaleEffect(phase == 1 ? 1.0 : 0.97)
        } animation: { _ in
                .easeInOut(duration: 4)
        }
    }
}

// MARK: - Free Trial Button
struct FreeTrialButton: View {
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "gift.fill")
                .font(.system(size: 12))
            
            Text("paywall_7_days_free_trial")
                .font(.footnote).fontWeight(.semibold)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .glassEffect(.clear.interactive().tint(.white.opacity(0.07)), in: .capsule)
    }
}
