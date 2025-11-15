import SwiftUI

struct EmptyStateView: View {
    @State private var isAnimating = false
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = 30
    @State private var buttonOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.8
    @ObservedObject private var colorManager = AppColorManager.shared
    
    let onCreateHabit: () -> Void
    
    private var isCompactHeight: Bool {
        UIScreen.main.bounds.height <= 667
    }
    
    private var imageSize: CGFloat {
        isCompactHeight ? 120 : 160
    }
    
    private var topPadding: CGFloat {
        isCompactHeight ? 20 : 60
    }
    
    private var verticalSpacing: CGFloat {
        isCompactHeight ? 24 : 40
    }
    
    var body: some View {
        VStack(spacing: verticalSpacing) {
            Image("TeymiaHabitBlank")
                .resizable()
                .scaledToFit()
                .frame(width: imageSize, height: imageSize)
                .scaleEffect(isAnimating ? 1.15 : 0.9)
            
            VStack(spacing: isCompactHeight ? 12 : 16) {
                Text("empty_view_largetitle".localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)
                
                Text("empty_view_title3".localized)
                    .font(.title3)
                    .fontDesign(.rounded)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .minimumScaleFactor(0.7)
                    .lineLimit(3)
                    .opacity(subtitleOpacity)
                    .offset(y: subtitleOffset)
            }
            
            Button(action: {
                HapticManager.shared.playSelection()
                onCreateHabit()
            }) {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(UIColor.systemBackground))
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(colorManager.selectedColor.color.gradient)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.top, isCompactHeight ? 12 : 24)
            .opacity(buttonOpacity)
            .scaleEffect(buttonScale)
            
            if !isCompactHeight {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, topPadding)
        .padding(.horizontal, 16)
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).delay(0.8)) {
                titleOpacity = 1.0
                titleOffset = 0
            }
            
            withAnimation(.easeOut(duration: 1.5).delay(1.6)) {
                subtitleOpacity = 1.0
                subtitleOffset = 0
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(2.4)) {
                buttonOpacity = 1.0
                buttonScale = 1.0
            }

            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}
