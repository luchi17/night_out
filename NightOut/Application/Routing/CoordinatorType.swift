import Foundation

public protocol CoordinatorType {
    func start()
    func close(_ completion: VoidClosure?)
}
