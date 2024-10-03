
import SwiftUI
import Combine

public struct SearchCoordinator {
    public init() { }
    
    public func start() -> any View {
        return SearchView()
    }
}

