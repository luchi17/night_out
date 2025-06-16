import SwiftUI
import Combine
import Firebase

final class FriendsViewModel: ObservableObject {
    @Published var followers: [ProfileModel] = []
    @Published var followerIds: [String] = []
    
    @Published var loading: Bool = true
}

protocol FriendsPresenter {
    var viewModel: FriendsViewModel { get }
    func transform(input: FriendsPresenterImpl.ViewInputs)
}

final class FriendsPresenterImpl: FriendsPresenter {
    
    struct UseCases {
        let userDataUseCase: UserDataUseCase
        let companyDataUseCase: CompanyDataUseCase
    }
    
    struct Actions {
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<[String], Never>
        let goToProfile: AnyPublisher<ProfileModel, Never>
    }
    
    var viewModel: FriendsViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        
        viewModel = FriendsViewModel()
    }
    
    func transform(input: FriendsPresenterImpl.ViewInputs) {
        input
            .viewDidLoad
            .handleEvents(receiveOutput: { [weak self] followerIds in
                self?.viewModel.followerIds = followerIds
            })
            .withUnretained(self)
            .flatMap({ presenter, _  in
                presenter.getInfoOfFollowers(followerIds: presenter.viewModel.followerIds)
                    .eraseToAnyPublisher()
            })
            .withUnretained(self)
            .sink { presenter, profiles in
                presenter.viewModel.loading = false
                presenter.viewModel.followers = profiles
            }
            .store(in: &cancellables)
    }
    
    private func getInfoOfFollowers(followerIds: [String]) -> AnyPublisher<[ProfileModel], Never> {
        
        let publishers: [AnyPublisher<ProfileModel, Never>] = followerIds.map { followerId in
            
            if UserDefaults.getCompanies()?.users.first(where: { $0.value.uid == followerId }) != nil {
                
                useCases.companyDataUseCase.getCompanyInfo(uid: followerId)
                    .map { companyModel in
                        if let companyModel = companyModel {
                            return ProfileModel(
                                profileImageUrl: companyModel.imageUrl,
                                username: companyModel.username,
                                fullname: companyModel.fullname,
                                profileId: companyModel.uid,
                                isCompanyProfile: true,
                                isPrivateProfile: companyModel.profileType == .privateProfile
                            )
                        } else {
                            return ProfileModel(profileId: "", isCompanyProfile: false, isPrivateProfile: false)
                        }
                    }
                    .eraseToAnyPublisher()
            } else {
                useCases.userDataUseCase.getUserInfo(uid: followerId)
                    .map { userModel in
                        if let userModel = userModel {
                            return ProfileModel(
                                profileImageUrl: userModel.image,
                                username: userModel.username,
                                fullname: userModel.fullname,
                                profileId: userModel.uid,
                                isCompanyProfile: false,
                                isPrivateProfile: userModel.profileType == .privateProfile
                            )
                        } else {
                            return ProfileModel(profileId: "", isCompanyProfile: false, isPrivateProfile: false)
                        }
                       
                    }
                    .eraseToAnyPublisher()
            }
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }
    
}
