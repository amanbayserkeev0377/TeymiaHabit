import SwiftUI
import UIKit

extension UIKeyboardType {
    static let emoji: UIKeyboardType = UIKeyboardType(rawValue: 124)!
}

struct IconSection: View {
    @Binding var selectedIcon: String?
    @Binding var selectedColor: HabitIconColor
    
    let onShowFullPicker: () -> Void

    @FocusState private var isEmojiPickerFocused: Bool

    private let sectionIcons: [String] = [
        "dice", "book", "glass", "footprint", "running", "meditation", "cycling",
        "drawer.alt", "carrot", "pills", "shower", "sleeping",  "gym2", "pray",
        "sun", "calendar", "journal", "target", "toothbrush",
    ]
    
    private let itemSpacing: CGFloat = 8
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let itemSize: CGFloat = 40
    
    private var oneCharBinding: Binding<String> {
        Binding(
            get: {
                if let icon = selectedIcon, icon.count == 1 && !sectionIcons.contains(icon) {
                    return icon
                }
                return ""
            },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let lastChar = trimmed.last {
                    selectedIcon = String(lastChar)
                } else if trimmed.isEmpty {
                    selectedIcon = nil
                }
            }
        )
    }
    
    private var iconNamesToShow: [String] {
        sectionIcons.first == "dice" ? Array(sectionIcons.dropFirst()) : sectionIcons
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: itemSpacing) {
            emojiPickerButton

            ForEach(iconNamesToShow, id: \.self) { iconName in
                iconButton(for: iconName)
            }
            
            moreIconsButton
        }
    }
    
    // MARK: - Emoji Picker Button
    
    private var emojiPickerButton: some View {
        let isSelected = selectedIcon?.count == 1 && !sectionIcons.contains(selectedIcon ?? "")

        return ZStack {
            Circle()
                .fill(.secondary.opacity(0.07))
            
            Group {
                if let icon = selectedIcon, icon.count == 1 && !sectionIcons.contains(icon) {
                    Text(icon)
                        .font(.system(size: itemSize * 0.55))
                } else {
                    Image("emoji")
                        .resizable()
                        .frame(width: itemSize * 0.55, height: itemSize * 0.55)
                        .foregroundStyle(Color.main)
                    
                }
            }
            
            TextField("", text: oneCharBinding, axis: .horizontal)
                .focused($isEmojiPickerFocused)
                .keyboardType(.emoji)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .opacity(0.001)
        }
        .frame(width: itemSize, height: itemSize)
        .overlay(
            Circle()
                .strokeBorder(Color.secondary.opacity(0.6), lineWidth: 2)
                .frame(width: itemSize, height: itemSize)
                .opacity(isSelected ? 1 : 0)
        )
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .contentShape(Circle())
        .onTapGesture {
            isEmojiPickerFocused = true
            if !isSelected {
                 selectedIcon = ""
            }
        }
    }

    // MARK: - Icon Button
    
    private func iconButton(for iconName: String) -> some View {
        let isSelected = selectedIcon == iconName
        
        return Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedIcon = iconName
            }
            isEmojiPickerFocused = false
            HapticManager.shared.playSelection()

        } label: {
            ZStack {
                Circle()
                    .fill(.secondary.opacity(0.07))
                
                Image(iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: itemSize * 0.55, height: itemSize * 0.55)
                    .foregroundStyle(.primary)
            }
            .frame(width: itemSize, height: itemSize)
            .overlay(
                Circle()
                    .strokeBorder(Color.secondary.opacity(0.6), lineWidth: 2)
                    .frame(width: itemSize, height: itemSize)
                    .opacity(isSelected ? 1 : 0)
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    // MARK: - More Icons Button

    private var moreIconsButton: some View {
        Button {
            onShowFullPicker()
            isEmojiPickerFocused = false
            HapticManager.shared.playSelection()
        } label: {
            Image("ellipsis.circle.fill")
                .resizable()
                .frame(width: itemSize * 0.8, height: itemSize * 0.8)
                .frame(width: itemSize, height: itemSize)
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.primary.opacity(0.8))
        }
        .buttonStyle(.plain)
    }
}
