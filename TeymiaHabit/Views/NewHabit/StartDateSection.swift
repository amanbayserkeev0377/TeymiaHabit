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
                        .frame(width: 20, height: 20)
                        .foregroundStyle(.gray.gradient)
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
