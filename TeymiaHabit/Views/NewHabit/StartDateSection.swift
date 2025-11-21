import SwiftUI

struct StartDateSection: View {
    @Binding var startDate: Date
    
    var body: some View {
        HStack {
            Label(
                title: { Text("start_date".localized) },
                icon: {
                    Image("calendar")
                        .resizable()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(Color.primary)
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
