import SwiftUI

struct AppColorSection: View {
    @ObservedObject private var colorManager = AppColorManager.shared
    @Environment(ProManager.self) private var proManager
    @State private var showingPaywall = false
    
    var body: some View {
        if proManager.isPro {
            // Pro users - normal navigation
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
        } else {
            // Free users - show Pro badge and paywall
            Button {
                showingPaywall = true
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
                    
                    ProLockBadge()
                }
            }
            .tint(.primary)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }
}

struct AppColorPickerView: View {
    @ObservedObject private var colorManager = AppColorManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var isToggleOn = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Main content in Form (scrollable)
                Form {
                    // MARK: - Ring Colors Section (moved to top)
                    Section {
                        VStack(spacing: 16) {
                            // Preview content that changes based on selection
                            Group {
                                switch colorManager.ringColorMode {
                                case .habitColors:
                                    habitColorPreviewContent
                                case .appColor:
                                    appColorPreviewContent
                                case .customGradient:
                                    customGradientPreviewContent
                                }
                            }
                            .frame(height: 140) // Fixed height to prevent jumping
                            .animation(.easeInOut(duration: 0.3), value: colorManager.ringColorMode)
                            
                            // Custom Gradient Color Pickers (only show when custom is selected)
                            if colorManager.ringColorMode == .customGradient {
                                VStack(spacing: 12) {
                                    ColorPicker(
                                        "Gradient Start",
                                        selection: $colorManager.customGradientColor1
                                    )
                                    .onChange(of: colorManager.customGradientColor1) { _, newColor in
                                        colorManager.setCustomGradientColors(
                                            color1: newColor,
                                            color2: colorManager.customGradientColor2
                                        )
                                    }
                                    
                                    ColorPicker(
                                        "Gradient End",
                                        selection: $colorManager.customGradientColor2
                                    )
                                    .onChange(of: colorManager.customGradientColor2) { _, newColor in
                                        colorManager.setCustomGradientColors(
                                            color1: colorManager.customGradientColor1,
                                            color2: newColor
                                        )
                                    }
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(.vertical, 8)
                        .animation(.easeInOut(duration: 0.3), value: colorManager.ringColorMode)
                        
                    } header: {
                        Text("Ring Colors")
                    } footer: {
                        Text("Choose which colors to use for progress rings. Completed habits are always shown in green.")
                    }
                    
                    // MARK: - App Color Preview Section
                    Section {
                        // Toggle preview
                        Toggle(isOn: $isToggleOn.animation(.easeInOut(duration: 0.3))) {
                            Label("reminders".localized, systemImage: "bell.badge")
                                .symbolEffect(.bounce, options: .repeat(1), value: isToggleOn)
                        }
                        .withToggleColor()
                        .animation(.easeInOut(duration: 0.5), value: colorManager.selectedColor.color)
                        
                        // Icons preview
                        HStack(spacing: 24) {
                            ForEach(["trophy", "calendar.badge.clock", "cloud.sun", "folder"], id: \.self) { iconName in
                                Image(systemName: iconName)
                                    .font(.title2)
                                    .foregroundStyle(colorManager.selectedColor.color)
                                    .animation(.easeInOut(duration: 0.5), value: colorManager.selectedColor.color)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, 12)
                        
                        // Complete button preview
                        Button(action: {}) {
                            Text("complete".localized)
                                .font(.headline)
                                .foregroundStyle(
                                    colorScheme == .dark ? .black : .white
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    colorManager.selectedColor.color.opacity(0.8),
                                    in: RoundedRectangle(cornerRadius: 16)
                                )
                                .animation(.easeInOut(duration: 0.5), value: colorManager.selectedColor.color)
                        }
                        .listRowInsets(EdgeInsets())
                        .padding()
                    } header: {
                        Text("app_color_preview_header".localized)
                    } footer: {
                        Text("app_color_preview_footer".localized)
                    }
                    
                    // MARK: - Ring Color Mode Selection (native list buttons)
                    Section {
                        // Habit Color Option
                        Button {
                            colorManager.setRingColorMode(.habitColors)
                        } label: {
                            HStack {
                                Text("Habit Color")
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if colorManager.ringColorMode == .habitColors {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(colorManager.selectedColor.color)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        // App Color Option  
                        Button {
                            colorManager.setRingColorMode(.appColor)
                        } label: {
                            HStack {
                                Text("App Color")
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if colorManager.ringColorMode == .appColor {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(colorManager.selectedColor.color)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        // Custom Gradient Option
                        Button {
                            colorManager.setRingColorMode(.customGradient)
                        } label: {
                            HStack {
                                Text("Custom Gradient")
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if colorManager.ringColorMode == .customGradient {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(colorManager.selectedColor.color)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                
                // Color picker section at the bottom (pinned, like IconPickerView)
                VStack(spacing: 16) {
                    ColorPickerSection.forAppColorPicker(selectedColor: Binding(
                        get: { colorManager.selectedColor },
                        set: { colorManager.setAppColor($0) }
                    ))
                }
                .padding()
                .padding(.horizontal)
                .background(Color(UIColor.systemGroupedBackground))
            }
            .navigationTitle("app_color".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Preview Content (for fixed preview area)
    
    @ViewBuilder
    private var habitColorPreviewContent: some View {
        // Mock habit rows with different colors (compact version)
        VStack(spacing: 6) {
            mockHabitRow(title: "Drink Water", icon: "drop.fill", color: .blue, progress: 0.6)
            mockHabitRow(title: "Exercise", icon: "figure.run", color: .orange, progress: 0.8)
            mockHabitRow(title: "Read Book", icon: "book.fill", color: .purple, progress: 0.4)
        }
    }
    
    @ViewBuilder
    private var appColorPreviewContent: some View {
        VStack {
            Spacer()
            ProgressRing(
                progress: 0.65,
                currentValue: "65%",
                isCompleted: false,
                isExceeded: false,
                habit: nil, // nil = uses app color
                size: 100 // Increased size to match habit preview height
            )
            .animation(.easeInOut(duration: 0.5), value: colorManager.selectedColor)
            .animation(.easeInOut(duration: 0.5), value: colorManager.ringColorMode)
            Spacer()
        }
    }
    
    @ViewBuilder
    private var customGradientPreviewContent: some View {
        VStack {
            Spacer()
            ProgressRing(
                progress: 0.65,
                currentValue: "65%",
                isCompleted: false,
                isExceeded: false,
                habit: nil, // nil = uses custom gradient
                size: 100 // Increased size to match habit preview height
            )
            .animation(.easeInOut(duration: 0.3), value: colorManager.customGradientColor1)
            .animation(.easeInOut(duration: 0.3), value: colorManager.customGradientColor2)
            Spacer()
        }
    }
    
    // MARK: - Mock Habit Row Helper
    
    @ViewBuilder
    private func mockHabitRow(title: String, icon: String, color: HabitIconColor, progress: Double) -> some View {
        HStack(spacing: 12) {
            // Mock habit icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color.color)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(color.color.opacity(0.1))
                )
            
            // Habit title and goal
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("Goal: 8 times")
                    .font(.footnote)
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
                size: 40
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Mock Habit Helper
    
    private func mockHabitWithColor(_ color: HabitIconColor) -> Habit? {
        // Create a simple mock habit for preview
        // You might need to adjust this based on your Habit model
        return nil // For now, we'll rely on the fact that nil uses app settings
        
        // If you want to create a proper mock habit:
        /*
        let mockHabit = Habit(
            title: "Mock",
            type: .count,
            goal: 8,
            iconName: "circle.fill",
            iconColor: color
        )
        return mockHabit
        */
    }
}
