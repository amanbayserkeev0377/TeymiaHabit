import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let currentValue: String
    let isCompleted: Bool
    let isExceeded: Bool
    let habit: Habit?
    
    var size: CGFloat = 180
    var lineWidth: CGFloat? = nil
    var fontSize: CGFloat? = nil
    var iconSize: CGFloat? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var ringColors: [Color] {
        return AppColorManager.shared.getRingColors(
            for: habit,
            isCompleted: isCompleted,
            isExceeded: isExceeded,
            colorScheme: colorScheme
        )
    }
    
    private var textColor: Color {
        if isCompleted || isExceeded {
            return Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1))
        } else {
            return .primary
        }
    }
    
    private var adaptiveLineWidth: CGFloat {
        return lineWidth ?? (size * 0.11)
    }
    
    private var adaptedFontSize: CGFloat {
        if let customFontSize = fontSize {
            return customFontSize
        }
        
        let baseSize = size * 0.20
        let digitsCount = currentValue.filter { $0.isNumber }.count
        
        let factor: CGFloat
        switch digitsCount {
        case 0...3: factor = 1.0
        case 4: factor = 0.9
        case 5: factor = 0.85
        case 6: factor = 0.75
        default: factor = 0.65
        }
        
        return baseSize * factor
    }
    
    private var adaptedIconSize: CGFloat {
        return iconSize ?? (size * 0.4)
    }
    
    var body: some View {
        ZStack {
            // Фоновый круг
            Circle()
                .stroke(Color.secondary.opacity(0.1), lineWidth: adaptiveLineWidth)
            
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    LinearGradient(
                        colors: ringColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: adaptiveLineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
            
            if isCompleted && !isExceeded {
                Image(systemName: "checkmark")
                    .font(.system(size: adaptedIconSize, weight: .bold))
                    .foregroundStyle(textColor)
            } else {
                Text(currentValue)
                    .font(.system(size: adaptedFontSize, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(textColor)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
        }
        .frame(width: size, height: size)
    }
}
