import SwiftUI

struct StreaksView: View {
    let viewModel: HabitStatsViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "laurel.leading")
                .font(.system(size: 38))
                .foregroundStyle(laurelGradient.gradient)
            
            Group {
                StatColumn(
                    value: "\(viewModel.currentStreak)",
                    label: "streak".localized
                )
                
                StatColumn(
                    value: "\(viewModel.bestStreak)",
                    label: "best".localized
                )
                
                StatColumn(
                    value: "\(viewModel.totalValue)",
                    label: "total".localized
                )
            }
            
            Image(systemName: "laurel.trailing")
                .font(.system(size: 38))
                .foregroundStyle(laurelGradient.gradient)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Gradient for Laurel Branches
    
    private var laurelGradient: Color {
        let habitColor = viewModel.habit.iconColor
        return habitColor.color
    }
}

struct StatColumn: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .fontDesign(.rounded)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(label)
                .font(.footnote)
                .fontDesign(.rounded)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}
