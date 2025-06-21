import SwiftUI
import SwiftData

struct FolderSection: View {
    @Binding var selectedFolders: Set<HabitFolder>
    @Environment(ProManager.self) private var proManager
    @State private var showingPaywall = false
    
    var body: some View {
        if proManager.canUseFolders {
            // Pro users - normal folder selection
            NavigationLink {
                FolderManagementView(mode: .selection(binding: $selectedFolders))
            } label: {
                folderContent
            }
        } else {
            // Free users - show Pro badge and paywall
            Button {
                showingPaywall = true
            } label: {
                folderContentWithProBadge
            }
            .tint(.primary)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }
    
    // MARK: - Content Views
    
    private var folderContent: some View {
        HStack(spacing: 12) {
            // Используем Label с iOS Settings стилем
            Label(
                title: { Text("folders".localized) },
                icon: {
                    Image(systemName: "folder.fill")
                        .withIOSSettingsIcon(lightColors: [
                            Color(#colorLiteral(red: 0.4, green: 0.7843137255, blue: 1, alpha: 1)), // Голубой
                            Color(#colorLiteral(red: 0.0, green: 0.4784313725, blue: 0.8, alpha: 1))  // Синий
                        ])
                }
            )
            
            Spacer()
            
            // Показываем выбранные папки
            if selectedFolders.isEmpty {
                Text("folders_none_selected".localized)
                    .foregroundStyle(.secondary)
            } else {
                Text(selectedFolders.map { $0.name }.joined(separator: ", "))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
    private var folderContentWithProBadge: some View {
        HStack {
            // Тот же Label стиль для консистентности
            Label(
                title: { Text("folders".localized) },
                icon: {
                    Image(systemName: "folder.fill")
                        .withIOSSettingsIcon(lightColors: [
                            Color(#colorLiteral(red: 0.4, green: 0.7843137255, blue: 1, alpha: 1)),
                            Color(#colorLiteral(red: 0.0, green: 0.4784313725, blue: 0.8, alpha: 1))
                        ])
                }
            )
            
            Spacer()
            
            // Pro badge
            ProLockBadge()
        }
    }
}
