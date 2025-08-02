import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportDataView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - State
    
    @State private var exportService: HabitExportService?
    @State private var selectedFormat: ExportFormat = .csv
    @State private var showErrorAlert = false
    @State private var exportedFileURL: URL?
    @State private var isExporting = false
    
    // MARK: - Data
    
    @Query(sort: \Habit.createdAt) private var allHabits: [Habit]
    
    private var activeHabits: [Habit] {
        allHabits.filter { !$0.isArchived }
    }
    
    private var isExportReady: Bool {
        !activeHabits.isEmpty && !isExporting
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                // Header Section with 3D Icon
                Section {
                    HStack {
                        Spacer()
                        
                        Image("3d_export_document")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 150)
                        
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                .listSectionSeparator(.hidden)
                
                // Format Selection Section
                formatSection
                
                // Export Button Section
                Section {
                    Button(action: performExportAndShare) {
                        buttonContent
                    }
                    .buttonStyle(.plain)
                    .disabled(!isExportReady)
                    .animation(.easeInOut(duration: 0.25), value: isExporting)
                    .padding(.horizontal, 20)
                    .background(
                        // Скрытый ShareLink, который активируется программно
                        ShareLink(item: exportedFileURL ?? URL(string: "about:blank")!) {
                            EmptyView()
                        }
                        .opacity(0)
                        .allowsHitTesting(false)
                        .onChange(of: exportedFileURL) { _, newValue in
                            if newValue != nil {
                                // Программно "нажимаем" на ShareLink
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    // Находим ShareLink и симулируем нажатие
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let window = windowScene.windows.first {
                                        
                                        // Создаем и показываем UIActivityViewController
                                        let activityVC = UIActivityViewController(
                                            activityItems: [newValue!],
                                            applicationActivities: nil
                                        )
                                        
                                        // Настройка для iPad
                                        if let popover = activityVC.popoverPresentationController {
                                            popover.sourceView = window
                                            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                                            popover.permittedArrowDirections = []
                                        }
                                        
                                        window.rootViewController?.present(activityVC, animated: true)
                                    }
                                    
                                    // Сбрасываем файл после показа
                                    exportedFileURL = nil
                                }
                            }
                        }
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            .navigationTitle("export_data".localized)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                setupExportService()
            }
            .alert("export_error_title".localized, isPresented: $showErrorAlert) {
                Button("ok".localized) { }
            } message: {
                if let error = exportService?.exportError {
                    Text(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var formatSection: some View {
        Section {
            ForEach(ExportFormat.allCases, id: \.self) { format in
                Button(action: {
                    selectedFormat = format
                    exportedFileURL = nil // Сбрасываем файл при смене формата
                }) {
                    HStack {
                        Image(systemName: "document.badge.arrow.up")
                            .foregroundStyle(format.iconGradient)
                            .frame(width: 30, height: 30)
                        
                        Text(format.displayName)
                            .font(.body)
                            .foregroundStyle(Color(UIColor.label))
                        
                        Spacer()
                        
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                            .withAppGradient()
                            .opacity(selectedFormat == format ? 1 : 0)
                            .animation(.easeInOut, value: selectedFormat == format)
                    }
                    .contentShape(Rectangle())
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private var buttonContent: some View {
        HStack(spacing: 8) {
            Text("export_button".localized)
            
            if isExporting {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "square.and.arrow.up")
            }
        }
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(isExportReady ? Color.white : Color.secondary)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    isExportReady
                    ? AnyShapeStyle(AppColorManager.shared.selectedColor.adaptiveGradient(for: colorScheme).opacity(0.9))
                    : AnyShapeStyle(LinearGradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                )
        )
    }
    
    private func setupExportService() {
        exportService = HabitExportService(modelContext: modelContext)
    }
    
    private func performExportAndShare() {
        guard let exportService = exportService else { return }
        
        // Обнуляем предыдущие данные
        exportedFileURL = nil
        isExporting = true
        
        Task {
            let result: ExportResult
            
            switch selectedFormat {
            case .csv:
                result = await exportService.exportToCSV(habits: activeHabits)
            case .json:
                result = await exportService.exportToJSON(habits: activeHabits)
            case .pdf:
                result = await exportService.exportToPDF(habits: activeHabits)
            }
            
            await MainActor.run {
                isExporting = false
                handleExportResult(result)
            }
        }
    }
    
    private func handleExportResult(_ result: ExportResult) {
        switch result {
        case .success(let content, let fileName, _):
            saveFileAndShare(content: content, fileName: fileName)
        case .failure:
            showErrorAlert = true
        }
    }
    
    private func saveFileAndShare(content: Data, fileName: String) {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try content.write(to: fileURL)
            exportedFileURL = fileURL
        } catch {
            showErrorAlert = true
        }
    }
}

// MARK: - Supporting Types

enum ExportFormat: CaseIterable {
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
    
    var displayName: String {
        switch self {
        case .csv: return "CSV"
        case .json: return "JSON"
        case .pdf: return "PDF"
        }
    }
    
    var iconGradient: LinearGradient {
        switch self {
        case .csv:
            return LinearGradient(
                colors: [
                    Color(#colorLiteral(red: 0.1960784314, green: 0.8431372549, blue: 0.2941176471, alpha: 1)),
                    Color(#colorLiteral(red: 0.1333333333, green: 0.5882352941, blue: 0.1333333333, alpha: 1))
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .json:
            return LinearGradient(
                colors: [
                    Color(#colorLiteral(red: 0.3411764706, green: 0.6235294118, blue: 1, alpha: 1)),
                    Color(#colorLiteral(red: 0.0, green: 0.3803921569, blue: 0.7647058824, alpha: 1))
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .pdf:
            return LinearGradient(
                colors: [
                    Color(#colorLiteral(red: 1, green: 0.4, blue: 0.4, alpha: 1)),
                    Color(#colorLiteral(red: 0.8, green: 0.2, blue: 0.2, alpha: 1))
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}
