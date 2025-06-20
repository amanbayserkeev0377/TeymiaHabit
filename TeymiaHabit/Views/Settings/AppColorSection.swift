import SwiftUI

struct AppColorSection: View {
    @ObservedObject private var colorManager = AppColorManager.shared
    @Environment(ProManager.self) private var proManager
    
    var body: some View {
        // ✅ Теперь все пользователи могут зайти в AppColorPickerView
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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(ProManager.self) private var proManager
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Main content (Form)
                Form {
                    // MARK: - Ring Colors Section
                    Section {
                        VStack(spacing: 20) {
                            // Preview content that changes based on selection
                            Group {
                                switch colorManager.ringColorMode {
                                case .appColor:
                                    appColorPreviewContent
                                case .habitColors:
                                    habitColorPreviewContent
                                case .customGradient:
                                    customGradientPreviewContent
                                }
                            }
                            .frame(height: 160) // Fixed height to prevent jumping
                            .animation(.easeInOut(duration: 0.4), value: colorManager.ringColorMode)
                            
                            // Ring Color Mode Selection
                            ringColorModeSelector
                        }
                        .padding(.vertical, 12)
                        
                    } header: {
                        Text("Progress Ring Colors")
                            .font(.headline)
                    } footer: {
                        Text("Customize how progress rings appear in your app. Completed habits always show in green for clarity.")
                            .font(.footnote)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    // This creates space for the overlay
                    Color.clear.frame(height: 120)
                }
                
                // Overlay Color Picker Section (floating above)
                VStack(spacing: 16) {
                    // ✅ Используем новую версию ColorPickerSection с onProRequired
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
                        .fill(.regularMaterial) // Material для glassmorphism эффекта
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
    
    // MARK: - Ring Color Mode Selector
    
    @ViewBuilder
    private var ringColorModeSelector: some View {
        VStack(spacing: 12) {
            // ✅ App Theme - доступен всем пользователям
            Button {
                colorManager.setRingColorMode(.appColor)
                HapticManager.shared.playSelection()
            } label: {
                ringModeRow(
                    mode: .appColor,
                    title: "App Theme",
                    description: "Use your selected app color",
                    icon: "app",
                    isLocked: false
                )
            }
            .buttonStyle(.plain)
            
            // ✅ Habit Colors - Pro функция
            Button {
                if proManager.isPro {
                    colorManager.setRingColorMode(.habitColors)
                    HapticManager.shared.playSelection()
                } else {
                    showingPaywall = true
                }
            } label: {
                ringModeRow(
                    mode: .habitColors,
                    title: "Habit Colors",
                    description: "Each habit uses its own color",
                    icon: "paintbrush",
                    isLocked: !proManager.isPro
                )
            }
            .buttonStyle(.plain)
            
            // ✅ Custom Gradient - Pro функция
            Button {
                if proManager.isPro {
                    colorManager.setRingColorMode(.customGradient)
                    HapticManager.shared.playSelection()
                } else {
                    showingPaywall = true
                }
            } label: {
                ringModeRow(
                    mode: .customGradient,
                    title: "Custom Gradient",
                    description: "Create your own gradient",
                    icon: "rainbow",
                    isLocked: !proManager.isPro
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Ring Mode Row Helper
    
    @ViewBuilder
    private func ringModeRow(
        mode: RingColorMode,
        title: String,
        description: String,
        icon: String,
        isLocked: Bool
    ) -> some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(
                    isLocked ? .secondary.opacity(0.6) :
                    (colorManager.ringColorMode == mode ? colorManager.selectedColor.color : .secondary)
                )
                .frame(width: 24)
            
            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(isLocked ? .secondary : .primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Right side indicator
            if isLocked {
                ProLockBadge()
            } else if colorManager.ringColorMode == mode {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(colorManager.selectedColor.color)
                    .symbolEffect(.bounce, value: colorManager.ringColorMode == mode)
            } else {
                Image(systemName: "circle")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    isLocked ? Color.clear :
                    (colorManager.ringColorMode == mode ? colorManager.selectedColor.color.opacity(0.1) : Color.clear)
                )
        )
        .animation(.easeInOut(duration: 0.3), value: colorManager.ringColorMode)
    }
    
    // MARK: - Preview Content
    
    @ViewBuilder
    private var appColorPreviewContent: some View {
        VStack(spacing: 12) {
            Text("Uses your app theme color")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ProgressRing(
                progress: 0.65,
                currentValue: "65%",
                isCompleted: false,
                isExceeded: false,
                habit: nil, // nil = uses app color
                size: 100
            )
            .animation(.easeInOut(duration: 0.5), value: colorManager.selectedColor)
            .animation(.easeInOut(duration: 0.5), value: colorManager.ringColorMode)
        }
    }
    
    @ViewBuilder
    private var habitColorPreviewContent: some View {
        VStack(spacing: 8) {
            Text("Each habit uses its own color")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                mockHabitRow(title: "Drink Water", icon: "drop.fill", color: .blue, progress: 0.6)
                mockHabitRow(title: "Exercise", icon: "figure.run", color: .orange, progress: 0.8)
                mockHabitRow(title: "Read Book", icon: "book.fill", color: .purple, progress: 0.4)
            }
        }
    }
    
    @ViewBuilder
    private var customGradientPreviewContent: some View {
        HStack(spacing: 20) {
            // Start Color Picker (Left)
            VStack(spacing: 8) {
                Text("Start")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                ColorPicker("", selection: $colorManager.customGradientColor1)
                    .labelsHidden()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(.primary.opacity(0.2), lineWidth: 1)
                    )
                    .disabled(!proManager.isPro) // ✅ Отключаем для бесплатных пользователей
                    .onChange(of: colorManager.customGradientColor1) { _, newColor in
                        if proManager.isPro {
                            colorManager.setCustomGradientColors(
                                color1: newColor,
                                color2: colorManager.customGradientColor2
                            )
                            HapticManager.shared.playSelection()
                        }
                    }
            }
            
            // Progress Ring (Center)
            ProgressRing(
                progress: 0.65,
                currentValue: "65%",
                isCompleted: false,
                isExceeded: false,
                habit: nil, // nil = uses custom gradient
                size: 80
            )
            .animation(.easeInOut(duration: 0.3), value: colorManager.customGradientColor1)
            .animation(.easeInOut(duration: 0.3), value: colorManager.customGradientColor2)
            
            // End Color Picker (Right)
            VStack(spacing: 8) {
                Text("End")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                ColorPicker("", selection: $colorManager.customGradientColor2)
                    .labelsHidden()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(.primary.opacity(0.2), lineWidth: 1)
                    )
                    .disabled(!proManager.isPro) // ✅ Отключаем для бесплатных пользователей
                    .onChange(of: colorManager.customGradientColor2) { _, newColor in
                        if proManager.isPro {
                            colorManager.setCustomGradientColors(
                                color1: colorManager.customGradientColor1,
                                color2: newColor
                            )
                            HapticManager.shared.playSelection()
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Mock Habit Row Helper
    
    @ViewBuilder
    private func mockHabitRow(title: String, icon: String, color: HabitIconColor, progress: Double) -> some View {
        HStack(spacing: 12) {
            // Mock habit icon
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color.color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.color.opacity(0.15))
                )
            
            // Habit title and goal
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("Goal: 8 times")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Mock progress ring with habit color
            ProgressRing(
                progress: progress,
                currentValue: "\(Int(progress * 100))%",
                isCompleted: false,
                isExceeded: false,
                habit: mockHabitWithColor(color),
                size: 36
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
        )
    }
    
    // MARK: - Mock Habit Helper
    
    private func mockHabitWithColor(_ color: HabitIconColor) -> Habit? {
        // Create a simple mock habit for preview
        // You might need to adjust this based on your Habit model
        return nil // For now, we'll rely on the fact that nil uses app settings
    }
}
