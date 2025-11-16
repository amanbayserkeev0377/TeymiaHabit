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
            .listRowBackground(Color.mainRowBackground)
            
            // Flaticon link
            Button {
                if let url = URL(string: "https://www.flaticon.com") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("flaticon.com")
                    .foregroundStyle(.primary)
            }
            .listRowBackground(Color.mainRowBackground)
        }
        .scrollContentBackground(.hidden)
        .background(Color.mainGroupBackground)
        .navigationTitle("licenses_section_attributions".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}
