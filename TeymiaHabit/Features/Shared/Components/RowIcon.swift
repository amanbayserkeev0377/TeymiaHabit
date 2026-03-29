import SwiftUI

struct RowIcon: View {
    let systemName: String
    
    var body: some View {
        Image(systemName: systemName)
            .font(.callout)
            .fontWeight(.medium)
            .foregroundStyle(.appPrimary)
    }
}
