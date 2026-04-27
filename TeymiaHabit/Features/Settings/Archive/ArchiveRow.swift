import SwiftUI

struct ArchiveRow: View {
    var body: some View {
        NavigationLink(destination: ArchiveView()) {
            Label(
                title: { Text("settings_archived_habits") },
                icon: { RowIcon(iconName: "archivebox") }
            )
        }
    }
}
