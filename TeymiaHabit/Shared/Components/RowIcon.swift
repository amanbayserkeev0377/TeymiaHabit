import SwiftUI

struct RowIcon: View {
    let iconName: String
    
    var body: some View {
        Image(systemName: iconName)
            .font(.callout)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
    }
}
