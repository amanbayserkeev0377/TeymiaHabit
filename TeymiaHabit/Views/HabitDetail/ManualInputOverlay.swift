import SwiftUI

// MARK: - Input Type

enum InputOverlayType {
    case count
    case time
    case none
}

// MARK: - Input Overlay Manager

@Observable
class InputOverlayManager {
    var activeInputType: InputOverlayType = .none
    
    func showCountInput() {
        activeInputType = .count
    }
    
    func showTimeInput() {
        activeInputType = .time
    }
    
    func dismiss() {
        activeInputType = .none
    }
    
    var isActive: Bool {
        activeInputType != .none
    }
}

// MARK: - Input Overlay Modifier

struct InputOverlayModifier: ViewModifier {
    let habit: Habit
    let inputType: InputOverlayType
    let onCountInput: (Int) -> Void
    let onTimeInput: (Int, Int) -> Void
    let onDismiss: () -> Void
    
    private enum AnimationConstants {
        static let duration: Double = 0.25
        static let scale: Double = 0.95
    }
    
    func body(content: Content) -> some View {
        content
            .overlay {
                overlayContent
                    .animation(.easeInOut(duration: AnimationConstants.duration), value: inputType)
                    .transition(.opacity.combined(with: .scale(scale: AnimationConstants.scale)))
            }
    }
    
    @ViewBuilder
    private var overlayContent: some View {
        switch inputType {
        case .count:
            countInputOverlay
        case .time:
            timeInputOverlay
        case .none:
            EmptyView()
        }
    }
    
    private var countInputOverlay: some View {
        ZStack {
            backgroundDismissalArea
            
            CountInputView(
                habit: habit,
                isPresented: Binding(
                    get: { true },
                    set: { _ in onDismiss() }
                ),
                onConfirm: { count in
                    onCountInput(count)
                }
            )
        }
    }
    
    private var timeInputOverlay: some View {
        ZStack {
            backgroundDismissalArea
            
            TimeInputView(
                habit: habit,
                isPresented: Binding(
                    get: { true },
                    set: { _ in onDismiss() }
                ),
                onConfirm: { hours, minutes in
                    onTimeInput(hours, minutes)
                }
            )
        }
    }
    
    private var backgroundDismissalArea: some View {
        Color.clear
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                onDismiss()
            }
    }
}

// MARK: - View Extension

extension View {
    /// Adds manual input overlay capability to any view
    func inputOverlay(
        habit: Habit,
        inputType: InputOverlayType,
        onCountInput: @escaping (Int) -> Void,
        onTimeInput: @escaping (Int, Int) -> Void,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(InputOverlayModifier(
            habit: habit,
            inputType: inputType,
            onCountInput: onCountInput,
            onTimeInput: onTimeInput,
            onDismiss: onDismiss
        ))
    }
}
