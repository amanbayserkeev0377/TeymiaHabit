import SwiftUI

struct LicensesView: View {
    var body: some View {
        List {
            Section("licenses_section_attributions".localized) {
                LicenseRow(iconName: "3d_star_progradient", attribution: "Decoration PNGs by Vecteezy", url: "https://www.vecteezy.com/png/48386636-a-five-pointed-star-3d-icon-pink-purple-blue-isolated-on-a-transparent-background")
                
                 LicenseRow(iconName: "3d_cloud_progradient", attribution: "Cloud Icon PNGs by Vecteezy", url: "https://www.vecteezy.com/png/55445028-elegant-minimalistic-cloud-icon-for-nature-inspired-designs")
                
                LicenseRow(iconName: "CardInfo_completion_rate", attribution: "3d List PNGs by Vecteezy", url: "https://www.vecteezy.com/png/54716302-data-visualization-3d-growth-chart-business-analytics-progress-report-statistical-graph-financial-metrics-market-trends-data-analysis-performance-indicators-upward-trend-investment-growth")
                
                LicenseRow(iconName: "CardInfo_active_days", attribution: "3d Calendar PNGs by Vecteezy", url: "https://www.vecteezy.com/png/56565480-3d-green-checkmark-on-transparent-background")
                
                LicenseRow(iconName: "CardInfo_habits_done", attribution: "Icon PNGs by Vecteezy", url: "https://www.vecteezy.com/png/56565480-3d-green-checkmark-on-transparent-background")
                
                LicenseRow(iconName: "CardInfo_active_habits", attribution: "3d Chart PNGs by Vecteezy", url: "https://www.vecteezy.com/png/46893434-menu-icon-blue-and-yellow-cartoon-design-cut-out-stock-3d")
                
                LicenseRow(iconName: "3d_bar_chart", attribution: "3d Bar Graph PNGs by Vecteezy", url: "https://www.vecteezy.com/png/54585147-3d-bar-graph-data-visualization-growth-chart-progress-report-statistical-analysis-business-analytics-market-trends-financial-performance-data-analysis-information-graphics-data-representation")
                
                LicenseRow(iconName: "3d_line_chart", attribution: "Data Visualization PNGs by Vecteezy", url: "https://www.vecteezy.com/png/54716611-growth-chart-data-cube-visualization-of-progress")
                
                LicenseRow(iconName: "3d_fitness_girl", attribution: "3d Fitness PNGs by Vecteezy", url: "https://www.vecteezy.com/png/57571132-beautiful-artistic-woman-doing-pilates-on-mat-isolated-genuine")
                
                LicenseRow(iconName: "3d_fitness_girl2", attribution: "3d Fitness PNGs by Vecteezy", url: "https://www.vecteezy.com/png/57571111-elegant-traditional-woman-doing-pilates-mat-exercise-cutout-genuine")
                
                LicenseRow(iconName: "3d_fitness_girl3", attribution: "3d Fitness PNGs by Vecteezy", url: "https://www.vecteezy.com/png/57571098-impressive-artistic-woman-doing-pilates-mat-exercise-cutout-exclusive")
                
                LicenseRow(iconName: "3d_fitness_boy", attribution: "3d Fitness PNGs by Vecteezy", url: "https://www.vecteezy.com/png/57444508-wonderful-abstract-man-doing-push-ups-side-view-transparent-background-high-resolution")
                
                LicenseRow(iconName: "3d_fitness_boy1", attribution: "3d Fitness PNGs by Vecteezy", url: "https://www.vecteezy.com/png/57444477-extraordinary-artistic-man-doing-pull-ups-front-view-isolated-cutout-4k")
            }
        }
        .navigationTitle("licenses".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LicenseRow: View {
    let iconName: String
    let attribution: String
    let url: String
    let iconSize: CGFloat  // ✅ Гибкий размер иконки
    
    // ✅ Инициализатор с размером по умолчанию
    init(iconName: String, attribution: String, url: String, iconSize: CGFloat = 36) {
        self.iconName = iconName
        self.attribution = attribution
        self.url = url
        self.iconSize = iconSize
    }
    
    var body: some View {
        Button {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 12) {
                // ✅ ГИБКИЙ РАЗМЕР ИКОНКИ
                Image(iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                
                // Attribution text
                Text(attribution)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .withExternalLinkIcon()
        }
        .tint(.primary)
    }
    // ✅ Вычисляемое скругление пропорционально размеру
    private var cornerRadius: CGFloat {
        switch iconSize {
        case ...30: return 6
        case 31...40: return 8
        case 41...48: return 10
        default: return 12
        }
    }
}
