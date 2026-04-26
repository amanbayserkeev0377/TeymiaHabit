import SwiftUI

struct DayProgressPopover: View {
    let habit: Habit
    let date: Date
    
    @Environment(HabitService.self) private var habitService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var inputText: String = ""
    @State private var selectedTime: Date = Calendar.current.date(
        bySettingHour: 0, minute: 0, second: 0, of: Date()
    ) ?? Date()
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 6) {
                    Text(habit.formattedProgress(for: date))
                    Text("|")
                    Text(habit.formattedGoal)
                }
                .font(.headline)
            }
            .padding(.top, 12)
            
            Divider()
            
            Group {
                if habit.type == .count {
                    TextField("0", text: $inputText)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .padding(.vertical, 8)
                } else {
                    DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxHeight: 120)
                }
            }
            .padding(.horizontal)
            
            actionButton("button_add") {
                addProgress()
            }
        }
        .frame(width: 280)
    }
    
    private func actionButton(_ label: LocalizedStringResource, action: @escaping () -> Void) -> some View {
        Button {
            action()
            dismiss()
        } label: {
            Text(label)
                .fontWeight(.medium)
                .foregroundStyle(Color(.systemBackground))
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .glassEffect(.clear.interactive().tint(.appPrimary), in: .capsule)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    
    private func addProgress() {
        if habit.type == .count {
            if let val = Int(inputText), val > 0 {
                habitService.addProgress(val, to: habit, date: date, context: modelContext)
            }
        } else {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
            let totalSeconds = (comps.hour ?? 0) * 3600 + (comps.minute ?? 0) * 60
            if totalSeconds > 0 {
                habitService.addProgress(totalSeconds, to: habit, date: date, context: modelContext)
            }
        }
    }
}
