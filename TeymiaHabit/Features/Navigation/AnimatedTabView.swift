import SwiftUI

protocol AnimatedTabSelectionProtocol: CaseIterable, Hashable {
    var title: LocalizedStringResource { get }
    var symbolImage: String { get }
}

struct AnimatedTabView<Selection: AnimatedTabSelectionProtocol, Content: TabContent<Selection>>: View {
    @Binding var selection: Selection
    @TabContentBuilder<Selection> var content: () -> Content
    @State private var imageViews: [Selection: UIImageView] = [:]
    
    var effects: (Selection) -> [any DiscreteSymbolEffect & SymbolEffect]
    
    var body: some View {
        TabView(selection: $selection) {
            content()
        }
        .tabViewStyle(.tabBarOnly)
        .background(ExtractImageViewsFromTabView {
            imageViews = $0
        })
        .compositingGroup()
        .onChange(of: selection) { _, newValue in
            let symbolEffects = effects(newValue)
            guard let imageView = imageViews[newValue] else { return }
            
            for effect in symbolEffects {
                imageView.addSymbolEffect(effect, options: .nonRepeating)
            }
        }
    }
}

private struct ExtractImageViewsFromTabView<Value: AnimatedTabSelectionProtocol>: UIViewRepresentable {
    var result: ([Value: UIImageView]) -> Void
    
    func makeUIView(context: Context) -> some UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        
        DispatchQueue.main.async {
            if let compostingGroup = view.superview?.superview {
                guard let tabHostingController = compostingGroup.subviews.last else { return }
                guard let tabController = tabHostingController.subviews.first?.next as? UITabBarController else { return }
                
                extractImageViews(tabController.tabBar)
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    
    private func extractImageViews(_ tabBar: UITabBar) {
        let imageViews = tabBar.subviews(type: UIImageView.self)
            .filter({ $0.image?.isSymbolImage ?? false })
            .filter({ ($0.tintColor == tabBar.tintColor) })
        
        var dict: [Value: UIImageView] = [:]
        
        for tab in Value.allCases {
            if let imageView = imageViews.first(where: {
                $0.description.contains(tab.symbolImage)
            }) {
                dict[tab] = imageView
            }
        }
        
        result(dict)
    }
}

fileprivate extension UIView {
    func subviews<T: UIView>(type: T.Type) -> [T] {
        subviews.compactMap { $0 as? T } +
        subviews.flatMap { $0.subviews(type: type) }
    }
}
