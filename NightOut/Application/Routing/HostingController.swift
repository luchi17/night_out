import Foundation
import SwiftUI

public final class HostingController<Content>: UIHostingController<Content> where Content: View {
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        view.setNeedsUpdateConstraints()
    }

    // MARK: - UIViewController

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        statusBarStyle
    }

    public override var prefersStatusBarHidden: Bool {
        false
    }

    // MARK: - Status Bar Style
    private var statusBarStyle = UIStatusBarStyle.default

    public func statusBar(style: UIStatusBarStyle) -> some HostingController<Content> {
        statusBarStyle = style
        setNeedsStatusBarAppearanceUpdate()
        return self
    }
    
    /// Used to customize individual view navigation bar
//    public func barAppearance(theme: NavBarTheme) -> some HostingController<Content> {
//        let appearance = theme.createNavBarAppearance()
//
//        self.navigationItem.standardAppearance = appearance
//        self.navigationItem.scrollEdgeAppearance = appearance
//        self.navigationItem.compactAppearance = appearance
//        self.navigationItem.backButtonTitle = nil
//        self.navigationItem.backButtonDisplayMode = .minimal
//
//        return self
//    }
    
    public override var shouldAutorotate: Bool {
        return true
    }
    
    private var supportedOrientations: UIInterfaceOrientationMask = .portrait
    
    public func supportedOrientations(_ supportedOrientations: UIInterfaceOrientationMask) -> some HostingController<Content> {
        self.supportedOrientations = supportedOrientations
        if #available(iOS 16.0, *) {
            setNeedsUpdateOfSupportedInterfaceOrientations()
        }
        
        return self
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return supportedOrientations
    }
}

