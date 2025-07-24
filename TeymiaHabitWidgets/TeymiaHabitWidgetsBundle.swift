import WidgetKit
import SwiftUI

@main
struct TeymiaHabitWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // Home Screen виджеты
        HabitMiniWidget()
        HabitGridWidget()
    }
}
