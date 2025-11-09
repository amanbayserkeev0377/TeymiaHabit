import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportDataView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ProManager.self) private var proManager
    
    @State private var exportService: HabitExportService?
    @State private var exportedData: Data?
    @State private var exportedFileName: String?
    @State private var showErrorAlert = false
    @State private var showShareSheet = false
    @State private var showProPaywall = false
    
    @Query(sort: \Habit.createdAt) private var allHabits: [Habit]
    
    private var activeHabits: [Habit] {
        allHabits.filter { !$0.isArchived }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Spacer()
                        
                        Image("export.fill")
                            .resizable()
                            .frame(
                                width: UIScreen.main.bounds.width * 0.25,
                                height: UIScreen.main.bounds.width * 0.25
                            )
                            .foregroundStyle(.gray.gradient)
                        
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                .listSectionSeparator(.hidden)
                
                Section {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button(action: {
                            if format.requiresPro && !proManager.isPro {
                                showProPaywall = true
                                return
                            }
                            
                            HapticManager.shared.playSelection()
                            performExport(format: format)
                        }) {
                            HStack {
                                Text(format.displayName)
                                    .fontDesign(.rounded)
                                    .foregroundStyle(Color(UIColor.label))
                                
                                Spacer()
                                
                                if format.requiresPro && !proManager.isPro {
                                    ProLockBadge()
                                }
                            }
                            .contentShape(Rectangle())
                        }
                    }
                }
            }
            .navigationTitle("export_data".localized)
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                setupExportService()
            }
            .alert("export_error_title".localized, isPresented: $showErrorAlert) {
                Button("paywall_ok_button".localized) { }
            } message: {
                if let error = exportService?.exportError {
                    Text(error.localizedDescription)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let data = exportedData, let fileName = exportedFileName {
                    ActivityViewController(data: data, fileName: fileName)
                }
            }
            .sheet(isPresented: $showProPaywall) {
                PaywallView()
            }
        }
    }
    
    // MARK: - Methods
    
    private func setupExportService() {
        exportService = HabitExportService(modelContext: modelContext)
    }
    
    private func performExport(format: ExportFormat) {
        guard let exportService = exportService else { return }
        guard !activeHabits.isEmpty else { return }
        
        exportedData = nil
        exportedFileName = nil
        
        Task {
            let result: ExportResult
            
            switch format {
            case .csv:
                result = await exportService.exportToCSV(habits: activeHabits)
            case .json:
                result = await exportService.exportToJSON(habits: activeHabits)
            case .pdf:
                result = await exportService.exportToPDF(habits: activeHabits)
            }
            
            await MainActor.run {
                handleExportResult(result)
            }
        }
    }
    
    private func handleExportResult(_ result: ExportResult) {
        switch result {
        case .success(let content, let fileName, _):
            exportedData = content
            exportedFileName = fileName
            showShareSheet = true
        case .failure:
            showErrorAlert = true
        }
    }
}

// MARK: - Supporting Types

struct ActivityViewController: UIViewControllerRepresentable {
    let data: Data
    let fileName: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: tempURL)
        } catch {
            print("Failed to write temp file: \(error)")
        }
        
        let controller = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

enum ExportFormat: CaseIterable {
    case csv
    case json
    case pdf
    
    var requiresPro: Bool {
        switch self {
        case .csv: return false
        case .json: return true
        case .pdf: return true
        }
    }
    
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
}
