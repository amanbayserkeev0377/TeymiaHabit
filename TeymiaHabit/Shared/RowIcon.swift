import SwiftUI

struct RowIcon: View {
    let iconName: String
    
    var body: some View {
        Image(systemName: iconName)
            .font(DS.Typography.rowIcon)
            .foregroundStyle(DS.Colors.appPrimary)
    }
}
