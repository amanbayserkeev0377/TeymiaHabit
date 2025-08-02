import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportDataView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ProManager.self) private var proManager
    
    @State private var exportService: HabitExportService?
    @State private var selectedFormat: ExportFormat = .csv
    @State private var exportedData: Data?
    @State private var exportedFileName: String?
    @State private var showErrorAlert = false
    @State private var showShareSheet = false
    @State private var showProPaywall = false
    @State private var isExporting = false
    
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
                
                formatSection
            }
            .navigationTitle("export_data".localized)
            .navigationBarTitleDisplayMode(.inline)
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
            .overlay(alignment: .bottom) {
                exportButton
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
    
    private var formatSection: some View {
        Section {
            ForEach(ExportFormat.allCases, id: \.self) { format in
                Button(action: {
                    if format.requiresPro && !proManager.isPro {
                        showProPaywall = true
                        return
                    }
                    
                    selectedFormat = format
                    exportedData = nil
                    exportedFileName = nil
                }) {
                    HStack {
                        Image(systemName: format.iconName)
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
                        
                        if format.requiresPro && !proManager.isPro {
                            ProLockBadge()
                        }
                    }
                    .contentShape(Rectangle())
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private var exportButton: some View {
        Button(action: performExportAndShare) {
            buttonContent
        }
        .buttonStyle(.plain)
        .disabled(!isExportReady)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private var buttonContent: some View {
        HStack(spacing: 8) {
            Text("export_button".localized)
            
            if isExporting {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "arrow.up.circle.fill")
            }
        }
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(Color.white)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColorManager.shared.selectedColor.adaptiveGradient(for: colorScheme).opacity(0.9))
        )
    }
    
    private func setupExportService() {
        exportService = HabitExportService(modelContext: modelContext)
    }
    
    private func performExportAndShare() {
        guard let exportService = exportService else { return }
        
        exportedData = nil
        exportedFileName = nil
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
    
    var iconName: String {
        switch self {
        case .csv: return "tablecells"
        case .json: return "curlybraces"
        case .pdf: return "doc.richtext"
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
