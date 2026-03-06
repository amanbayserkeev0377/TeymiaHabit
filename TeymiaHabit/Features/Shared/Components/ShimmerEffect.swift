import SwiftUI

extension View {
    @ViewBuilder
    func shimmer(_ config: ShimmerConfig) -> some View {
        self
            .modifier(ShimmerEffectHelper(config: config))
    }
}

fileprivate struct ShimmerEffectHelper: ViewModifier {
    var config: ShimmerConfig
    @State private var moveTo: CGFloat = -1.5

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    let size = geo.size
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0),
                                    config.highlight.opacity(config.highlightOpacity),
                                    .white.opacity(0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .blur(radius: config.blur)
                        .rotationEffect(.init(degrees: -20))
                        .offset(x: size.width * moveTo)
                }
                .mask(content)
            }
            .onAppear {
                withAnimation(.linear(duration: config.speed)
                    .delay(config.delay)
                    .repeatForever(autoreverses: false)) {
                        moveTo = 1.5
                }
            }
    }
}

struct ShimmerConfig {
    var highlight: Color = .white
    var blur: CGFloat = 15
    var highlightOpacity: CGFloat = 0.4
    var speed: CGFloat = 1
    var delay: Double = 4
}
