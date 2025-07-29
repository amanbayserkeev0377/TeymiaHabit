import SwiftUI

// MARK: - Input Type Enum

/// Types of manual input overlays available for habit progress entry
enum InputOverlayType {
    case count  // For count-based habits
    case time   // For time-based habits
    case none   // No overlay shown
}

// MARK: - Input Overlay Manager

/// Observable manager for controlling input overlay state
/// Used in ViewModels to manage overlay presentation
@Observable
class InputOverlayManager {
    var activeInputType: InputOverlayType = .none
    
    /// Shows count input overlay for count-based habits
    func showCountInput() {
        activeInputType = .count
    }
    
    /// Shows time input overlay for time-based habits
    func showTimeInput() {
        activeInputType = .time
    }
    
    /// Dismisses any active overlay
    func dismiss() {
        activeInputType = .none
    }
    
    /// Whether any overlay is currently active
    var isActive: Bool {
        activeInputType != .none
    }
}

// MARK: - Input Overlay Modifier

/// ViewModifier that adds manual input overlays to any view
/// Handles background dismissal and input type switching
struct InputOverlayModifier: ViewModifier {
    let habit: Habit
    let inputType: InputOverlayType
    let onCountInput: (Int) -> Void
    let onTimeInput: (Int, Int) -> Void
    let onDismiss: () -> Void
    
    // Animation constants
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
    
    /// Main overlay content that switches between input types
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
    
    /// Count input overlay with background dismissal
    private var countInputOverlay: some View {
        ZStack {
            // Background dismissal area
            backgroundDismissalArea
            
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
    }
    
    /// Time input overlay with background dismissal
    private var timeInputOverlay: some View {
        ZStack {
            // Background dismissal area
            backgroundDismissalArea
            
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
    }
    
    /// Transparent background that dismisses overlay when tapped
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
    ///
    /// Usage:
    /// ```swift
    /// someView
    ///     .inputOverlay(
    ///         habit: habit,
    ///         inputType: inputManager.activeInputType,
    ///         onCountInput: { count in ... },
    ///         onTimeInput: { hours, minutes in ... },
    ///         onDismiss: { inputManager.dismiss() }
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - habit: Habit being edited
    ///   - inputType: Type of input overlay to show
    ///   - onCountInput: Callback for count input confirmation
    ///   - onTimeInput: Callback for time input confirmation
    ///   - onDismiss: Callback for overlay dismissal
    /// - Returns: View with input overlay capability
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
