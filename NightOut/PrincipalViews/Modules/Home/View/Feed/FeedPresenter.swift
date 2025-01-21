import SwiftUI
import Combine
import CoreLocation

#warning("Add cache of companies with UserDefaults.getCompanies() ")

final class FeedViewModel: ObservableObject {
    
    @Published var posts: [PostModel] = []
    
    @Published var loading: Bool = false
    @Published var toastError: ToastType?
    @Published var headerError: ErrorState?
    @Published var followersCount: Int = 0
    
    private var matchingPosts: [PostsUser] = []
    
    init() {
        
    }
    
}

protocol FeedPresenter {
    var viewModel: FeedViewModel { get }
    func transform(input: FeedPresenterImpl.ViewInputs)
}

final class FeedPresenterImpl: FeedPresenter {
    
    struct UseCases {
        let postsUseCase: PostsUseCase
        let followUseCase: FollowUseCase
        let userDataUseCase: UserDataUseCase
        let companyDataUseCase: CompanyDataUseCase
    }
    
    struct Actions {
        let onOpenMaps: InputClosure<(Double, Double)>
        let onOpenAppleMaps: InputClosure<(CLLocationCoordinate2D, String?)>
        let onShowUserProfile: InputClosure<UserPostProfileInfo>
        let onShowCompanyProfile: InputClosure<CompanyModel>
        let onShowPostComments: InputClosure<PostCommentsInfo>
        
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let openMaps: AnyPublisher<PostModel, Never>
        let openAppleMaps: AnyPublisher<PostModel, Never>
        let showUserOrCompanyProfile: AnyPublisher<PostModel, Never>
        let showCommentsView: AnyPublisher<PostModel, Never>
    }
    
    var viewModel: FeedViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    let defaultCoordinates = CLLocationCoordinate2D(latitude: Double(-90.0000), longitude: Double(-0.0000))
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        
        viewModel = FeedViewModel()
    }
    
    func transform(input: FeedPresenterImpl.ViewInputs) {
        
        listenToInput(input: input)
        
        let userPostsPublisher = input
            .viewDidLoad
            .withUnretained(self)
            .flatMapLatest({ presenter, _ -> AnyPublisher<FollowModel?, Never> in
                guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just(nil).eraseToAnyPublisher()
                }
                return presenter.useCases.followUseCase.fetchFollow(id: uid)
            })
            .handleEvents(receiveRequest: { [weak self] _ in
                self?.viewModel.loading = true
            })
            .withUnretained(self)
            .flatMapLatest({ presenter, followModel -> AnyPublisher<[PostUserModel], Never> in
                presenter.useCases.postsUseCase.fetchPosts()
                    .map { posts in
                        let matchingPosts = posts.filter { post in
                            followModel?.following?.keys.contains(post.value.publisherId) ?? false
                        }.values
                        return Array(matchingPosts)
                    }
                    .eraseToAnyPublisher()
            })
            .withUnretained(self)
            .eraseToAnyPublisher()
        
        userPostsPublisher
            .flatMapLatest({ presenter, userPosts ->  AnyPublisher<[PostModel], Never> in
                let publishers: [AnyPublisher<PostModel, Never>] = userPosts.map { post in
                    
                    if post.isFromUser ?? true {
                        presenter.getPostFromUserInfo(post: post)
                    } else {
                        presenter.getPostFromCompanyInfo(post: post)
                    }
                }
                
                return Publishers.MergeMany(publishers)
                    .collect()
                    .eraseToAnyPublisher()
            })
            .withUnretained(self)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .finished :
                    self.viewModel.loading = false
                case .failure(let error):
                    print("Error: \(error)")
                    self.viewModel.loading = false
                    self.viewModel.toastError = .custom(.init(title: "Error", description: "Could not load posts", image: nil))
                }
            }, receiveValue: { presenter, data in
                presenter.viewModel.loading = false
                presenter.viewModel.posts = Utils.sortByDate(objects: data, dateExtractor: { $0.date }, ascending: false)
            })
            .store(in: &cancellables)
        
    }
    
    func listenToInput(input: FeedPresenterImpl.ViewInputs) {
        input
            .openMaps
            .withUnretained(self)
            .sink { presenter, postModel in
                let coordinate = presenter.getLocationToOpen(postModel: postModel)
                presenter.actions.onOpenMaps((coordinate.latitude, coordinate.longitude))
            }
            .store(in: &cancellables)
        
        input
            .openAppleMaps
            .withUnretained(self)
            .sink { presenter, postModel in
                let coordinate = presenter.getLocationToOpen(postModel: postModel)
                
                if LocationManager.shared.areCoordinatesEqual(
                    coordinate1: coordinate,
                    coordinate2: presenter.defaultCoordinates
                ) {
                    presenter.actions.onOpenAppleMaps((coordinate: coordinate, placeName: "Narnia"))
                } else {
                    presenter.actions.onOpenAppleMaps((coordinate: coordinate, placeName: postModel.username))
                }
            }
            .store(in: &cancellables)
        
        input
            .showUserOrCompanyProfile
            .withUnretained(self)
            .sink { presenter, model in
                let profileInfo = UserPostProfileInfo(
                    profileId: model.publisherId,
                    profileImageUrl: model.profileImageUrl,
                    username: model.username ?? "Unknown",
                    fullName: model.fullName ?? "Unknown"
                )
                presenter.actions.onShowUserProfile(profileInfo)
            }
            .store(in: &cancellables)
        
        input
            .showCommentsView
            .map { model in
                PostCommentsInfo(
                    postId: model.uid,
                    postImage: model.postImage,
                    postIsFromUser: model.isFromUser,
                    publisherId: model.publisherId
                )
            }
            .withUnretained(self)
            .sink { presenter, model in
                presenter.actions.onShowPostComments(model)
            }
            .store(in: &cancellables)
            
    }
}

private extension FeedPresenterImpl {
    func getPostFromUserInfo(post: PostUserModel) -> AnyPublisher<PostModel, Never> {
        return useCases.userDataUseCase.getUserInfo(uid: post.publisherId)
            .withUnretained(self)
            .flatMapLatest({ presenter, userInfo in
                presenter.getPostImagePublisher(image: post.postImage)
                    .map( { (userInfo, $0) })
            })
            .withUnretained(self)
            .map({ presenter, data in
                let userInfo = data.0
                let postImage = data.1
                return PostModel(
                    profileImageUrl: userInfo?.image,
                    postImage: postImage,
                    description: post.description,
                    location: presenter.getClubNameByPostLocation(postLocation: post.location),
                    username: userInfo?.username,
                    fullName: userInfo?.fullname,
                    uid: post.postID,
                    isFromUser: post.isFromUser ?? true,
                    publisherId: post.publisherId,
                    date: post.date ?? Date().toIsoString()
                )
            })
            .eraseToAnyPublisher()
    }
    
    func getPostFromCompanyInfo(post: PostUserModel) -> AnyPublisher<PostModel, Never> {
        useCases.companyDataUseCase.getCompanyInfo(uid: post.publisherId)
            .withUnretained(self)
            .flatMapLatest({ presenter, companyInfo in
                presenter.getPostImagePublisher(image: post.postImage)
                    .map( { (companyInfo, $0) })
            })
            .withUnretained(self)
            .map({ presenter, data in
                let companyInfo = data.0
                let postImage = data.1
                return PostModel(
                    profileImageUrl: companyInfo?.imageUrl,
                    postImage: postImage,
                    description: post.description,
                    location: presenter.getLocationFromCompanyPost(postLocation: post.location, companylocation: companyInfo?.location),
                    username: companyInfo?.username,
                    fullName: companyInfo?.fullname,
                    uid: post.postID,
                    isFromUser: post.isFromUser ?? false,
                    publisherId: post.publisherId,
                    date: post.date ?? Date().toIsoString()
                )
            })
            .eraseToAnyPublisher()
    }
    
    func getLocationFromCompanyPost(postLocation: String?, companylocation: String?) -> String {
        if let location = postLocation {
            return "📍 \(location)"
        } else {
            return "📍 \(companylocation ?? "")"
        }
    }
    
    func getClubNameByPostLocation(postLocation: String?) -> String {
        let defaultLocation = "📍 De fiesta por Narnia"
        
        if let postLocation = postLocation, !postLocation.isEmpty {
            
            let postLocationCompany = UserDefaults.getCompanies()?.users.first(where: { company in
                return company.value.location == postLocation
            })?.value
            
            if let username = postLocationCompany?.username {
                return "📍 \(username)"
            } else {
                return defaultLocation
            }
        }
        
        return defaultLocation
    }
    
    func getLocationToOpen(postModel: PostModel) -> CLLocationCoordinate2D {
        let cleanedPostLocation = postModel.location?.replacingOccurrences(of: "📍 ", with: "")
        
        if postModel.isFromUser {
            
            let locationFromName = UserDefaults.getCompanies()?.users.first(where: { $0.value.username == cleanedPostLocation })?.value.location
            
            if let locationFromName = locationFromName,
               let coordinate = LocationManager.shared.getCoordinatesFromString(locationFromName) {
                return coordinate
            }

        } else {
            if let cleanedPostLocation = cleanedPostLocation,
               let coordinate = LocationManager.shared.getCoordinatesFromString(cleanedPostLocation) {
                return coordinate
            }
        }
        
        return defaultCoordinates
    }
    
    func getPostImagePublisher(image: String?) -> AnyPublisher<UIImage?, Never> {
        if let image = image, let url = URL(string: image) {
            return KingFisherImage.fetchImagePublisher(url: url)
        }
        return Just(nil).eraseToAnyPublisher()
    }
    
    
}
