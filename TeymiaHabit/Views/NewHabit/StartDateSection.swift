import SwiftUI

struct StartDateSection: View {
    @Binding var startDate: Date
    
    var body: some View {
        HStack {
            Label(
                title: { Text("start_date".localized) },
                icon: {
                    Image(systemName: "calendar.badge.clock")
                        .withIOSSettingsIcon(lightColors: [
                            Color(#colorLiteral(red: 0.75, green: 0.65, blue: 0.55, alpha: 1)), // Коричневато-золотой
                            Color(#colorLiteral(red: 0.4, green: 0.35, blue: 0.3, alpha: 1))    // Темно-коричневый
                        ])
                }
            )
            
            Spacer()
            
            DatePicker(
                "",
                selection: $startDate,
                in: HistoryLimits.datePickerRange,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
        }
    }
}
