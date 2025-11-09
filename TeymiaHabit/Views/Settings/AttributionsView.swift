import SwiftUI

struct AttributionsView: View {
    var body: some View {
        List {
            // Vecteezy link
            Button {
                if let url = URL(string: "https://www.vecteezy.com") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("vecteezy.com")
                    .foregroundStyle(.primary)
            }
            
            // Flaticon link
            Button {
                if let url = URL(string: "https://www.flaticon.com") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("flaticon.com")
                    .foregroundStyle(.primary)
            }
        }
        .navigationTitle("licenses_section_attributions".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}
