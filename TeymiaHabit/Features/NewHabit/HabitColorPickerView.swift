import SwiftUI

struct HabitColorPickerView: View {
    @Binding var selectedColor: HabitIconColor
    @Environment(AppColorManager.self) private var colorManager
    let iconName: String
    
    private var mockHabit: Habit {
        Habit(
            title: "",
            type: .count,
            goal: 7,
            iconName: iconName,
            iconColor: selectedColor,
            createdAt: Date()
        )
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            ColorPickerSection.forIconPicker(selectedColor: $selectedColor)
                .padding(.horizontal)
                .padding(.top, 30)
        }
        .safeAreaBar(edge: .top) {
            HStack(spacing: 40) {
                HabitIconView(
                    iconName: iconName,
                    iconColor: selectedColor,
                    size: 28
                )
                
                ProgressRing(
                    progress: 1.1,
                    currentValue: "7",
                    isCompleted: true,
                    isExceeded: true,
                    habit: mockHabit,
                    size: 50
                )
            }
            .padding(.top, 20)
        }
    }
}
