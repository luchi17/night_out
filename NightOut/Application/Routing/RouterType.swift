import UIKit

public enum PresentationType {
    case fullScreen
    case pageSheet(dismissOnSwipeDown: Bool)
    case overCurrentContext
}

public protocol RouterType: AnyObject {
    func start()
    func popViewController(animated: Bool)
    func popToRootViewController(animated: Bool)
    func pushViewController(_ vc: UIViewController, animated: Bool)
    func presentViewController(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?)
    func setViewController(_ vc: UIViewController, animated: Bool)
    func present(
        coordinator: (RouterType) -> CoordinatorType,
        presentationType: PresentationType,
        onCompletion: (VoidClosure)?
    )
    func pushFlow(coordinator: (RouterType) -> CoordinatorType)
    func back()
    func close(_ completion: (VoidClosure)?)
}

// MARK: - Common Methods For Vertical & Horizontal Routers.
public protocol BaseRouter: RouterType {
    var navigationController: UINavigationController? { get }
}

public extension BaseRouter {
    func pushViewController(_ vc: UIViewController, animated: Bool) {
        navigationController?.pushViewController(vc, animated: animated)
    }

     func present(
        coordinator: (RouterType) -> CoordinatorType,
        presentationType: PresentationType,
        onCompletion: (VoidClosure)?
    ) {
        guard let navigationController = navigationController else { return }
            let vNavigator = VerticalRouter(
                presenter: navigationController,
                presentationType: presentationType,
                onCloseButtonTap: nil,
                onPresentedCompletion: onCompletion
            )
            coordinator(vNavigator).start()
            vNavigator.start()
        }

    func pushFlow(coordinator: (RouterType) -> CoordinatorType) {
        guard let navigationController = navigationController else { return }
        let newRouter = HorizontalRouter(navigationController: navigationController)
        coordinator(newRouter).start()
        newRouter.start()
    }

     func popToRootViewController(animated: Bool) {
         navigationController?.popToRootViewController(animated: animated)
    }

     func popViewController(animated: Bool) {
         navigationController?.popViewController(animated: animated)
    }

    func setViewController(_ vc: UIViewController, animated: Bool) {
        guard let navigationController = navigationController else { return }
        if !navigationController.viewControllers.isEmpty {
            var viewControllers = navigationController.viewControllers
            viewControllers.removeLast()
            viewControllers.append(vc)
            navigationController.setViewControllers(viewControllers, animated: animated)
        }
    }

    func presentViewController(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?) {
        navigationController?.present(vc, animated: animated, completion: completion)
    }

    var fdpPresentingController: UIViewController? {
        navigationController?.topViewController
    }
}

// MARK: - Horizontal Router.
public class HorizontalRouter: RouterType, BaseRouter {
    public weak var navigationController: UINavigationController?
    private let coordinatorRootViewController: UIViewController?
    private let onCloseButtonTap: (VoidClosure)?

    public init(
        navigationController: UINavigationController,
        onCloseButtonTap: (VoidClosure)? = nil
    ) {
        self.navigationController = navigationController
        self.onCloseButtonTap = onCloseButtonTap
        coordinatorRootViewController = navigationController.topViewController
    }

    public func close(_ completion: (() -> Void)?) {
        guard let navigationController = navigationController else {
            assertionFailure("Unexpected nil value")
            completion?()
            return
        }

        if let coordinatorRootViewController {
            navigationController.popToViewController(
               coordinatorRootViewController,
               animated: true
            )
        } else {
            navigationController.dismiss(animated: true)
        }

         completion?()
     }

    public func back() {
         guard let navigationController = navigationController else { return }
         var previousViewController: UIViewController? {
             let viewControllers = navigationController.viewControllers
             return viewControllers.count > 1 ? viewControllers[viewControllers.count - 2] : nil
         }

         if previousViewController == coordinatorRootViewController {
             close(onCloseButtonTap)
         } else {
             navigationController.popViewController(animated: true)
         }
     }

    // Horizontal Navigator doesn't have to do anything for starting itself as it will
    // remain in the current navigation flow. The vertical navigator will configure and present itself in this method.
    public func start() { }
}

// MARK: - Vertical Router.
public class VerticalRouter: RouterType, BaseRouter {
    public weak var navigationController: UINavigationController?

    // It is required to create a strong reference to the NavigationController until it is presented.
    private var navigationControllerNotPresented: UINavigationController?

    private weak var presenter: UIViewController?
    private let presentationType: PresentationType
    private let onCloseButtonTap: (VoidClosure)?
    private let onPresentedCompletion: (VoidClosure)?

    public init(
        presenter: UIViewController,
        presentationType: PresentationType,
        onCloseButtonTap: (VoidClosure)? = nil,
        onPresentedCompletion: (VoidClosure)?
    ) {
        self.presenter = presenter
        self.presentationType = presentationType
        self.onCloseButtonTap = onCloseButtonTap
        self.onPresentedCompletion = onPresentedCompletion
        self.navigationControllerNotPresented = NavigationController()
        self.navigationController = navigationControllerNotPresented
    }

    public func close(_ completion: (() -> Void)?) {
        navigationController?.dismiss(animated: true, completion: completion)
    }

    public func pushViewController(_ vc: UIViewController, animated: Bool) {
         navigationController?.pushViewController(vc, animated: animated)
    }

    public func back() {
         guard let navigationController = navigationController else { return }
         if navigationController.viewControllers.count <= 1 {
             close(onCloseButtonTap)
         } else {
             navigationController.popViewController(animated: true)
         }
     }

     public func start() {
        guard let navigationControllerNotPresented = navigationControllerNotPresented, let presenter = presenter else {
            return
        }

        navigationControllerNotPresented.setPresentationType(presentationType)
        if case let .pageSheet(dismissOnSwipeDown) = presentationType {
            navigationControllerNotPresented.isModalInPresentation = !dismissOnSwipeDown
        }
        if case .overCurrentContext = presentationType,
           presenter.tabBarController != nil {
            presenter
                .tabBarController?
                .present(
                    navigationControllerNotPresented,
                    animated: true,
                    completion: self.onPresentedCompletion
                )
        } else {
            presenter.present(navigationControllerNotPresented, animated: true, completion: self.onPresentedCompletion)
        }
        navigationController = navigationControllerNotPresented
        self.navigationControllerNotPresented = nil
    }
}

private extension UINavigationController {
    func setPresentationType(_ type: PresentationType) {
        switch type {
        case .fullScreen:
            modalPresentationStyle = .fullScreen
        case .pageSheet:
            modalPresentationStyle = .pageSheet
        case .overCurrentContext:
            modalPresentationStyle = .overCurrentContext
        }
    }
}
