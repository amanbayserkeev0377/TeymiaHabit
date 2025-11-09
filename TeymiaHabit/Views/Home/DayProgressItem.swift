import SwiftUI

struct DayProgressItem: View, Equatable {
    let date: Date
    let isSelected: Bool
    let progress: Double
    let onTap: () -> Void
    var showProgressRing: Bool = true
    var habit: Habit? = nil
    var isOverallProgress: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject private var colorManager = AppColorManager.shared
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    private var dayNumber: String {
        "\(calendar.component(.day, from: date))"
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var isFutureDate: Bool {
        date > Date()
    }
    
    private var isValidDate: Bool {
        date <= Date().addingTimeInterval(86400 * 365)
    }
    
    private var progressColor: Color {
        if progress > 0 {
            let isCompleted = progress >= 1.0
            let isExceeded: Bool
            
            if isOverallProgress {
                isExceeded = progress > 1.0
            } else {
                isExceeded = habit?.isExceededForDate(date) ?? false
            }
            
            return AppColorManager.shared.getRingColor(
                for: habit,
                isCompleted: isCompleted,
                isExceeded: isExceeded
            )
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    private var circleSize: CGFloat {
        switch dynamicTypeSize {
        case .accessibility5: return 40
        case .accessibility4: return 38
        case .accessibility3: return 36
        case .accessibility2: return 34
        case .accessibility1: return 32
        default: return 30
        }
    }
    
    private var lineWidth: CGFloat {
        switch dynamicTypeSize {
        case .accessibility5, .accessibility4, .accessibility3:
            return 4.0
        case .accessibility2, .accessibility1:
            return 3.8
        default:
            return 3.5
        }
    }
    
    private var fontSize: CGFloat {
        switch dynamicTypeSize {
        case .accessibility5: return 17
        case .accessibility4: return 16
        case .accessibility3: return 15
        case .accessibility2: return 14
        case .accessibility1: return 13.5
        default: return 13
        }
    }
    
    private var dayTextColor: Color {
        if isToday {
            return .orange
        } else if isSelected {
            return .primary
        } else if isFutureDate {
            return .primary
        } else {
            return .primary
        }
    }
    
    private var fontWeight: Font.Weight {
        if isSelected {
            return .bold
        } else {
            return .regular
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    if showProgressRing && !isFutureDate {
                        Circle()
                            .stroke(Color.secondary.opacity(0.15), lineWidth: lineWidth)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                progressColor.gradient,
                                style: StrokeStyle(
                                    lineWidth: lineWidth,
                                    lineCap: .round
                                )
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.5), value: progress)
                    }
                    
                    Text(dayNumber)
                        .font(.system(size: fontSize, weight: fontWeight))
                        .fontDesign(.rounded)
                        .foregroundColor(dayTextColor)
                }
                .frame(width: circleSize, height: circleSize)
                
                Circle()
                    .fill(isToday ? Color.orange : Color.primary)
                    .frame(width: 4, height: 4)
                    .opacity(isSelected ? 1 : 0)
            }
        }
        .buttonStyle(.plain)
        .disabled(isFutureDate || !isValidDate)
    }
    
    static func == (lhs: DayProgressItem, rhs: DayProgressItem) -> Bool {
        Calendar.current.isDate(lhs.date, inSameDayAs: rhs.date) &&
        lhs.isSelected == rhs.isSelected &&
        abs(lhs.progress - rhs.progress) < 0.01 &&
        lhs.showProgressRing == rhs.showProgressRing &&
        lhs.habit?.id == rhs.habit?.id &&
        lhs.isOverallProgress == rhs.isOverallProgress
    }
}
