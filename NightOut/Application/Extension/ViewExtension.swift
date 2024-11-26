import SwiftUI
import Combine

public extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition { transform(self) } else { self }
    }
    
    @ViewBuilder
    func `ifLet`<Transform: View, T>(_ value: T?, transform: ((value: T, view: Self)) -> Transform) -> some View {
        if let value = value {
            transform((value: value, view: self))
        } else {
            self
        }
    }
    
}

