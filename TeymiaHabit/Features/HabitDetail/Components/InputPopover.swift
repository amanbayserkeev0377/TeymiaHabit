import SwiftUI

struct BaseInputPopover<Content: View>: View {
    let habit: Habit
    let date: Date
    let showQuickActions: Bool
    let titleKey: LocalizedStringResource
    let isValid: Bool
    let onConfirm: () -> Void
    var onComplete: (() -> Void)? = nil
    var onReset: (() -> Void)? = nil
    
    @ViewBuilder var content: Content
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            if showQuickActions {
                headerView
            } else {
                Text(titleKey)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
            }
            
            content
            
            if showQuickActions {
                quickActionsRow
            } else {
                standardActionsRow
            }
        }
        .padding(16)
        .frame(width: 320)
    }
    
    private var headerView: some View {
        VStack(spacing: 4) {
            Text(date.formatted(date: .abbreviated, time: .omitted))
            
            HStack(spacing: 6) {
                Text(habit.formattedProgress(for: date))
                Text("|")
                Text(habit.formattedGoal)
            }
            .font(.headline)
        }
        .foregroundStyle(Color.primary.gradient)
    }
    
    private var quickActionsRow: some View {
        VStack(alignment: .leading, spacing: 15) {
            actionButton(label: "button_add", isEnabled: isValid, action: onConfirm)
                .disabled(!isValid)
            
            actionButton(label: "complete") {
                onComplete?()
            }
            
            actionButton(label: "button_reset") {
                onReset?()
            }
        }
        .padding(.horizontal, 12)
    }
    
    private var standardActionsRow: some View {
        HStack {
            Button {
                onConfirm()
                dismiss()
            } label: {
                Text("button_add")
                    .foregroundStyle(Color.primaryInverse)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .contentShape(Capsule())
            .glassEffect(.regular.tint(Color.primary).interactive(), in: .capsule)
            .disabled(!isValid)
            .animation(.smooth(duration: 0.2), value: isValid)
        }
        .padding(.horizontal, 12)
    }
    
    @ViewBuilder
    private func actionButton(
        label: LocalizedStringResource? = nil,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: { action(); dismiss() }) {
            HStack {
                if let label = label {
                    Text(label)
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(.primaryInverse)
        }
        .contentShape(Capsule())
        .glassEffect(.clear.tint(Color.primary).interactive(), in: .capsule)
        .disabled(!isEnabled)
        .animation(.smooth(duration: 0.2), value: isEnabled)
    }
}

// MARK: - Count Input Popover
struct CountInputPopover: View {
    let habit: Habit
    let date: Date
    var showQuickActions: Bool = false
    let onConfirm: (Int) -> Void
    var onComplete: (() -> Void)? = nil
    var onReset: (() -> Void)? = nil
    
    @State private var inputText: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        BaseInputPopover(
            habit: habit, date: date,
            showQuickActions: showQuickActions,
            titleKey: "add_count",
            isValid: (Int(inputText) ?? 0) > 0,
            onConfirm: { if let val = Int(inputText) { onConfirm(val) } },
            onComplete: onComplete,
            onReset: onReset
        ) {
            HStack {
                TextField("0", text: $inputText)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($isTextFieldFocused)
                    .frame(maxWidth: .infinity)
                
                if !inputText.isEmpty {
                    Button { inputText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .animation(.easeInOut(duration: 0.2), value: inputText.isEmpty)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { isTextFieldFocused = true }
        }
    }
}

// MARK: - Time Input Popover
struct TimeInputPopover: View {
    let habit: Habit
    let date: Date
    var showQuickActions: Bool = false
    let onConfirm: (Int, Int) -> Void
    var onComplete: (() -> Void)? = nil
    var onReset: (() -> Void)? = nil
    
    @State private var selectedTime: Date = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date()) ?? Date()

    var body: some View {
        BaseInputPopover(
            habit: habit, date: date,
            showQuickActions: showQuickActions,
            titleKey: "add_time",
            isValid: true,
            onConfirm: {
                let comps = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                onConfirm(comps.hour ?? 0, comps.minute ?? 0)
            },
            onComplete: onComplete,
            onReset: onReset
        ) {
            DatePicker("", selection: $selectedTime, displayedComponents: [.hourAndMinute])
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxHeight: 120)
                .padding(10)
        }
    }
}

struct CustomMenuView<Label: View, Content: View>: View {
    var isHapticEnabled: Bool = true
    var action: (() -> Void)? = nil
    @ViewBuilder var label: Label
    @ViewBuilder var content: Content
    
    @State private var haptics: Bool = false
    @State private var isExpanded: Bool = false
    @Namespace private var namespace
    
    var body: some View {
        Button {
            action?()
            if isHapticEnabled {
                haptics.toggle()
            }
            isExpanded.toggle()
        } label: {
            label
                .matchedTransitionSource(id: "MENUCONTENT", in: namespace)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isExpanded) {
            PopOverHelper {
                content
            }
#if !targetEnvironment(macCatalyst)
            .navigationTransition(.zoom(sourceID: "MENUCONTENT", in: namespace))
#endif
        }
        .sensoryFeedback(.selection, trigger: haptics)
    }
}

struct PopOverHelper<Content: View>: View {
    @ViewBuilder var content: Content
    @State private var isVisible: Bool = false
    
    var body: some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.95)
            .padding(.bottom, 10)
            .task {
                try? await Task.sleep(for: .seconds(0.05))
                withAnimation(.snappy(duration: 0.4, extraBounce: 0)) {
                    isVisible = true
                }
            }
            .fixedSize()
            .presentationCompactAdaptation(.popover)
            .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
