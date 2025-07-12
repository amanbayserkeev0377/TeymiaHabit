import SwiftUI

// MARK: - Input Type Enum
enum InputOverlayType {
    case count
    case time
    case none
}

// MARK: - Input Overlay Manager ViewModifier
struct InputOverlayModifier: ViewModifier {
    let habit: Habit
    let inputType: InputOverlayType
    let onCountInput: (Int) -> Void
    let onTimeInput: (Int, Int) -> Void
    let onDismiss: () -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay {
                // Single overlay with all input types
                Group {
                    switch inputType {
                    case .count:
                        ZStack {
                            Color.clear
                                .ignoresSafeArea()
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onDismiss()
                                }
                            
                            // Count input view
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
                        
                    case .time:
                        ZStack {
                            Color.clear
                                .ignoresSafeArea()
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onDismiss()
                                }
                            
                            // Time input view
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
                        
                    case .none:
                        EmptyView()
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: inputType)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
    }
}

// MARK: - View Extension
extension View {
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

// MARK: - Observable Input Manager (для ViewModel)
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
}
