import SwiftUI

struct DayProgressItem: View, Equatable {
    let date: Date
    let isSelected: Bool
    let progress: Double
    let onTap: () -> Void
    var showProgressRing: Bool = true
    var habit: Habit? = nil // ← НОВЫЙ ПАРАМЕТР
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private var calendar: Calendar {
        return Calendar.userPreferred
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
    
    // UPDATED: Use habit parameter for colors
    private var progressColors: [Color] {
        if progress > 0 {
            return AppColorManager.shared.getSmallRingColors(
                for: habit,
                isCompleted: progress >= 1.0,
                isExceeded: false
            )
        } else {
            // No progress - gray colors
            return [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]
        }
    }
    
    // Размеры для разных значений dynamic type
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
    
    // Цвет текста для дня
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
    
    // Вес шрифта
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
                // Круг прогресса и число
                ZStack {
                    if showProgressRing && !isFutureDate {
                        Circle()
                            .stroke(Color.secondary.opacity(0.15), lineWidth: lineWidth)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                AngularGradient(
                                    colors: progressColors,
                                    center: .center,
                                    startAngle: .degrees(0),
                                    endAngle: .degrees(360)
                                ),
                                style: StrokeStyle(
                                    lineWidth: lineWidth,
                                    lineCap: .round
                                )
                            )
                            .rotationEffect(.degrees(-90))
                    }
                    
                    // Число дня месяца
                    Text(dayNumber)
                        .font(.system(size: fontSize, weight: fontWeight))
                        .foregroundColor(dayTextColor)
                }
                .frame(width: circleSize, height: circleSize)
                
                // Индикатор выбранного дня (точка под числом)
                Circle()
                    .fill(isToday ? Color.orange : Color.primary)
                    .frame(width: 4, height: 4)
                    .opacity(isSelected ? 1 : 0)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isFutureDate || !isValidDate)
    }
    
    // UPDATED: Include habit in equality check
    static func == (lhs: DayProgressItem, rhs: DayProgressItem) -> Bool {
        return Calendar.current.isDate(lhs.date, inSameDayAs: rhs.date) &&
        lhs.isSelected == rhs.isSelected &&
        abs(lhs.progress - rhs.progress) < 0.01 &&
        lhs.showProgressRing == rhs.showProgressRing &&
        lhs.habit?.id == rhs.habit?.id // ← ДОБАВЛЯЕМ СРАВНЕНИЕ HABIT
    }
}
