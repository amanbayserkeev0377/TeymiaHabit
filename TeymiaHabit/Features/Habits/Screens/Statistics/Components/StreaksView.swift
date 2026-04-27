import SwiftUI

struct StreaksView: View {
    let viewModel: HabitStatsViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            statCard(value: "\(viewModel.currentStreak)", label: "stats_streak", icon: "flame.fill")
            statCard(value: "\(viewModel.bestStreak)", label: "stats_best", icon: "star.fill")
            statCard(value: "\(viewModel.totalValue)", label: "stats_total", icon: "checkmark.circle.fill")
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func statCard(value: String, label: LocalizedStringResource, icon: String) -> some View {
        StatColumn(value: value, label: label, icon: icon)
    }
}

struct StatColumn: View {
    let value: String
    let label: LocalizedStringResource
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.primary.opacity(0.9).gradient)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.primary.opacity(0.7).gradient)
                
                Text(label)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primary.opacity(0.7).gradient)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
