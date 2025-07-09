import SwiftUI

struct CountInputView: View {
    let habit: Habit
    @Binding var isPresented: Bool
    let onConfirm: (Int) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var inputText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    private var isValidInput: Bool {
        guard let count = Int(inputText), count > 0 else { return false }
        return true
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("add_count".localized)
                .font(.headline)
                .foregroundStyle(.primary)
            
            // Input field
            HStack {
                TextField("".localized, text: $inputText)
                    .font(.system(size: 24, weight: .medium))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($isTextFieldFocused)
                
                if !inputText.isEmpty {
                    Button(action: {
                        inputText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(habit.iconColor.color)
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)
            .animation(.easeInOut(duration: 0.15), value: inputText.isEmpty)
            
            // Buttons
            HStack(spacing: 12) {
                // Cancel button
                Button {
                    isPresented = false
                } label: {
                    Text("button_cancel".localized)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(habit.iconColor.color)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(habit.iconColor.color.opacity(0.1))
                        )
                }
                
                // Add button
                Button {
                    guard let count = Int(inputText), count > 0 else { return }
                    onConfirm(count)
                    isPresented = false
                } label: {
                    Text("button_add".localized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    isValidInput ?
                                    habit.iconColor.adaptiveGradient(for: colorScheme) :
                                        LinearGradient(colors: [Color.gray, Color.gray], startPoint: .leading, endPoint: .trailing)
                                )
                        )
                }
                .disabled(!isValidInput)
                .animation(.easeInOut(duration: 0.15), value: isValidInput)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color(.separator).opacity(0.6), lineWidth: 0.7)
                )
        )
        .padding(.horizontal, 32)
        .onAppear {
            isTextFieldFocused = true
        }
    }
}
