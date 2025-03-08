import SwiftUI
import Combine

class TicketDetailCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TicketDetailCoordinator, rhs: TicketDetailCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: TicketDetailPresenterImpl.Actions
    private let model: (CompanyModel, Fiesta)
    
    init(actions: TicketDetailPresenterImpl.Actions, model: (CompanyModel, Fiesta)) {
        self.actions = actions
        self.model = model
    }
    
    @ViewBuilder
    func build() -> some View {
        TicketDetailView(presenter: TicketDetailPresenterImpl(
            actions: actions,
            useCases: .init(),
            companyModel: model.0,
            fiesta: model.1
        ))
    }
}
