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
    private func statCard(value: String, label: String, icon: String) -> some View {
        StatColumn(value: value, label: label, icon: icon)
            .padding(.vertical, 12)
            .glassEffect(.regular.tint(Color.rowBackground), in: RoundedRectangle(
                cornerRadius: 24, style: .continuous
            ))
    }
}

struct StatColumn: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary.opacity(0.7))
                
                Text(label)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
