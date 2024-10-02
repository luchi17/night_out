import UIKit

public class NavigationController: UINavigationController {
    /*
     To enable status bar appearance on a screen by screen bases:
     */
    public override var childForStatusBarStyle: UIViewController? {
        visibleViewController?.isBeingDismissed == false ? visibleViewController : topViewController
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        visibleViewController?.preferredStatusBarStyle ?? .lightContent
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return visibleViewController?.supportedInterfaceOrientations ?? .portrait
    }
}

extension UINavigationController {
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        navigationBar.topItem?.backButtonDisplayMode = .minimal
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        topViewController?.preferredStatusBarStyle ?? .lightContent
    }

    open override var childForStatusBarStyle: UIViewController? {
        topViewController?.childForStatusBarStyle ?? topViewController
    }
}

