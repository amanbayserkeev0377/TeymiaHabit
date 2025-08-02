import SwiftUI
import SwiftData
import PDFKit

// MARK: - Export Service

@Observable
final class HabitExportService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    // MARK: - Export State
    
    var isExporting = false
    var exportProgress: Double = 0.0
    var exportError: ExportError?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Export Methods
    
    @MainActor
    func exportToCSV(habits: [Habit]) async -> ExportResult {
        return await performExport(
            format: HabitExportFormat.csv,
            generator: { try await generateCSVContent(habits: habits) }
        )
    }
    
    @MainActor
    func exportToJSON(habits: [Habit]) async -> ExportResult {
        return await performExport(
            format: HabitExportFormat.json,
            generator: { try await generateJSONContent(habits: habits) }
        )
    }
    
    @MainActor
    func exportToPDF(habits: [Habit]) async -> ExportResult {
        return await performExport(
            format: HabitExportFormat.pdf,
            generator: { try await generatePDFContent(habits: habits) }
        )
    }
    
    // MARK: - CSV Generation
    
    private func generateCSVContent(habits: [Habit]) async throws -> Data {
        var csvLines = ["Date,Habit,Progress,Goal,Status"]
        let allRecords = collectAllRecords(from: habits)
        
        await updateProgress(0.5)
        
        let sortedRecords = allRecords.sorted { first, second in
            if first.date != second.date {
                return first.date > second.date
            }
            return first.habit.title < second.habit.title
        }
        
        await updateProgress(0.7)
        
        for record in sortedRecords {
            let line = formatCSVLine(habit: record.habit, completion: record.completion)
            csvLines.append(line)
        }
        
        await updateProgress(1.0)
        
        let csvString = csvLines.joined(separator: "\n")
        guard let csvData = csvString.data(using: .utf8) else {
            throw ExportError.dataConversionFailed
        }
        
        return csvData
    }
    
    private func formatCSVLine(habit: Habit, completion: HabitCompletion) -> String {
        let date = formatDateISO(completion.date)
        let habitName = escapeCSVField(habit.title)
        let (progressFormatted, goalFormatted) = formatProgressAndGoal(habit: habit, completion: completion)
        let status = completion.value >= habit.goal ? "Completed" : "In Progress"
        
        return "\(date),\(habitName),\(progressFormatted),\(goalFormatted),\(status)"
    }
    
    // MARK: - JSON Generation
    
    private func generateJSONContent(habits: [Habit]) async throws -> Data {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        
        let exportInfo = [
            "app_name": "Teymia Habit",
            "app_version": appVersion,
            "export_date": formatDateISO(Date()),
            "format": "json"
        ]
        
        var habitsData: [[String: Any]] = []
        
        for (index, habit) in habits.enumerated() {
            await updateProgress(Double(index) / Double(habits.count) * 0.8)
            
            let habitData = createHabitJSONData(habit: habit)
            habitsData.append(habitData)
        }
        
        let finalData: [String: Any] = [
            "export_info": exportInfo,
            "summary": [
                "total_habits": habits.count,
                "export_includes": "All habits with complete history"
            ],
            "habits": habitsData
        ]
        
        await updateProgress(1.0)
        
        return try JSONSerialization.data(withJSONObject: finalData, options: .prettyPrinted)
    }
    
    private func createHabitJSONData(habit: Habit) -> [String: Any] {
        var habitData: [String: Any] = [
            "title": habit.title,
            "type": habit.type == .count ? "count" : "time",
            "goal_formatted": habit.type == .time ? formatTimeForUser(habit.goal) : "\(habit.goal)",
            "created_date": formatDateISO(habit.createdAt)
        ]
        
        if let completions = habit.completions?.sorted(by: { $0.date > $1.date }) {
            let completionsData = completions.map { completion in
                createCompletionJSONData(habit: habit, completion: completion)
            }
            
            habitData["total_days"] = completions.count
            habitData["completed_days"] = completions.filter { $0.value >= habit.goal }.count
            habitData["history"] = completionsData
        } else {
            habitData["total_days"] = 0
            habitData["completed_days"] = 0
            habitData["history"] = []
        }
        
        return habitData
    }
    
    private func createCompletionJSONData(habit: Habit, completion: HabitCompletion) -> [String: Any] {
        var recordData: [String: Any] = [
            "date": formatDateISO(completion.date),
            "progress_formatted": habit.type == .time ? formatTimeForUser(completion.value) : "\(completion.value)",
            "goal_formatted": habit.type == .time ? formatTimeForUser(habit.goal) : "\(habit.goal)",
            "completed": completion.value >= habit.goal
        ]
        
        // Add raw numbers only for count type
        if habit.type == .count {
            recordData["progress"] = completion.value
            recordData["goal"] = habit.goal
        }
        
        return recordData
    }
    
    // MARK: - PDF Generation
    
    private func generatePDFContent(habits: [Habit]) async throws -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Teymia Habit",
            kCGPDFContextTitle: "Habits Progress Report"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 8.5 * 72.0, height: 11 * 72.0)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            createPDFContent(context: context, habits: habits, pageRect: pageRect)
        }
        
        await updateProgress(1.0)
        return data
    }
    
    private func createPDFContent(context: UIGraphicsPDFRendererContext, habits: [Habit], pageRect: CGRect) {
        context.beginPage()
        
        let margin: CGFloat = 50
        let contentWidth = pageRect.width - 2 * margin
        var yPosition: CGFloat = margin
        
        // Title section
        yPosition = drawPDFTitle(at: yPosition, margin: margin)
        
        // Statistics overview
        yPosition = drawPDFOverview(habits: habits, at: yPosition, margin: margin, contentWidth: contentWidth)
        
        // Habits section
        yPosition = drawPDFHabitsSection(habits: habits, context: context, at: yPosition, margin: margin, contentWidth: contentWidth, pageRect: pageRect)
        
        // Footer
        drawPDFFooter(at: pageRect.height - 60, margin: margin)
    }
    
    private func drawPDFTitle(at yPosition: CGFloat, margin: CGFloat) -> CGFloat {
        var currentY = yPosition
        
        let titleFont = UIFont.boldSystemFont(ofSize: 28)
        let title = "📊 Habits Progress Report"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.systemBlue
        ]
        let titleSize = title.size(withAttributes: titleAttributes)
        title.draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttributes)
        currentY += titleSize.height + 10
        
        let subtitle = "Generated by Teymia Habit"
        subtitle.draw(at: CGPoint(x: margin, y: currentY), withAttributes: [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.systemGray
        ])
        currentY += 30
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.locale = Locale(identifier: "en_US")
        let dateText = "Report Date: \(dateFormatter.string(from: Date()))"
        dateText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12)
        ])
        currentY += 25
        
        return currentY
    }
    
    private func drawPDFOverview(habits: [Habit], at yPosition: CGFloat, margin: CGFloat, contentWidth: CGFloat) -> CGFloat {
        let statsBoxHeight: CGFloat = 80
        let statsBoxRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: statsBoxHeight)
        
        UIColor.systemGray6.setFill()
        let path = UIBezierPath(roundedRect: statsBoxRect, cornerRadius: 8)
        path.fill()
        
        let (totalHabits, totalCompletions, totalDays) = calculateOverallStats(habits: habits)
        
        let statsY = yPosition + 15
        "📈 OVERVIEW".draw(at: CGPoint(x: margin + 15, y: statsY), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 16)
        ])
        
        let line1 = "Active Habits: \(totalHabits) • Total Days Tracked: \(totalDays) • Completed Goals: \(totalCompletions)"
        line1.draw(at: CGPoint(x: margin + 15, y: statsY + 25), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12)
        ])
        
        let completionRate = totalDays > 0 ? (Double(totalCompletions) / Double(totalDays) * 100) : 0
        let line2 = "Overall Success Rate: \(String(format: "%.1f", completionRate))%"
        line2.draw(at: CGPoint(x: margin + 15, y: statsY + 45), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12)
        ])
        
        return yPosition + statsBoxHeight + 30
    }
    
    private func drawPDFHabitsSection(habits: [Habit], context: UIGraphicsPDFRendererContext, at yPosition: CGFloat, margin: CGFloat, contentWidth: CGFloat, pageRect: CGRect) -> CGFloat {
        var currentY = yPosition
        
        "📋 Your Habits".draw(at: CGPoint(x: margin, y: currentY), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 18)
        ])
        currentY += 35
        
        for habit in habits {
            if currentY > pageRect.height - 180 {
                context.beginPage()
                currentY = margin
            }
            
            currentY = drawHabitCard(habit: habit, at: currentY, margin: margin, contentWidth: contentWidth)
        }
        
        return currentY
    }
    
    private func drawHabitCard(habit: Habit, at yPosition: CGFloat, margin: CGFloat, contentWidth: CGFloat) -> CGFloat {
        let cardHeight: CGFloat = 100
        let cardRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: cardHeight)
        
        UIColor.systemGray6.setFill()
        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 8)
        cardPath.fill()
        
        let habitIcon = habit.type == .time ? "⏱️" : "🔢"
        let habitTitle = "\(habitIcon) \(habit.title)"
        habitTitle.draw(at: CGPoint(x: margin + 15, y: yPosition + 15), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 16)
        ])
        
        let (completedDays, totalDaysForHabit, habitSuccessRate) = calculateHabitStats(habit: habit)
        
        let statsY = yPosition + 40
        let detailFont = UIFont.systemFont(ofSize: 12)
        
        "Goal: \(habit.formattedGoal)".draw(at: CGPoint(x: margin + 15, y: statsY), withAttributes: [.font: detailFont])
        "Days Tracked: \(totalDaysForHabit)".draw(at: CGPoint(x: margin + 150, y: statsY), withAttributes: [.font: detailFont])
        "Completed: \(completedDays)".draw(at: CGPoint(x: margin + 280, y: statsY), withAttributes: [.font: detailFont])
        "Success Rate: \(String(format: "%.1f", habitSuccessRate))%".draw(at: CGPoint(x: margin + 380, y: statsY), withAttributes: [.font: detailFont])
        
        drawProgressBar(successRate: habitSuccessRate, at: statsY + 25, margin: margin, contentWidth: contentWidth)
        
        return yPosition + cardHeight + 20
    }
    
    private func drawProgressBar(successRate: Double, at yPosition: CGFloat, margin: CGFloat, contentWidth: CGFloat) {
        let progressBarWidth: CGFloat = contentWidth - 30
        let progressBarHeight: CGFloat = 8
        let progressBarRect = CGRect(x: margin + 15, y: yPosition, width: progressBarWidth, height: progressBarHeight)
        
        UIColor.systemGray4.setFill()
        let progressBackground = UIBezierPath(roundedRect: progressBarRect, cornerRadius: 4)
        progressBackground.fill()
        
        let progressFillWidth = progressBarWidth * CGFloat(successRate / 100)
        let progressFillRect = CGRect(x: margin + 15, y: yPosition, width: progressFillWidth, height: progressBarHeight)
        
        UIColor.systemGreen.setFill()
        let progressFill = UIBezierPath(roundedRect: progressFillRect, cornerRadius: 4)
        progressFill.fill()
    }
    
    private func drawPDFFooter(at yPosition: CGFloat, margin: CGFloat) {
        "Generated by Teymia Habit • Keep building great habits! 🌟".draw(
            at: CGPoint(x: margin, y: yPosition),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.systemGray
            ]
        )
    }
    
    // MARK: - Helper Methods
    
    private func performExport(format: HabitExportFormat, generator: () async throws -> Data) async -> ExportResult {
        isExporting = true
        exportProgress = 0.0
        defer {
            isExporting = false
            exportProgress = 0.0
        }
        
        do {
            let content = try await generator()
            let fileName = generateFileName(format: format)
            
            return .success(
                content: content,
                fileName: fileName,
                mimeType: format.mimeType
            )
        } catch {
            let exportError = ExportError.from(error)
            self.exportError = exportError
            return .failure(exportError)
        }
    }
    
    private func collectAllRecords(from habits: [Habit]) -> [(date: Date, habit: Habit, completion: HabitCompletion)] {
        var allRecords: [(date: Date, habit: Habit, completion: HabitCompletion)] = []
        
        for habit in habits {
            guard let completions = habit.completions else { continue }
            
            for completion in completions {
                allRecords.append((date: completion.date, habit: habit, completion: completion))
            }
        }
        
        return allRecords
    }
    
    private func formatProgressAndGoal(habit: Habit, completion: HabitCompletion) -> (String, String) {
        if habit.type == .time {
            return (formatTimeForUser(completion.value), formatTimeForUser(habit.goal))
        } else {
            return ("\(completion.value)", "\(habit.goal)")
        }
    }
    
    private func calculateOverallStats(habits: [Habit]) -> (totalHabits: Int, totalCompletions: Int, totalDays: Int) {
        let totalHabits = habits.count
        let totalCompletions = habits.reduce(0) { total, habit in
            total + (habit.completions?.filter { $0.value >= habit.goal }.count ?? 0)
        }
        let totalDays = habits.reduce(0) { total, habit in
            total + (habit.completions?.count ?? 0)
        }
        
        return (totalHabits, totalCompletions, totalDays)
    }
    
    private func calculateHabitStats(habit: Habit) -> (completedDays: Int, totalDays: Int, successRate: Double) {
        let completions = habit.completions ?? []
        let completedDays = completions.filter { $0.value >= habit.goal }.count
        let totalDays = completions.count
        let successRate = totalDays > 0 ? (Double(completedDays) / Double(totalDays) * 100) : 0
        
        return (completedDays, totalDays, successRate)
    }
    
    private func updateProgress(_ progress: Double) async {
        await MainActor.run {
            exportProgress = progress
        }
    }
    
    private func formatTimeForUser(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else {
            return String(format: "0:%02d", minutes)
        }
    }
    
    private func formatDateISO(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
    
    private func generateFileName(format: HabitExportFormat) -> String {
        let dateString = formatDateISO(Date())
        return "TeymiaHabit-\(dateString).\(format.fileExtension)"
    }
}

// MARK: - Supporting Types

enum HabitExportFormat {
    case csv
    case json
    case pdf
    
    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        case .pdf: return "pdf"
        }
    }
    
    var mimeType: String {
        switch self {
        case .csv: return "text/csv"
        case .json: return "application/json"
        case .pdf: return "application/pdf"
        }
    }
}

enum ExportResult {
    case success(content: Data, fileName: String, mimeType: String)
    case failure(ExportError)
}

enum ExportError: LocalizedError {
    case noDataToExport
    case dataConversionFailed
    case fileCreationFailed
    case unknownError(Error)
    
    static func from(_ error: Error) -> ExportError {
        if let exportError = error as? ExportError {
            return exportError
        }
        return .unknownError(error)
    }
    
    var errorDescription: String? {
        switch self {
        case .noDataToExport:
            return "No data available for export"
        case .dataConversionFailed:
            return "Failed to convert data to export format"
        case .fileCreationFailed:
            return "Failed to create export file"
        case .unknownError(let error):
            return "Export failed: \(error.localizedDescription)"
        }
    }
}
