import SwiftUI
import Combine

class PayDetailCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PayDetailCoordinator, rhs: PayDetailCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: PayDetailPresenterImpl.Actions
    private let model: PayDetailModel
    
    init(actions: PayDetailPresenterImpl.Actions, model: PayDetailModel) {
        self.actions = actions
        self.model = model
    }
    
    @ViewBuilder
    func build() -> some View {
        PayDetailView(presenter: PayDetailPresenterImpl(
            actions: actions,
            useCases: .init(),
            model: model
        ))
    }
}
