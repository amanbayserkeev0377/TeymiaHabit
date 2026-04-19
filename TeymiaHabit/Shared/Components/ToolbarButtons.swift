import SwiftUI

struct CloseToolbarButton: ToolbarContent {
    let dismiss: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(role: .close) {
                dismiss()
            } label: {
                #if os(iOS)
                Image(systemName: "xmark")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)
                #else
                Text("button_cancel")
                #endif
            }
        }
    }
}

struct ConfirmationToolbarButton: ToolbarContent {
    let action: () -> Void
    let isDisabled: Bool
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(role: .none) {
                action()
            } label: {
                #if os(iOS)
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
                #else
                Text("button_ok")
                #endif
            }
            .disabled(isDisabled)
        }
    }
}
