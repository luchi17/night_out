import SwiftUI
import Combine
import Firebase

final class LeagueViewModel: ObservableObject {
    @Published var loading: Bool = false
    @Published var toast: ToastType?

}

protocol LeaguePresenter {
    var viewModel: LeagueViewModel { get }
    func transform(input: LeaguePresenterImpl.ViewInputs)
}

final class LeaguePresenterImpl: LeaguePresenter {
    
    struct UseCases {
        let followUseCase: FollowUseCase
    }
    
    struct Actions {
//        let goToProfile: InputClosure<ProfileModel>
//        let goToPrivateProfile: InputClosure<ProfileModel>
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let search: AnyPublisher<Void, Never>
    }
    
    var viewModel: LeagueViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()

    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        
        viewModel = LeagueViewModel()
    }
    
    func transform(input: LeaguePresenterImpl.ViewInputs) {
//        input
//            .goToProfile
//            .withUnretained(self)
//            .flatMap({ presenter, profileModel -> AnyPublisher<(FollowModel?, ProfileModel), Never> in
//                guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
//                    return Just((nil, profileModel)).eraseToAnyPublisher()
//                }
//                return presenter.useCases.followUseCase.fetchFollow(id: uid)
//                    .map({ ($0, profileModel) })
//                    .eraseToAnyPublisher()
//            })
//            .withUnretained(self)
//            .sink { presenter, data in
//            
//                let profileModel = data.1
//                let following = data.0?.following?.keys.first(where: { $0 == profileModel.profileId }) != nil
//                
//                if following {
//                    presenter.actions.goToProfile(profileModel)
//                } else {
//                    if profileModel.isPrivateProfile {
//                        presenter.actions.goToPrivateProfile(profileModel)
//                    } else {
//                        presenter.actions.goToProfile(profileModel)
//                    }
//                }
//            }
//            .store(in: &cancellables)
//        
    }
}
