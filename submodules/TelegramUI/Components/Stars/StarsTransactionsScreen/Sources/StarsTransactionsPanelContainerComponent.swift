import Foundation
import UIKit
import Display
import ComponentFlow
import ComponentDisplayAdapters
import TelegramPresentationData

final class StarsTransactionsPanelContainerEnvironment: Equatable {
    let isScrollable: Bool
    
    init(
        isScrollable: Bool
    ) {
        self.isScrollable = isScrollable
    }

    static func ==(lhs: StarsTransactionsPanelContainerEnvironment, rhs: StarsTransactionsPanelContainerEnvironment) -> Bool {
        if lhs.isScrollable != rhs.isScrollable {
            return false
        }
        return true
    }
}

final class StarsTransactionsPanelEnvironment: Equatable {
    let theme: PresentationTheme
    let strings: PresentationStrings
    let dateTimeFormat: PresentationDateTimeFormat
    let containerInsets: UIEdgeInsets
    let isScrollable: Bool
    let isCurrent: Bool
    let externalScrollBounds: CGRect?
    let externalBottomOffset: CGFloat?
    
    init(
        theme: PresentationTheme,
        strings: PresentationStrings,
        dateTimeFormat: PresentationDateTimeFormat,
        containerInsets: UIEdgeInsets,
        isScrollable: Bool,
        isCurrent: Bool,
        externalScrollBounds: CGRect? = nil,
        externalBottomOffset: CGFloat? = nil
    ) {
        self.theme = theme
        self.strings = strings
        self.dateTimeFormat = dateTimeFormat
        self.containerInsets = containerInsets
        self.isScrollable = isScrollable
        self.isCurrent = isCurrent
        self.externalScrollBounds = externalScrollBounds
        self.externalBottomOffset = externalBottomOffset
    }

    static func ==(lhs: StarsTransactionsPanelEnvironment, rhs: StarsTransactionsPanelEnvironment) -> Bool {
        if lhs.theme !== rhs.theme {
            return false
        }
        if lhs.strings !== rhs.strings {
            return false
        }
        if lhs.dateTimeFormat != rhs.dateTimeFormat {
            return false
        }
        if lhs.containerInsets != rhs.containerInsets {
            return false
        }
        if lhs.isScrollable != rhs.isScrollable {
            return false
        }
        if lhs.isCurrent != rhs.isCurrent {
            return false
        }
        if lhs.externalScrollBounds != rhs.externalScrollBounds {
            return false
        }
        if lhs.externalBottomOffset != rhs.externalBottomOffset {
            return false
        }
        return true
    }
}

private final class StarsTransactionsHeaderItemComponent: CombinedComponent {
    let theme: PresentationTheme
    let title: String
    let activityFraction: CGFloat
    
    init(
        theme: PresentationTheme,
        title: String,
        activityFraction: CGFloat
    ) {
        self.theme = theme
        self.title = title
        self.activityFraction = activityFraction
    }
    
    static func ==(lhs: StarsTransactionsHeaderItemComponent, rhs: StarsTransactionsHeaderItemComponent) -> Bool {
        if lhs.theme !== rhs.theme {
            return false
        }
        if lhs.title != rhs.title {
            return false
        }
        if lhs.activityFraction != rhs.activityFraction {
            return false
        }
        return true
    }
    
    static var body: Body {
        let activeText = Child(Text.self)
        let inactiveText = Child(Text.self)
        
        return { context in
            let activeText = activeText.update(
                component: Text(text: context.component.title, font: Font.medium(14.0), color: context.component.theme.list.itemAccentColor),
                availableSize: context.availableSize,
                transition: .immediate
            )
            let inactiveText = inactiveText.update(
                component: Text(text: context.component.title, font: Font.medium(14.0), color: context.component.theme.list.itemSecondaryTextColor),
                availableSize: context.availableSize,
                transition: .immediate
            )
            
            context.add(activeText
                .position(CGPoint(x: activeText.size.width * 0.5, y: activeText.size.height * 0.5))
                .opacity(context.component.activityFraction)
            )
            context.add(inactiveText
                .position(CGPoint(x: inactiveText.size.width * 0.5, y: inactiveText.size.height * 0.5))
                .opacity(1.0 - context.component.activityFraction)
            )
            
            return activeText.size
        }
    }
}

private extension CGFloat {
    func interpolate(with other: CGFloat, fraction: CGFloat) -> CGFloat {
        let invT = 1.0 - fraction
        let result = other * fraction + self * invT
        return result
    }
}

private extension CGPoint {
    func interpolate(with other: CGPoint, fraction: CGFloat) -> CGPoint {
        return CGPoint(x: self.x.interpolate(with: other.x, fraction: fraction), y: self.y.interpolate(with: other.y, fraction: fraction))
    }
}

private extension CGSize {
    func interpolate(with other: CGSize, fraction: CGFloat) -> CGSize {
        return CGSize(width: self.width.interpolate(with: other.width, fraction: fraction), height: self.height.interpolate(with: other.height, fraction: fraction))
    }
}

private extension CGRect {
    func interpolate(with other: CGRect, fraction: CGFloat) -> CGRect {
        return CGRect(origin: self.origin.interpolate(with: other.origin, fraction: fraction), size: self.size.interpolate(with: other.size, fraction: fraction))
    }
}

private final class StarsTransactionsHeaderComponent: Component {
    struct Item: Equatable {
        let id: AnyHashable
        let title: String

        init(
            id: AnyHashable,
            title: String
        ) {
            self.id = id
            self.title = title
        }
    }

    let theme: PresentationTheme
    let items: [Item]
    let activeIndex: Int
    let transitionFraction: CGFloat
    let switchToPanel: (AnyHashable) -> Void
    
    init(
        theme: PresentationTheme,
        items: [Item],
        activeIndex: Int,
        transitionFraction: CGFloat,
        switchToPanel: @escaping (AnyHashable) -> Void
    ) {
        self.theme = theme
        self.items = items
        self.activeIndex = activeIndex
        self.transitionFraction = transitionFraction
        self.switchToPanel = switchToPanel
    }
    
    static func ==(lhs: StarsTransactionsHeaderComponent, rhs: StarsTransactionsHeaderComponent) -> Bool {
        if lhs.theme !== rhs.theme {
            return false
        }
        if lhs.items != rhs.items {
            return false
        }
        if lhs.activeIndex != rhs.activeIndex {
            return false
        }
        if lhs.transitionFraction != rhs.transitionFraction {
            return false
        }
        return true
    }
    
    class View: UIView {
        private var component: StarsTransactionsHeaderComponent?
        
        private var visibleItems: [AnyHashable: ComponentView<Empty>] = [:]
        private let activeItemLayer: SimpleLayer
        
        override init(frame: CGRect) {
            self.activeItemLayer = SimpleLayer()
            self.activeItemLayer.cornerRadius = 2.0
            self.activeItemLayer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            
            super.init(frame: frame)
            
            self.layer.addSublayer(self.activeItemLayer)
            
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(_:))))
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc private func tapGesture(_ recognizer: UITapGestureRecognizer) {
            if case .ended = recognizer.state {
                let point = recognizer.location(in: self)
                var closestId: (CGFloat, AnyHashable)?
                if self.bounds.contains(point) {
                    for (id, item) in self.visibleItems {
                        if let itemView = item.view {
                            let distance: CGFloat = min(abs(point.x - itemView.frame.minX), abs(point.x - itemView.frame.maxX))
                            if let closestIdValue = closestId {
                                if distance < closestIdValue.0 {
                                    closestId = (distance, id)
                                }
                            } else {
                                closestId = (distance, id)
                            }
                        }
                    }
                }
                if let closestId = closestId, let component = self.component {
                    component.switchToPanel(closestId.1)
                }
            }
        }
        
        func update(component: StarsTransactionsHeaderComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
            let themeUpdated = self.component?.theme !== component.theme
            
            self.component = component
            
            var validIds = Set<AnyHashable>()
            for i in 0 ..< component.items.count {
                let item = component.items[i]
                validIds.insert(item.id)
                
                let itemView: ComponentView<Empty>
                var itemTransition = transition
                if let current = self.visibleItems[item.id] {
                    itemView = current
                } else {
                    itemTransition = .immediate
                    itemView = ComponentView()
                    self.visibleItems[item.id] = itemView
                }
                
                let activeIndex: CGFloat = CGFloat(component.activeIndex) - component.transitionFraction
                let activityDistance: CGFloat = abs(activeIndex - CGFloat(i))
                
                let activityFraction: CGFloat
                if activityDistance < 1.0 {
                    activityFraction = 1.0 - activityDistance
                } else {
                    activityFraction = 0.0
                }
                
                let itemSize = itemView.update(
                    transition: itemTransition,
                    component: AnyComponent(StarsTransactionsHeaderItemComponent(
                        theme: component.theme,
                        title: item.title,
                        activityFraction: activityFraction
                    )),
                    environment: {},
                    containerSize: availableSize
                )
                
                let itemHorizontalSpace = availableSize.width / CGFloat(component.items.count)
                let itemX: CGFloat
                if component.items.count == 1 {
                    itemX = 37.0
                } else {
                    itemX = itemHorizontalSpace * CGFloat(i) + floor((itemHorizontalSpace - itemSize.width) / 2.0)
                }
                
                let itemFrame = CGRect(origin: CGPoint(x: itemX, y: floor((availableSize.height - itemSize.height) / 2.0)), size: itemSize)
                if let itemComponentView = itemView.view {
                    if itemComponentView.superview == nil {
                        self.addSubview(itemComponentView)
                        itemComponentView.isUserInteractionEnabled = false
                    }
                    itemTransition.setFrame(view: itemComponentView, frame: itemFrame)
                }
            }
            
            if component.activeIndex < component.items.count {
                let activeView = self.visibleItems[component.items[component.activeIndex].id]?.view
                let nextIndex: Int
                if component.transitionFraction > 0.0 {
                    nextIndex = max(0, component.activeIndex - 1)
                } else {
                    nextIndex = min(component.items.count - 1, component.activeIndex + 1)
                }
                let nextView = self.visibleItems[component.items[nextIndex].id]?.view
                if let activeView = activeView, let nextView = nextView {
                    let mergedFrame = activeView.frame.interpolate(with: nextView.frame, fraction: abs(component.transitionFraction))
                    transition.setFrame(layer: self.activeItemLayer, frame: CGRect(origin: CGPoint(x: mergedFrame.minX, y: availableSize.height - 3.0), size: CGSize(width: mergedFrame.width, height: 3.0)))
                }
            }
            
            if themeUpdated {
                self.activeItemLayer.backgroundColor = component.theme.list.itemAccentColor.cgColor
            }
            
            var removeIds: [AnyHashable] = []
            for (id, itemView) in self.visibleItems {
                if !validIds.contains(id) {
                    removeIds.append(id)
                    if let itemComponentView = itemView.view {
                        itemComponentView.removeFromSuperview()
                    }
                }
            }
            for id in removeIds {
                self.visibleItems.removeValue(forKey: id)
            }
            
            return availableSize
        }
    }
    
    func makeView() -> View {
        return View(frame: CGRect())
    }
    
    func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}

final class StarsTransactionsPanelContainerComponent: Component {
    typealias EnvironmentType = StarsTransactionsPanelContainerEnvironment
    
    struct Item: Equatable {
        let id: AnyHashable
        let title: String
        let panel: AnyComponent<StarsTransactionsPanelEnvironment>

        init(
            id: AnyHashable,
            title: String,
            panel: AnyComponent<StarsTransactionsPanelEnvironment>
        ) {
            self.id = id
            self.title = title
            self.panel = panel
        }
    }

    let theme: PresentationTheme
    let strings: PresentationStrings
    let dateTimeFormat: PresentationDateTimeFormat
    let insets: UIEdgeInsets
    let items: [Item]
    let currentPanelUpdated: (AnyHashable, ComponentTransition) -> Void
    
    init(
        theme: PresentationTheme,
        strings: PresentationStrings,
        dateTimeFormat: PresentationDateTimeFormat,
        insets: UIEdgeInsets,
        items: [Item],
        currentPanelUpdated: @escaping (AnyHashable, ComponentTransition) -> Void
    ) {
        self.theme = theme
        self.strings = strings
        self.dateTimeFormat = dateTimeFormat
        self.insets = insets
        self.items = items
        self.currentPanelUpdated = currentPanelUpdated
    }
    
    static func ==(lhs: StarsTransactionsPanelContainerComponent, rhs: StarsTransactionsPanelContainerComponent) -> Bool {
        if lhs.theme !== rhs.theme {
            return false
        }
        if lhs.strings !== rhs.strings {
            return false
        }
        if lhs.dateTimeFormat != rhs.dateTimeFormat {
            return false
        }
        if lhs.insets != rhs.insets {
            return false
        }
        if lhs.items != rhs.items {
            return false
        }
        return true
    }
    
    class View: UIView, UIGestureRecognizerDelegate {
        private let topPanelClippingView: UIView
        private let topPanelBackgroundView: UIView
        private let topPanelMergedBackgroundView: UIView
        private let topPanelSeparatorLayer: SimpleLayer
        private let header = ComponentView<Empty>()
        
        private var component: StarsTransactionsPanelContainerComponent?
        private weak var state: EmptyComponentState?
        
        private let panelsBackgroundLayer: SimpleLayer
        private let clippingView: UIView
        private var visiblePanels: [AnyHashable: ComponentView<StarsTransactionsPanelEnvironment>] = [:]
        private var actualVisibleIds = Set<AnyHashable>()
        private var currentId: AnyHashable?
        private var transitionFraction: CGFloat = 0.0
        private var animatingTransition: Bool = false
        
        override init(frame: CGRect) {
            self.topPanelClippingView = UIView()
            self.topPanelClippingView.clipsToBounds = true
            self.topPanelClippingView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            
            self.topPanelBackgroundView = UIView()
            
            self.topPanelMergedBackgroundView = UIView()
            self.topPanelMergedBackgroundView.alpha = 0.0
            
            self.topPanelSeparatorLayer = SimpleLayer()
            
            self.panelsBackgroundLayer = SimpleLayer()
            
            self.clippingView = UIView()
            self.clippingView.clipsToBounds = true
            
            super.init(frame: frame)
            
            self.layer.addSublayer(self.panelsBackgroundLayer)
            self.addSubview(self.clippingView)
            self.addSubview(self.topPanelClippingView)
            self.topPanelClippingView.addSubview(self.topPanelBackgroundView)
            self.topPanelClippingView.addSubview(self.topPanelMergedBackgroundView)
            self.layer.addSublayer(self.topPanelSeparatorLayer)
            
            let panRecognizer = InteractiveTransitionGestureRecognizer(target: self, action: #selector(self.panGesture(_:)), allowedDirections: { [weak self] point in
                guard let self, let component = self.component, let currentId = self.currentId else {
                    return []
                }
                guard let index = component.items.firstIndex(where: { $0.id == currentId }) else {
                    return []
                }
                
                /*if strongSelf.tabsContainerNode.bounds.contains(strongSelf.view.convert(point, to: strongSelf.tabsContainerNode.view)) {
                    return []
                }*/
                
                if index == 0 {
                    return .left
                }
                return [.left, .right]
            })
            panRecognizer.delegate = self
            panRecognizer.delaysTouchesBegan = false
            panRecognizer.cancelsTouchesInView = true
            self.addGestureRecognizer(panRecognizer)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        var currentPanelView: UIView? {
            guard let currentId = self.currentId, let panel = self.visiblePanels[currentId] else {
                return nil
            }
            return panel.view
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return false
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            if let _ = otherGestureRecognizer as? InteractiveTransitionGestureRecognizer {
                return false
            }
            if let _ = otherGestureRecognizer as? UIPanGestureRecognizer {
                return true
            }
            return false
        }
        
        @objc private func panGesture(_ recognizer: UIPanGestureRecognizer) {
            switch recognizer.state {
            case .began:
                func cancelContextGestures(view: UIView) {
                    if let gestureRecognizers = view.gestureRecognizers {
                        for gesture in gestureRecognizers {
                            if let gesture = gesture as? ContextGesture {
                                gesture.cancel()
                            }
                        }
                    }
                    for subview in view.subviews {
                        cancelContextGestures(view: subview)
                    }
                }
                
                cancelContextGestures(view: self)
                
                //self.animatingTransition = true
            case .changed:
                guard let component = self.component, let currentId = self.currentId else {
                    return
                }
                guard let index = component.items.firstIndex(where: { $0.id == currentId }) else {
                    return
                }
                
                let translation = recognizer.translation(in: self)
                var transitionFraction = translation.x / self.bounds.width
                if index <= 0 {
                    transitionFraction = min(0.0, transitionFraction)
                }
                if index >= component.items.count - 1 {
                    transitionFraction = max(0.0, transitionFraction)
                }
                self.transitionFraction = transitionFraction
                self.state?.updated(transition: .immediate)
            case .cancelled, .ended:
                guard let component = self.component, let currentId = self.currentId else {
                    return
                }
                guard let index = component.items.firstIndex(where: { $0.id == currentId }) else {
                    return
                }
                
                let translation = recognizer.translation(in: self)
                let velocity = recognizer.velocity(in: self)
                var directionIsToRight: Bool?
                if abs(velocity.x) > 10.0 {
                    directionIsToRight = velocity.x < 0.0
                } else {
                    if abs(translation.x) > self.bounds.width / 2.0 {
                        directionIsToRight = translation.x > self.bounds.width / 2.0
                    }
                }
                if let directionIsToRight = directionIsToRight {
                    var updatedIndex = index
                    if directionIsToRight {
                        updatedIndex = min(updatedIndex + 1, component.items.count - 1)
                    } else {
                        updatedIndex = max(updatedIndex - 1, 0)
                    }
                    self.currentId = component.items[updatedIndex].id
                }
                self.transitionFraction = 0.0
                
                let transition = ComponentTransition(animation: .curve(duration: 0.35, curve: .spring))
                if let currentId = self.currentId {
                    self.state?.updated(transition: transition)
                    component.currentPanelUpdated(currentId, transition)
                }
                
                self.animatingTransition = false
                //self.currentPaneUpdated?(false)
                
                //self.currentPaneStatusPromise.set(self.currentPane?.node.status ?? .single(nil))
            default:
                break
            }
        }
        
        func updateNavigationMergeFactor(value: CGFloat, transition: ComponentTransition) {
            transition.setAlpha(view: self.topPanelMergedBackgroundView, alpha: value)
            transition.setAlpha(view: self.topPanelBackgroundView, alpha: 1.0 - value)
        }
        
        func transferVelocity(_ velocity: CGFloat) {
            if let currentPanelView = self.currentPanelView as? StarsTransactionsListPanelComponent.View {
                currentPanelView.transferVelocity(velocity)
            }
        }
        
        func scrollToTop() -> Bool {
            if let currentPanelView = self.currentPanelView as? StarsTransactionsListPanelComponent.View {
                return currentPanelView.scrollToTop()
            }
            return false
        }
        
        func update(component: StarsTransactionsPanelContainerComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<StarsTransactionsPanelContainerEnvironment>, transition: ComponentTransition) -> CGSize {
            let environment = environment[StarsTransactionsPanelContainerEnvironment.self].value
            
            let themeUpdated = self.component?.theme !== component.theme
            
            self.component = component
            self.state = state
            
            if themeUpdated {
                self.panelsBackgroundLayer.backgroundColor = component.theme.list.itemBlocksBackgroundColor.cgColor
                self.topPanelSeparatorLayer.backgroundColor = component.theme.list.itemBlocksSeparatorColor.cgColor
                self.topPanelBackgroundView.backgroundColor = component.theme.list.itemBlocksBackgroundColor
                self.topPanelMergedBackgroundView.backgroundColor = component.theme.rootController.navigationBar.blurredBackgroundColor
            }
            
            let topPanelCoverHeight: CGFloat = 10.0
            
            let containerWidth = availableSize.width - component.insets.left - component.insets.right
            let topPanelFrame = CGRect(origin: CGPoint(x: component.insets.left, y: -topPanelCoverHeight), size: CGSize(width: containerWidth, height: 44.0))
            transition.setFrame(view: self.topPanelClippingView, frame: topPanelFrame)
            transition.setFrame(view: self.topPanelBackgroundView, frame: CGRect(origin: .zero, size: topPanelFrame.size))
            transition.setFrame(view: self.topPanelMergedBackgroundView, frame: CGRect(origin: .zero, size: topPanelFrame.size))

            transition.setCornerRadius(layer: self.topPanelClippingView.layer, cornerRadius: component.insets.left > 0.0 ? 11.0 : 0.0)
            
            transition.setFrame(layer: self.panelsBackgroundLayer, frame: CGRect(origin: CGPoint(x: component.insets.left, y: topPanelFrame.maxY), size: CGSize(width: containerWidth, height: availableSize.height - topPanelFrame.maxY)))
            
            transition.setFrame(layer: self.topPanelSeparatorLayer, frame: CGRect(origin: CGPoint(x: component.insets.left, y: topPanelFrame.maxY), size: CGSize(width: containerWidth, height: UIScreenPixel)))
            
            if let currentIdValue = self.currentId, !component.items.contains(where: { $0.id == currentIdValue }) {
                self.currentId = nil
            }
            if self.currentId == nil {
                self.currentId = component.items.first?.id
            }
            
            var visibleIds = Set<AnyHashable>()
            var currentIndex: Int?
            if let currentId = self.currentId {
                visibleIds.insert(currentId)
                
                if let index = component.items.firstIndex(where: { $0.id == currentId }) {
                    currentIndex = index
                    if index != 0 {
                        visibleIds.insert(component.items[index - 1].id)
                    }
                    if index != component.items.count - 1 {
                        visibleIds.insert(component.items[index + 1].id)
                    }
                }
            }
            
            let sideInset: CGFloat = 16.0 + component.insets.left
            let condensedPanelWidth: CGFloat = availableSize.width - sideInset * 2.0
            let headerSize = self.header.update(
                transition: transition,
                component: AnyComponent(StarsTransactionsHeaderComponent(
                    theme: component.theme,
                    items: component.items.map { item -> StarsTransactionsHeaderComponent.Item in
                        return StarsTransactionsHeaderComponent.Item(
                            id: item.id,
                            title: item.title
                        )
                    },
                    activeIndex: currentIndex ?? 0,
                    transitionFraction: self.transitionFraction,
                    switchToPanel: { [weak self] id in
                        guard let self, let component = self.component else {
                            return
                        }
                        if component.items.contains(where: { $0.id == id }) {
                            self.currentId = id
                            let transition = ComponentTransition(animation: .curve(duration: 0.35, curve: .spring))
                            self.state?.updated(transition: transition)
                            component.currentPanelUpdated(id, transition)
                        }
                    }
                )),
                environment: {},
                containerSize: CGSize(width: condensedPanelWidth, height: topPanelFrame.size.height)
            )
            if let headerView = self.header.view {
                if headerView.superview == nil {
                    self.addSubview(headerView)
                }
                transition.setFrame(view: headerView, frame: CGRect(origin: topPanelFrame.origin.offsetBy(dx: 16.0, dy: 0.0), size: headerSize))
            }
                        
            let centralPanelFrame = CGRect(origin: CGPoint(x: 0.0, y: topPanelFrame.maxY), size: CGSize(width: availableSize.width, height: availableSize.height - topPanelFrame.maxY))
            
            if self.animatingTransition {
                visibleIds = visibleIds.filter({ self.visiblePanels[$0] != nil })
            }
            
            self.actualVisibleIds = visibleIds
            
            for (id, _) in self.visiblePanels {
                visibleIds.insert(id)
            }
                        
            var validIds = Set<AnyHashable>()
            if let currentIndex {
                var anyAnchorOffset: CGFloat = 0.0
                for (id, panel) in self.visiblePanels {
                    guard let itemIndex = component.items.firstIndex(where: { $0.id == id }), let panelView = panel.view else {
                        continue
                    }
                    var itemFrame = centralPanelFrame.offsetBy(dx: self.transitionFraction * availableSize.width, dy: 0.0)
                    if itemIndex < currentIndex {
                        itemFrame.origin.x -= itemFrame.width
                    } else if itemIndex > currentIndex {
                        itemFrame.origin.x += itemFrame.width
                    }
                    
                    anyAnchorOffset = itemFrame.minX - panelView.frame.minX
                    
                    break
                }
                
                for id in visibleIds {
                    guard let itemIndex = component.items.firstIndex(where: { $0.id == id }) else {
                        continue
                    }
                    let panelItem = component.items[itemIndex]
                    
                    var itemFrame = centralPanelFrame.offsetBy(dx: self.transitionFraction * availableSize.width, dy: 0.0)
                    if itemIndex < currentIndex {
                        itemFrame.origin.x -= itemFrame.width
                    } else if itemIndex > currentIndex {
                        itemFrame.origin.x += itemFrame.width
                    }
                        
                    validIds.insert(panelItem.id)
                    
                    let panel: ComponentView<StarsTransactionsPanelEnvironment>
                    var panelTransition = transition
                    var animateInIfNeeded = false
                    if let current = self.visiblePanels[panelItem.id] {
                        panel = current
                        
                        if let panelView = panel.view, !panelView.bounds.isEmpty {
                            var wasHidden = false
                            if abs(panelView.frame.minX - availableSize.width) < .ulpOfOne || abs(panelView.frame.maxX - 0.0) < .ulpOfOne {
                                wasHidden = true
                            }
                            var isHidden = false
                            if abs(itemFrame.minX - availableSize.width) < .ulpOfOne || abs(itemFrame.maxX - 0.0) < .ulpOfOne {
                                isHidden = true
                            }
                            if wasHidden && isHidden {
                                panelTransition = .immediate
                            }
                        }
                    } else {
                        panelTransition = .immediate
                        animateInIfNeeded = true
                        
                        panel = ComponentView()
                        self.visiblePanels[panelItem.id] = panel
                    }
                    
                    let childEnvironment = StarsTransactionsPanelEnvironment(
                        theme: component.theme,
                        strings: component.strings,
                        dateTimeFormat: component.dateTimeFormat,
                        containerInsets: UIEdgeInsets(top: 0.0, left: component.insets.left, bottom: component.insets.bottom, right: component.insets.right),
                        isScrollable: environment.isScrollable,
                        isCurrent: self.currentId == panelItem.id
                    )
                    
                    let _ = panel.update(
                        transition: panelTransition,
                        component: panelItem.panel,
                        environment: {
                            childEnvironment
                        },
                        containerSize: centralPanelFrame.size
                    )
                    if let panelView = panel.view {
                        if panelView.superview == nil {
                            self.clippingView.addSubview(panelView)
                        }
                        
                        panelTransition.setFrame(view: panelView, frame: itemFrame, completion: { [weak self] _ in
                            guard let self else {
                                return
                            }
                            if !self.actualVisibleIds.contains(id) {
                                if let panel = self.visiblePanels[id] {
                                    self.visiblePanels.removeValue(forKey: id)
                                    panel.view?.removeFromSuperview()
                                }
                            }
                        })
                        if animateInIfNeeded && anyAnchorOffset != 0.0 {
                            transition.animatePosition(view: panelView, from: CGPoint(x: -anyAnchorOffset, y: 0.0), to: CGPoint(), additive: true)
                        }
                    }
                }
            }
            
            let clippingFrame = CGRect(origin: CGPoint(x: component.insets.left, y: 0.0), size: CGSize(width: availableSize.width - component.insets.left - component.insets.right, height: availableSize.height))
            
            transition.setPosition(view: self.clippingView, position: clippingFrame.center)
            transition.setBounds(view: self.clippingView, bounds: CGRect(origin: CGPoint(x: component.insets.left, y: 0.0), size: clippingFrame.size))
            
            var removeIds: [AnyHashable] = []
            for (id, panel) in self.visiblePanels {
                if !validIds.contains(id) {
                    removeIds.append(id)
                    if let panelView = panel.view {
                        panelView.removeFromSuperview()
                    }
                }
            }
            for id in removeIds {
                self.visiblePanels.removeValue(forKey: id)
            }
            
            return availableSize
        }
    }
    
    func makeView() -> View {
        return View(frame: CGRect())
    }
    
    func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<StarsTransactionsPanelContainerEnvironment>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}
