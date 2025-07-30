import SwiftUI

struct StreaksView: View {
    let viewModel: HabitStatsViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "laurel.leading")
                .font(.system(size: 38))
                .foregroundStyle(laurelGradient)
            
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
                .foregroundStyle(laurelGradient)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Gradient for Laurel Branches
    
    private var laurelGradient: LinearGradient {
        let habitColor = viewModel.habit.iconColor
        return habitColor.adaptiveGradient(
            for: colorScheme)
    }
}

struct StatColumn: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}
