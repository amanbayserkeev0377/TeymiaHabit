import SwiftUI

struct BaseInputPopover<Content: View>: View {
    let habit: Habit
    let date: Date
    let showQuickActions: Bool
    let titleKey: String
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
        .foregroundStyle(Color.primary)
    }
    
    private var quickActionsRow: some View {
        VStack(spacing: 12) {
            actionButton(icon: "plus.circle.fill", label: "button_add", color: habit.iconColor.color, isFilled: true, isEnabled: isValid, action: onConfirm)
                .disabled(!isValid)
            actionButton(icon: "checkmark.circle.fill", label: "complete", color: habit.iconColor.color, isFilled: true) { onComplete?() }
            actionButton(icon: "arrow.counterclockwise.circle.fill", label: "button_reset", color: .red, isFilled: true) { onReset?() }
            actionButton(icon: "", label: "button_cancel", color: .red) { dismiss() }
        }
    }
    
    private var standardActionsRow: some View {
        HStack {
            Button {
                onConfirm()
                dismiss()
            } label: {
                Text("button_add")
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
            .contentShape(Capsule())
            .glassEffect(.regular.interactive(), in: .capsule)
            .disabled(!isValid)
            .animation(.smooth(duration: 0.2), value: isValid)
        }
    }
    
    @ViewBuilder
    private func actionButton(icon: String, label: String? = nil, color: Color, isFilled: Bool = false, isEnabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: { action(); dismiss() }) {
            HStack {
                if !icon.isEmpty {
                    Image(systemName: icon)
                }
                if let label = label {
                    Text(label)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(isFilled ? Color(.systemBackground) : color)
        }
        .contentShape(Capsule())
        .glassEffect(.regular.interactive(), in: .capsule)
        .disabled(!isEnabled)
        .animation(.smooth(duration: 0.2), value: isValid)
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
