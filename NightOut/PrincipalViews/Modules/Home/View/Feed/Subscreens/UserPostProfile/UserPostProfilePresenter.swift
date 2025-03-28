import SwiftUI
import Combine

struct UserPostProfileInfo {
    var profileId: String
    var profileImageUrl: String?
    var username: String
    var fullName: String
    var isCompanyProfile: Bool
}

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

final class UserPostProfileViewModel: ObservableObject {
    @Published var profileImageUrl: String?
    @Published var username: String = "Nombre no disponible"
    @Published var fullname: String = "Username no disponible"
    @Published var followersCount: String = "0"
    @Published var discosCount: String = "0"
    @Published var copasCount: String = "0"
    @Published var images: [IdentifiableImage] = []
    @Published var isCompanyProfile: Bool
    @Published var profileId: String = ""
    
    var followers: [String] = []

    init(profileImageUrl: String? = nil, username: String, fullname: String, discosCount: String, copasCount: String, isCompanyProfile: Bool, profileId: String) {
        self.profileImageUrl = profileImageUrl
        self.username = username
        self.fullname = fullname
        self.discosCount = discosCount
        self.copasCount = copasCount
        self.isCompanyProfile = isCompanyProfile
        self.profileId = profileId
    }
}

protocol UserPostProfilePresenter {
    var viewModel: UserPostProfileViewModel { get }
    func transform(input: UserPostProfilePresenterImpl.ViewInputs)
}

final class UserPostProfilePresenterImpl: UserPostProfilePresenter {
    
    struct UseCases {
        let followUseCase: FollowUseCase
        let postsUseCase: PostsUseCase
        let userDataUseCase: UserDataUseCase
    }
    
    struct Actions {
        let goToFriendsList: InputClosure<[String]>
        let goBack: VoidClosure
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let goToFriendsList: AnyPublisher<Void, Never>
        let goBack: AnyPublisher<Void, Never>
    }
    
    var viewModel: UserPostProfileViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    private let info: UserPostProfileInfo
    
    init(
        useCases: UseCases,
        actions: Actions,
        info: UserPostProfileInfo
    ) {
        self.actions = actions
        self.useCases = useCases
        self.info = info

        viewModel = UserPostProfileViewModel(
            profileImageUrl: info.profileImageUrl,
            username: info.username,
            fullname: info.fullName,
            discosCount: "0",
            copasCount: "0",
            isCompanyProfile: info.isCompanyProfile,
            profileId: info.profileId
        )
    }
    
    func transform(input: UserPostProfilePresenterImpl.ViewInputs) {
        
        input
            .goToFriendsList
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.actions.goToFriendsList(presenter.viewModel.followers)
            }
            .store(in: &cancellables)
        
        input
            .viewDidLoad
            .filter({ [weak self] _ in  !(self?.info.isCompanyProfile ?? false) })
            .withUnretained(self)
            .flatMap({ presenter, _ in
                presenter.useCases.userDataUseCase.getUserInfo(uid: presenter.info.profileId)
            })
            .withUnretained(self)
            .sink { presenter, userModel in
                presenter.viewModel.copasCount = String(userModel?.MisCopas ?? 0)
                
                let uniqueDiscotecasCount = Set(userModel?.MisEntradas?.values.map { $0.discoteca } ?? []).count

                presenter.viewModel.discosCount = String(uniqueDiscotecasCount)
            }
            .store(in: &cancellables)
        
        
        let postsPublisher = input
            .viewDidLoad
            .withUnretained(self)
            .flatMap({ presenter, _ in
                presenter.useCases.followUseCase.fetchFollow(id: presenter.info.profileId)
                    .handleEvents(receiveOutput: { [weak self] followModel in
                        
                        if let followers = followModel?.followers?.keys {
                            self?.viewModel.followers = Array(followers)
                        }
                        self?.viewModel.followersCount = String(followModel?.followers?.count ?? 0)
                        
                    })
                    .eraseToAnyPublisher()
            })
            .filter({ [weak self] _ in  self?.info.isCompanyProfile ?? false })
            .withUnretained(self)
            .flatMap({ presenter, _ in
                presenter.useCases.postsUseCase.fetchPosts()
                    .map { posts in
                        let matchingPosts = posts.filter { post in
                            return post.value.publisherId == presenter.info.profileId
                        }.values
                        return Array(matchingPosts)
                    }
                    .eraseToAnyPublisher()
            })
            .eraseToAnyPublisher()
        
        postsPublisher
            .withUnretained(self)
            .flatMap { presenter, posts in
                let publishers: [AnyPublisher<IdentifiableImage, Never>] = posts.map { post in
                    
                    presenter.getPostImagePublisher(image: post.postImage)
                        .compactMap({ $0 })
                        .map({ IdentifiableImage(image: $0 )})
                        .eraseToAnyPublisher()
                }
                return Publishers.MergeMany(publishers)
                    .collect()
                    .eraseToAnyPublisher()
            }
            .withUnretained(self)
            .sink { presenter, images in
                presenter.viewModel.images = images
            }
            .store(in: &cancellables)

    }
    
    func getPostImagePublisher(image: String?) -> AnyPublisher<UIImage?, Never> {
        if let image = image, let url = URL(string: image) {
            return KingFisherImage.fetchImagePublisher(url: url)
        }
        
        return Just(nil).eraseToAnyPublisher()
    }
}
