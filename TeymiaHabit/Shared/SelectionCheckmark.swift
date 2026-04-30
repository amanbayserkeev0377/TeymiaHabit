import SwiftUI

struct SelectionCheckmark: View {
    var body: some View {
        Image(systemName: "checkmark")
            .fontWeight(.semibold)
            .transition(.symbolEffect(.drawOn))
    }
}
