import SwiftUI

// MARK: - Lively Floating Blobs Background (Lava Lamp Effect)

struct LivelyFloatingBlobsBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.mainBackground
                    .ignoresSafeArea()
                
                LivelyBlob(
                    index: 0,
                    color: colorScheme == .dark
                    ?  Color(#colorLiteral(red: 0.7803921569, green: 0.3803921569, blue: 0.7568627451, alpha: 1)).opacity(0.35)
                    :  Color(#colorLiteral(red: 0.7803921569, green: 0.3803921569, blue: 0.7568627451, alpha: 1)).opacity(0.3),
                        
                    size: 210,
                    positions: [
                        CGPoint(x: geo.size.width * 0.15, y: geo.size.height * 0.2),
                            CGPoint(x: geo.size.width * 0.25, y: geo.size.height * 0.4),
                            CGPoint(x: geo.size.width * 0.2, y: geo.size.height * 0.7),
                            CGPoint(x: geo.size.width * 0.3, y: geo.size.height * 0.55),
                            CGPoint(x: geo.size.width * 0.18, y: geo.size.height * 0.35)
                    ],
                    duration: 4,
                    blur: 60
                )
                
                LivelyBlob(
                    index: 1,
                    color: colorScheme == .dark
                    ? Color(#colorLiteral(red: 0.4235294118, green: 0.5764705882, blue: 0.9960784314, alpha: 1)).opacity(0.45)
                    : Color(#colorLiteral(red: 0.4235294118, green: 0.5764705882, blue: 0.9960784314, alpha: 1)).opacity(0.5),
                    size: 190,
                    positions: [
                        CGPoint(x: geo.size.width * 0.75, y: geo.size.height * 0.25),
                            CGPoint(x: geo.size.width * 0.85, y: geo.size.height * 0.5),
                            CGPoint(x: geo.size.width * 0.8, y: geo.size.height * 0.75),
                            CGPoint(x: geo.size.width * 0.7, y: geo.size.height * 0.6),
                            CGPoint(x: geo.size.width * 0.82, y: geo.size.height * 0.4)
                    ],
                    duration: 5,
                    blur: 60
                )
                
                LivelyBlob(
                    index: 2,
                    color: colorScheme == .dark
                    ? Color(#colorLiteral(red: 0.4925274849, green: 0.5225450397, blue: 0.9995061755, alpha: 1)).opacity(0.5)
                    : Color(#colorLiteral(red: 0.4925274849, green: 0.5225450397, blue: 0.9995061755, alpha: 1)).opacity(0.6),
                    size: 170,
                    positions: [
                        CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.3),
                            CGPoint(x: geo.size.width * 0.55, y: geo.size.height * 0.5),
                            CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.7),
                        CGPoint(x: geo.size.width * 0.45, y: geo.size.height * 0.5)
                    ],
                    duration: 3,
                    blur: 60
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Single Lively Blob

struct LivelyBlob: View {
    let index: Int
    let color: Color
    let size: CGFloat
    let positions: [CGPoint]
    let duration: Double
    let blur: CGFloat
    
    @State private var currentIndex = 0
    
    private var currentPosition: CGPoint {
        positions[currentIndex % positions.count]
    }
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        color,
                        color.opacity(0.7),
                        color.opacity(0.4),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: blur)
            .position(currentPosition)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.5) {
                    startMoving()
                }
            }
    }
    
    private func startMoving() {
        withAnimation(
            .easeInOut(duration: duration)
        ) {
            currentIndex += 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            startMoving()
        }
    }
}

// MARK: - Preview

#Preview("Dark Mode") {
    LivelyFloatingBlobsBackground()
        .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    LivelyFloatingBlobsBackground()
        .preferredColorScheme(.light)
}
