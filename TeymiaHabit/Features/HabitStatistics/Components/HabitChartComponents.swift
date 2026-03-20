import SwiftUI
import Charts

// MARK: - Time Formatting

extension Int {
    /// Formats seconds into "H:MM" or "M:MM" without seconds, for chart display
    func formattedAsChartDuration() -> String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60

        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else if minutes > 0 {
            return String(format: "0:%02d", minutes)
        } else {
            return "0"
        }
    }
}

// MARK: - Y-Axis Values

/// Computes up to 4 evenly spaced Y-axis tick values based on the chart data max
func habitChartYAxisValues(for data: [ChartDataPoint], habitType: HabitType) -> [Int] {
    guard !data.isEmpty else { return [0] }

    let maxValue = data.map { $0.value }.max() ?? 0
    guard maxValue > 0 else { return [0] }

    let displayMax = habitType == .time ? maxValue / 3600 : maxValue
    let step = max(1, displayMax / 3)
    let values = [0, step, step * 2, step * 3].filter { $0 <= displayMax + step / 2 }

    return habitType == .time ? values.map { $0 * 3600 } : values
}

// MARK: - Chart Navigation Buttons

struct ChartNavigationButton: View {
    let systemImage: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 20))
                .foregroundStyle(isEnabled ? Color.primary.gradient : Color.white.opacity(0.5).gradient)
                .contentShape(Rectangle())
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
    }
}

// MARK: - Chart Stats Header

/// The three-column stats row: average | selected date | total
struct ChartStatsRow: View {
    let averageLabel: String
    let totalLabel: String
    let selectedDateLabel: String?
    let selectedValueLabel: String?
    let primaryColor: Color = .primary
    let secondaryColor: Color = .white.opacity(0.7)

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("average")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryColor.gradient)

                Text(averageLabel)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(primaryColor.gradient)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let dateLabel = selectedDateLabel, let valueLabel = selectedValueLabel {
                VStack(alignment: .center, spacing: 2) {
                    Text(dateLabel.capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(secondaryColor.gradient)

                    Text(valueLabel)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(primaryColor.gradient)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text("total")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryColor.gradient)

                Text(totalLabel)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(primaryColor.gradient)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Chart Period Header

/// Navigation arrows + period title + stats row
struct ChartPeriodHeader: View {
    let title: String
    let canGoPrevious: Bool
    let canGoNext: Bool
    let averageLabel: String
    let totalLabel: String
    let selectedDateLabel: String?
    let selectedValueLabel: String?
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ChartNavigationButton(systemImage: "chevron.left", isEnabled: canGoPrevious, action: onPrevious)
                Spacer()
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                ChartNavigationButton(systemImage: "chevron.right", isEnabled: canGoNext, action: onNext)
            }
            .padding(.horizontal, 16)

            ChartStatsRow(
                averageLabel: averageLabel,
                totalLabel: totalLabel,
                selectedDateLabel: selectedDateLabel,
                selectedValueLabel: selectedValueLabel
            )
        }
    }
}

// MARK: - Chart Y-Axis View Modifier

/// Applies the standard trailing Y-axis with dashed grid lines
struct HabitChartYAxisModifier: ViewModifier {
    let values: [Int]

    func body(content: Content) -> some View {
        content
            .chartYAxis {
                AxisMarks(position: .trailing, values: values) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.6, dash: [3]))
                        .foregroundStyle(.white.opacity(0.2).gradient)
                }
            }
    }
}

extension View {
    func habitChartYAxis(values: [Int]) -> some View {
        modifier(HabitChartYAxisModifier(values: values))
    }
}
