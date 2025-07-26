import SwiftUI

struct CreateHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTemplate: HabitTemplate?
    @State private var showingNewHabitView = false
    @State private var showingCustomHabit = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Background for entire screen
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Scrollable content
                    ScrollView {
                        VStack(spacing: 24) {
                            templatesGrid
                        }
                        .padding(.horizontal)
                        .padding(.top, 24)
                        .padding(.bottom, 100) // Space for bottom button
                    }
                }
                
                // Floating custom habit button
                customHabitButton
            }
            .navigationTitle("create_habit".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    XmarkView(action: {
                        dismiss()
                    })
                }
            }
        }
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingNewHabitView) {
            if let template = selectedTemplate {
                NewHabitView(template: template) {
                    // Callback to dismiss both views
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingCustomHabit) {
            NewHabitView {
                // Callback to dismiss both views
                dismiss()
            }
        }
    }
    
    // MARK: - Custom Habit Button
    private var customHabitButton: some View {
        VStack(spacing: 0) {
            // Button area
            Button {
                showingCustomHabit = true
            } label: {
                HStack(spacing: 8) {
                    Text("create_custom_habit".localized)
                    Image(systemName: "plus.circle.fill")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            AppColorManager.shared.selectedColor.adaptiveGradient(for: colorScheme).opacity(0.9)
                        )
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Templates Grid
    private var templatesGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            ForEach(HabitTemplate.allTemplates, id: \.id) { template in
                templateCard(template: template)
            }
        }
    }
    
    // MARK: - Template Card
    private func templateCard(template: HabitTemplate) -> some View {
        Button {
            selectedTemplate = template
            showingNewHabitView = true
        } label: {
            VStack(spacing: 12) {
                // Icon with colored background
                Image(systemName: template.icon)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(template.iconColor.adaptiveGradient(for: colorScheme))
                    .frame(width: 64, height: 64)
                    .background(
                        Circle()
                            .fill(template.iconColor.color.opacity(0.15))
                    )
                
                // Title
                Text(template.name.localized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(.primary)
                    .frame(height: 40)
                    .frame(maxWidth: .infinity)

            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        Color(.separator).opacity(0.5), lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - HabitTemplate Model
struct HabitTemplate: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let iconColor: HabitIconColor
    let habitType: HabitType
    let defaultGoal: Int
    
    static let allTemplates: [HabitTemplate] = [
        HabitTemplate(
            name: "reading".localized,
            icon: "book.fill",
            iconColor: .orange,
            habitType: .time,
            defaultGoal: 30
        ),
        HabitTemplate(
            name: "meditation".localized,
            icon: "figure.mind.and.body",
            iconColor: .bluePink,
            habitType: .time,
            defaultGoal: 20
        ),
        HabitTemplate(
            name: "drink_water".localized,
            icon: "waterbottle.fill",
            iconColor: .oceanBlue,
            habitType: .count,
            defaultGoal: 8
        ),
        HabitTemplate(
            name: "practice_yoga".localized,
            icon: "figure.yoga",
            iconColor: .pink,
            habitType: .time,
            defaultGoal: 30
        ),
        HabitTemplate(
            name: "running".localized,
            icon: "figure.run",
            iconColor: .green,
            habitType: .time,
            defaultGoal: 30
        ),
        HabitTemplate(
            name: "learn_language".localized,
            icon: "translate",
            iconColor: .gray,
            habitType: .time,
            defaultGoal: 30
        ),
        HabitTemplate(
            name: "focus".localized,
            icon: "brain.fill",
            iconColor: .coral,
            habitType: .time,
            defaultGoal: 60
        ),
        HabitTemplate(
            name: "cold_shower".localized,
            icon: "shower.fill",
            iconColor: .blue,
            habitType: .count,
            defaultGoal: 1
        ),
        HabitTemplate(
            name: "workout".localized,
            icon: "figure.strengthtraining.traditional",
            iconColor: .mint,
            habitType: .count,
            defaultGoal: 1
        ),
        HabitTemplate(
            name: "swimming".localized,
            icon: "figure.pool.swim",
            iconColor: .sky,
            habitType: .count,
            defaultGoal: 1
        ),
        HabitTemplate(
            name: "cycling".localized,
            icon: "figure.outdoor.cycle",
            iconColor: .antarctica,
            habitType: .count,
            defaultGoal: 1
        ),
        HabitTemplate(
            name: "take_vitamins".localized,
            icon: "pills.fill",
            iconColor: .purple,
            habitType: .count,
            defaultGoal: 1
        ),
        HabitTemplate(
            name: "eat_vegetables".localized,
            icon: "carrot.fill",
            iconColor: .yellowOrange,
            habitType: .count,
            defaultGoal: 1
        ),

        HabitTemplate(
            name: "practice_coding".localized,
            icon: "keyboard.fill",
            iconColor: .softLavender,
            habitType: .time,
            defaultGoal: 60
        ),
        HabitTemplate(
            name: "plan_my_day".localized,
            icon: "calendar.badge.clock",
            iconColor: .red,
            habitType: .count,
            defaultGoal: 1
        ),
        HabitTemplate(
            name: "journaling".localized,
            icon: "pencil.and.scribble",
            iconColor: .candy,
            habitType: .count,
            defaultGoal: 1
        ),
        HabitTemplate(
            name: "call_parents".localized,
            icon: "phone.fill",
            iconColor: .green,
            habitType: .count,
            defaultGoal: 1
        ),
        HabitTemplate(
            name: "play_piano".localized,
            icon: "pianokeys",
            iconColor: .primary,
            habitType: .time,
            defaultGoal: 30
        ),
        HabitTemplate(
            name: "wakeup_early".localized,
            icon: "sunrise.fill",
            iconColor: .yellow,
            habitType: .count,
            defaultGoal: 1
        ),
        HabitTemplate(
            name: "take_a_walk".localized,
            icon: "shoeprints.fill",
            iconColor: .brown,
            habitType: .count,
            defaultGoal: 1
        )
    ]
}
