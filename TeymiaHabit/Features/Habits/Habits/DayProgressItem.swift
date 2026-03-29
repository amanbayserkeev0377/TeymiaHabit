import SwiftUI

struct DayProgressItem: View, Equatable {
    let date: Date
    let isSelected: Bool
    let progress: Double
    var showProgressRing: Bool = true
    var habit: Habit? = nil
    var isOverallProgress: Bool = false
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
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
            return .appOrange
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
            VStack(spacing: 6) {
                ZStack {
                    if showProgressRing && !isFutureDate {
                        if let habit = habit {
                            ProgressRing(
                                progress: progress,
                                currentValue: "",
                                isCompleted: progress >= 1.0,
                                isExceeded: habit.isExceededForDate(date),
                                habit: habit,
                                size: circleSize,
                                lineWidth: lineWidth,
                                hideContent: true
                            )
                        } else if isOverallProgress {
                            overallProgressRing
                        }
                    }
                    
                    Text(dayNumber)
                        .font(.system(size: fontSize, weight: fontWeight))
                        .foregroundStyle(dayTextColor.gradient)
                }
                .frame(width: circleSize, height: circleSize)
                
                Circle()
                    .fill(isToday ? .appOrange : .primary)
                    .frame(width: 4, height: 4)
                    .opacity(isSelected ? 1 : 0)
            }
    }
    
    @ViewBuilder
    private var overallProgressRing: some View {
        let isCompleted = progress >= 1.0
        let ringColors: [Color] = isCompleted
        ? [Color(#colorLiteral(red: 0.6274385452, green: 0.8037135005, blue: 0.2274374366, alpha: 1)), Color(#colorLiteral(red: 0.1764799058, green: 0.7451224923, blue: 0.3647513092, alpha: 1)), Color(#colorLiteral(red: 0.1764799058, green: 0.7451224923, blue: 0.3647513092, alpha: 1)), Color(#colorLiteral(red: 0.6274385452, green: 0.8037135005, blue: 0.2274374366, alpha: 1))]
        : [Color(#colorLiteral(red: 0.9450980392, green: 0.6392156863, blue: 0.231372549, alpha: 1)), Color(#colorLiteral(red: 1, green: 0.3882352941, blue: 0.003921568627, alpha: 1)), Color(#colorLiteral(red: 1, green: 0.3882352941, blue: 0.003921568627, alpha: 1)), Color(#colorLiteral(red: 0.9450980392, green: 0.6392156863, blue: 0.231372549, alpha: 1))]
        
        ZStack {
            Circle()
                .stroke(Color(.systemGray6), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: ringColors,
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                        ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
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
