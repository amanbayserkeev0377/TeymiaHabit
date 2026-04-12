import Foundation

// MARK: - Extensions

extension Int {
    func formattedAsTime() -> String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
        
    func formattedAsLocalizedDuration() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(self)) ?? "\(self)s"
    }
}

extension DateFormatter {
    static let nominativeMonthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()
    
    static func capitalizedNominativeMonthYear(from date: Date) -> String {
        let dateString = nominativeMonthYear.string(from: date)
        return dateString.capitalizingFirstLetter()
    }
}

private extension String {
    func capitalizingFirstLetter() -> String {
        guard let firstChar = self.first else { return self }
        return String(firstChar).uppercased() + self.dropFirst()
    }
}
