import SwiftUI
import Combine

class DiscotecaDetailCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DiscotecaDetailCoordinator, rhs: DiscotecaDetailCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: DiscotecaDetailPresenterImpl.Actions
    private let model: (CompanyModel, [Fiesta])
    
    init(actions: DiscotecaDetailPresenterImpl.Actions, model: (CompanyModel, [Fiesta])) {
        self.actions = actions
        self.model = model
    }
    
    @ViewBuilder
    func build() -> some View {
        DiscotecaDetailView(presenter: DiscotecaDetailPresenterImpl(
            actions: actions,
            useCases: .init(followUseCase: FollowUseCaseImpl(repository: PostsRepositoryImpl.shared)),
            companyModel: model.0,
            fiestas: model.1
        ))
    }
}
