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
                
                Circle()
                    .fill(colorManager.selectedColor.color)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
                    .animation(.easeInOut(duration: 0.3), value: colorManager.selectedColor)
            }
        }
    }
}

struct AppColorPickerView: View {
    @ObservedObject private var colorManager = AppColorManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ProManager.self) private var proManager
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Main content
                Form {
                    Section {
                        // Realistic preview showing actual app elements
                        VStack(spacing: 20) {
                            appColorPreview
                        }
                        .padding(.vertical, 12)
                        
                    } header: {
                        Text("app_color_preview_header".localized)
                            .font(.headline)
                    } footer: {
                        Text("app_color_preview_footer".localized)
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
                        .fill(.ultraThinMaterial)
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
    
    // MARK: - Realistic Preview
    
    @ViewBuilder
    private var appColorPreview: some View {
        VStack(spacing: 20) {
            // 1. Floating Action Button (как в NewHabit)
            VStack(spacing: 8) {
                Text("Floating Action Button")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button {
                    // Preview button
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(
                                    colorManager.selectedColor.adaptiveGradient(
                                        for: colorScheme,
                                        lightOpacity: 0.9,
                                        darkOpacity: 1.0
                                    )
                                )
                                .shadow(
                                    color: colorScheme == .dark ? .clear : .black.opacity(0.15),
                                    radius: colorScheme == .dark ? 0 : 8,
                                    x: 0,
                                    y: colorScheme == .dark ? 0 : 4
                                )
                        )
                }
                .animation(.easeInOut(duration: 0.3), value: colorManager.selectedColor)
            }
            
            // 2. Beautiful Button (как в формах)
            VStack(spacing: 8) {
                Text("Action Button")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button {
                    // Preview button
                } label: {
                    HStack(spacing: 8) {
                        Text("Save Changes")
                        Image(systemName: "checkmark.circle.fill")
                    }
                }
                .beautifulButton(
                    habitColor: colorManager.selectedColor,
                    isEnabled: true,
                    style: .primary
                )
                .frame(maxWidth: 200) // Ограничиваем ширину для preview
            }
            
            // 3. Progress Indicators (как в календаре)
            VStack(spacing: 8) {
                Text("Progress Indicators")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { index in
                        Circle()
                            .fill(index < 4 ? colorManager.selectedColor.color : Color.secondary.opacity(0.2))
                            .frame(width: 12, height: 12)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: colorManager.selectedColor)
            }
            
            // 4. Navigation Link/Button (как в настройках)
            VStack(spacing: 8) {
                Text("Navigation Elements")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text("Example Setting")
                        .font(.body)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(colorManager.selectedColor.color)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.quaternary.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .animation(.easeInOut(duration: 0.3), value: colorManager.selectedColor)
            }
        }
    }
}
