import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportRowView: View {
    var body: some View {
        NavigationLink(destination: ExportView()) {
            Label(
                title: { Text("settings_export") },
                icon: { Image(systemName: "document.badge.arrow.up").iconStyle() }
            )
        }
    }
}

struct ExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ProManager.self) private var proManager
    
    @State private var exportService: ExportService?
    @State private var exportedData: Data?
    @State private var exportedFileName: String?
    @State private var showErrorAlert = false
    @State private var showShareSheet = false
    @State private var showProPaywall = false
    
    @Query(filter: #Predicate<Habit> { !$0.isArchived }, sort: \Habit.createdAt)
    private var activeHabits: [Habit]
    
    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    
                    Image("ui-file.export.fill")
                        .resizable()
                        .frame(width: 90, height: 90)
                        .foregroundStyle(Color.gray.gradient)
                    
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            
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
                                .foregroundStyle(Color.primary)
                            
                            Spacer()
                            
                            if format.requiresPro && !proManager.isPro {
                                ProLockBadge()
                            }
                        }
                    }
                }
            }
            .listRowBackground(Color.rowBackground)
        }
        .appBackground()
        .navigationTitle("settings_export")
        .onAppear { setupExportService() }
        .alert("export_error_title", isPresented: $showErrorAlert) {
            Button("button_ok") { }
        } message: {
            if let error = exportService?.exportError {
                Text(error.localizedDescription)
            }
        }.tint(Color.primary)
        .sheet(isPresented: $showShareSheet) {
            if let data = exportedData, let filename = exportedFileName {
                ActivityViewController(data: data, fileName: filename)
            }
        }
        .fullScreenCover(isPresented: $showProPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Methods
    
    private func setupExportService() {
        exportService = ExportService(modelContext: modelContext)
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

// MARK: Helpers

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
