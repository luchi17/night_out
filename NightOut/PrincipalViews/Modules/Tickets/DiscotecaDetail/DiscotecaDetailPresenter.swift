import Combine
import SwiftUI
import Firebase

class DiscotecaDetailViewModel: ObservableObject {
    
    @Published var loading: Bool = false
    @Published var toast: ToastType?
    
    @Published var companyModel: CompanyModel
    @Published var following: FollowButtonType = .follow
    @Published var fiestas: [Fiesta]
    
    init(companyModel: CompanyModel, fiestas: [Fiesta]) {
        self.companyModel = companyModel
        self.fiestas = fiestas
    }
}

protocol DiscotecaDetailPresenter {
    var viewModel: DiscotecaDetailViewModel { get }
    func transform(input: DiscotecaDetailPresenterImpl.Input)
}

final class DiscotecaDetailPresenterImpl: DiscotecaDetailPresenter {
    var viewModel: DiscotecaDetailViewModel
    
    struct Input {
        let viewIsLoaded: AnyPublisher<Void, Never>
        let followTapped: AnyPublisher<Void, Never>
        let goBack: AnyPublisher<Void, Never>
    }
    
    struct UseCases {
        let followUseCase: FollowUseCase
    }
    
    struct Actions {
        let goBack: VoidClosure
    }
    
    // MARK: - Stored Properties
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    init(actions: Actions, useCases: UseCases, companyModel: CompanyModel, fiestas: [Fiesta]) {
        
        self.viewModel = DiscotecaDetailViewModel(
            companyModel: companyModel,
            fiestas: fiestas
        )
        self.actions = actions
        self.useCases = useCases
    }
    
    func transform(input: Input) {
        
        input
            .viewIsLoaded
            .withUnretained(self)
            .flatMap({ presenter, _ -> AnyPublisher<FollowModel?, Never> in
                guard let currentUId = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just(nil).eraseToAnyPublisher()
                }
                return presenter.useCases.followUseCase.fetchFollow(id: currentUId)
            })
            .withUnretained(self)
            .sink { presenter, followModel in
                
                let followingCompany = followModel?.following?.keys.contains(presenter.viewModel.companyModel.uid) ?? false
                presenter.viewModel.following = followingCompany ? .following : .follow
            }
            .store(in: &cancellables)
        
        input
            .followTapped
            .withUnretained(self)
            .sink { presenter, followModel in
                presenter.followButtonTapped()
            }
            .store(in: &cancellables)

        input
            .goBack
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.actions.goBack()
            }
            .store(in: &cancellables)
    }
    
    private func followButtonTapped() {
        guard let currentUId = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            return
        }
        switch viewModel.following {
        case .follow:
            // Añadir al seguimiento en "Follow"
            useCases.followUseCase.addFollow(
                requesterProfileUid: currentUId,
                profileUid: viewModel.companyModel.uid,
                needRemoveFromPending: false
            )
            .withUnretained(self)
            .sink { presenter, followOk in
                if followOk {
                    print("started following \(presenter.viewModel.companyModel.uid)")
                    presenter.viewModel.following = .following
                } else {
                    print("Error: started following \(presenter.viewModel.companyModel.uid)")
                }
            }
            .store(in: &cancellables)
            
        case .following:
            // Eliminar del seguimiento en "Follow"
            useCases.followUseCase.removeFollow(
                requesterProfileUid: currentUId,
                profileUid: viewModel.companyModel.uid
            )
            .withUnretained(self)
            .sink { presenter, unfollowOk in
                if unfollowOk {
                    print("remove following \(presenter.viewModel.companyModel.uid)")
                    presenter.viewModel.following = .follow
                } else {
                    print("Error: removing following \(presenter.viewModel.companyModel.uid)")
                }
            }
            .store(in: &cancellables)
        }
    }
}
