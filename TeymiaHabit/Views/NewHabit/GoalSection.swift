import SwiftUI

struct GoalSection: View {
    @Binding var selectedType: HabitType
    @Binding var countGoal: Int
    @Binding var hours: Int
    @Binding var minutes: Int
    
    @State private var countText: String = ""
    @State private var timeDate: Date = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: Date()) ?? Date()
    
    var body: some View {
        Section {
            Label {
                HStack {
                    Text("daily_goal".localized)
                    
                    Spacer()
                    
                    Picker("", selection: $selectedType.animation(.easeInOut(duration: 0.4))) {
                        Text("count".localized).tag(HabitType.count)
                        Text("time".localized).tag(HabitType.time)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: 180)
                }
            } icon: {
                Image(systemName: "trophy.fill")
            }
            
            if selectedType == .count {
                Label {
                    HStack {
                        TextField("goalsection_enter_count".localized, text: $countText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.leading)
                            .fontDesign(.rounded)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Stepper(value: $countGoal, in: 1...999999) {}
                            .labelsHidden()
                    }
                } icon: {
                    Image(systemName: "number")
                        .foregroundStyle(.gray.gradient)
                        .frame(width: 20, height: 20)
                }
                .onChange(of: countText) { _, newValue in
                    if let number = Int(newValue), number > 0 {
                        countGoal = min(number, 999999)
                    } else if newValue.isEmpty {
                        countGoal = 1
                    }
                }
                .onChange(of: countGoal) { _, newValue in
                    if String(newValue) != countText {
                        countText = String(newValue)
                    }
                }
            } else {
                Label {
                    HStack {
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
                } icon : {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.gray.gradient)
                        .frame(width: 20, height: 20)
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
    
    // MARK: - Private Methods
    
    private func updateHoursAndMinutesFromTimeDate() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: timeDate)
        hours = components.hour ?? 0
        minutes = components.minute ?? 0
    }
    
    private func updateTimeDateFromHoursAndMinutes() {
        timeDate = Calendar.current.date(bySettingHour: hours, minute: minutes, second: 0, of: Date()) ?? Date()
    }
    
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
            updateTimeDateFromHoursAndMinutes()
        }
    }
    
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
            updateTimeDateFromHoursAndMinutes()
        }
    }
}
