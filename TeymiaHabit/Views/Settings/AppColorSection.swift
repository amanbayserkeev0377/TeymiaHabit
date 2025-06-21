import SwiftUI

struct AppColorSection: View {
    @ObservedObject private var colorManager = AppColorManager.shared
    @Environment(ProManager.self) private var proManager
    
    var body: some View {
        NavigationLink {
            AppColorPickerView()
        } label: {
            HStack {
                Label(
                    title: { Text("app_color".localized) },
                    icon: {
                        Image(systemName: "paintbrush.pointed.fill")
                            .withIOSSettingsIcon(lightColors: [
                                Color(.purple),
                                Color(.pink)
                            ])
                    }
                )
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(colorManager.selectedColor.color)
                    .frame(width: 18, height: 18)
                    .animation(.easeInOut(duration: 0.3), value: colorManager.selectedColor)
            }
        }
    }
}

struct AppColorPickerView: View {
    @ObservedObject private var colorManager = AppColorManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(ProManager.self) private var proManager
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Main content
                Form {
                    Section {
                        // Simple preview showing app color usage
                        VStack(spacing: 16) {
                            appColorPreview
                        }
                        .padding(.vertical, 8)
                        
                    } header: {
                        Text("App Color")
                            .font(.headline)
                    } footer: {
                        Text("Choose the color for app interface elements like navigation, buttons, and progress indicators in calendar view.")
                            .font(.footnote)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    // Space for color picker overlay
                    Color.clear.frame(height: 120)
                }
                
                // Color picker overlay
                VStack(spacing: 16) {
                    ColorPickerSection.forAppColorPicker(
                        selectedColor: Binding(
                            get: { colorManager.selectedColor },
                            set: { colorManager.setAppColor($0) }
                        ),
                        onProRequired: {
                            showingPaywall = true
                        }
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.regularMaterial)
                        .shadow(color: .primary.opacity(0.2), radius: 20, x: 0, y: -10)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .navigationTitle("app_color".localized)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }
    
    // MARK: - Preview
    
    @ViewBuilder
    private var appColorPreview: some View {
        VStack(spacing: 12) {
            Text("Preview")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Sample UI elements using app color
            VStack(spacing: 8) {
                // Navigation bar sample
                HStack {
                    Text("Habits")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button {
                        // Preview button
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.quaternary.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Sample button
                Button {
                    // Preview button
                } label: {
                    Text("Save Changes")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(colorManager.selectedColor.color)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .animation(.easeInOut(duration: 0.3), value: colorManager.selectedColor)
                
                // Sample progress indicator (like calendar)
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { index in
                        Circle()
                            .fill(index < 4 ? colorManager.selectedColor.color : Color.secondary.opacity(0.2))
                            .frame(width: 12, height: 12)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: colorManager.selectedColor)
            }
        }
    }
}
