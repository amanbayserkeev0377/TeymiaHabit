import SwiftUI

// MARK: - Count Input Popover
struct CountInputPopover: View {
    let habit: Habit
    let onConfirm: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var inputText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var isVisible: Bool = false
    
    private var isValidInput: Bool {
        guard let count = Int(inputText), count > 0 else { return false }
        return true
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("add_count".localized)
                .font(.headline)
                .fontDesign(.rounded) // Add this for consistency
                .foregroundStyle(.primary)
            
            HStack {
                TextField("0", text: $inputText)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($isTextFieldFocused)
                    .tint(habit.iconColor.color)
                    .frame(maxWidth: .infinity)
                
                if !inputText.isEmpty {
                    Button(action: {
                        inputText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 20))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .animation(.easeInOut(duration: 0.15), value: inputText.isEmpty)
            
            HStack(spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    Text("button_cancel".localized)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(habit.iconColor.color)
                        .frame(height: 40)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(habit.iconColor.color.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                
                Button {
                    guard let count = Int(inputText), count > 0 else { return }
                    onConfirm(count)
                    dismiss()
                } label: {
                    Text("button_add".localized)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(height: 40)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    isValidInput ?
                                    habit.iconColor.color.gradient :
                                    Color.gray.gradient
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(!isValidInput)
                .animation(.smooth(duration: 0.2), value: isValidInput)
            }
        }
        .padding(20)
        .frame(width: 280)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.95)
        .task {
            try? await Task.sleep(for: .seconds(0.05))
            withAnimation(.spring(duration: 0.25)) {
                isVisible = true
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isTextFieldFocused = true
            }
        }
        .presentationCompactAdaptation(.popover)
    }
}

// MARK: - Time Input Popover
struct TimeInputPopover: View {
    let habit: Habit
    let onConfirm: (Int, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var isVisible: Bool = false
    @State private var selectedTime: Date = {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date()) ?? Date()
    }()
    
    var body: some View {
        VStack(spacing: 16) {
            Text("add_time".localized)
                .font(.headline)
                .fontDesign(.rounded)
                .foregroundStyle(.primary)
            
            DatePicker(
                "Time",
                selection: $selectedTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxHeight: 140)
            
            HStack(spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    Text("button_cancel".localized)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(habit.iconColor.color)
                        .frame(height: 40)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(habit.iconColor.color.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                
                Button {
                    let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                    let hours = components.hour ?? 0
                    let minutes = components.minute ?? 0
                    onConfirm(hours, minutes)
                    dismiss()
                } label: {
                    Text("button_add".localized)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(height: 40)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(habit.iconColor.color.gradient)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(width: 280)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.95)
        .task {
            try? await Task.sleep(for: .seconds(0.05))
            withAnimation(.spring(duration: 0.25)) {
                isVisible = true
            }
        }
        .presentationCompactAdaptation(.popover)
    }
}
