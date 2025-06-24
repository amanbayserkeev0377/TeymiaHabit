import SwiftUI

struct GoalSection: View {
    @Binding var selectedType: HabitType
    @Binding var countGoal: Int
    @Binding var hours: Int
    @Binding var minutes: Int
    @FocusState.Binding var isFocused: Bool
    
    @State private var countText: String = ""
    @State private var timeDate: Date = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: Date()) ?? Date()
    
    var body: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "trophy.fill")
                    .withIOSSettingsIcon(lightColors: [
                        Color(#colorLiteral(red: 0.3, green: 0.8, blue: 0.4, alpha: 1)), // Яркий зеленый
                        Color(#colorLiteral(red: 0.2, green: 0.6, blue: 0.3, alpha: 1))  // Темно-зеленый
                    ],
                    fontSize: 17
                    )
                    .symbolEffect(.bounce, options: .repeat(1), value: selectedType)
                Text("daily_goal".localized)
                
                Spacer()
                
                Picker("", selection: $selectedType.animation(.easeInOut(duration: 0.4))) {
                    Text("count".localized).tag(HabitType.count)
                    Text("time".localized).tag(HabitType.time)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 170)
            }
            
            // Компонент ввода в зависимости от типа
            if selectedType == .count {
                HStack(spacing: 12) {
                    Image(systemName: "number")
                        .withGradientIcon(
                            colors: [
                                Color(#colorLiteral(red: 0.3, green: 0.8, blue: 0.4, alpha: 1)),  // светлый зеленый
                                Color(#colorLiteral(red: 0.1, green: 0.5, blue: 0.2, alpha: 1))   // темный зеленый
                            ],
                            startPoint: .top,
                            endPoint: .bottom,
                            fontSize: 16
                        )
                    
                    TextField("goalsection_enter_count".localized, text: $countText)
                        .keyboardType(.numberPad)
                        .focused($isFocused)
                        .multilineTextAlignment(.leading)
                        .onChange(of: countText) { _, newValue in
                            if let number = Int(newValue), number > 0 {
                                countGoal = min(number, 999999)
                            }
                        }
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .withGradientIcon(
                            colors: [
                                Color(#colorLiteral(red: 0.3, green: 0.6, blue: 0.8, alpha: 1)),  // светлый синий
                                Color(#colorLiteral(red: 0.1, green: 0.3, blue: 0.6, alpha: 1))   // темный синий
                            ],
                            startPoint: .top,
                            endPoint: .bottom,
                            fontSize: 16
                        )
                    
                    Text("goalsection_choose_time".localized)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    DatePicker("", selection: $timeDate, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .onChange(of: timeDate) { _, _ in
                            updateHoursAndMinutesFromTimeDate()
                        }
                }
            }
        }
        .onAppear {
            initializeValues()
        }
        .onChange(of: selectedType) { _, newValue in
            resetFieldsForType(newValue)
        }
    }
    
    // Синхронизация между timeDate и часами/минутами
    private func updateHoursAndMinutesFromTimeDate() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: timeDate)
        hours = components.hour ?? 0
        minutes = components.minute ?? 0
    }
    
    private func updateTimeDateFromHoursAndMinutes() {
        timeDate = Calendar.current.date(bySettingHour: hours, minute: minutes, second: 0, of: Date()) ?? Date()
    }
    
    // Инициализация значений при появлении
    private func initializeValues() {
        if selectedType == .count {
            if countGoal <= 0 {
                countGoal = 1
            }
            countText = String(countGoal)
        } else {
            if hours == 0 && minutes == 0 {
                hours = 1
                minutes = 0
            }
        }
    }
    
    // Сброс полей при смене типа
    private func resetFieldsForType(_ type: HabitType) {
        if type == .count {
            if countGoal <= 0 {
                countGoal = 1
            }
            countText = String(countGoal)
        } else {
            if hours == 0 && minutes == 0 {
                hours = 1
                minutes = 0
            }
        }
    }
}
