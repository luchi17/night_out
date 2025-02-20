import SwiftUI
import Combine
import CoreLocation

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
    
    struct Input {
        let reload: AnyPublisher<Void, Never>
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
    private let outinput: Input
    private var cancellables = Set<AnyCancellable>()
    
    let defaultCoordinates = CLLocationCoordinate2D(latitude: Double(-90.0000), longitude: Double(-0.0000))
    
    init(
        useCases: UseCases,
        actions: Actions,
        input: Input
    ) {
        self.actions = actions
        self.useCases = useCases
        self.outinput = input
        
        viewModel = FeedViewModel()
    }
    
    func transform(input: FeedPresenterImpl.ViewInputs) {
        
        listenToInput(input: input)
        
        let userPostsPublisher = input
            .viewDidLoad
            .merge(with: outinput.reload)
            .withUnretained(self)
            .flatMap { presenter, _ in //Get user info and save it when feed appears
                guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just(()).eraseToAnyPublisher()
                }
                if FirebaseServiceImpl.shared.getImUser() {
                    return presenter.useCases.userDataUseCase.getUserInfo(uid: uid)
                        .map({ _ in })
                        .eraseToAnyPublisher()
                } else {
                    return presenter.useCases.companyDataUseCase.getCompanyInfo(uid: uid)
                        .map({ _ in })
                        .eraseToAnyPublisher()
                }
            }
            .withUnretained(self)
            .performRequest(request: { presenter, _ -> AnyPublisher<FollowModel?, Never> in
                guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just(nil).eraseToAnyPublisher()
                }
                return presenter.useCases.followUseCase.observeFollow(id: uid)
                
            }, loadingClosure: { [weak self] loading in
                guard let self = self else { return }
                self.viewModel.loading = loading
            }, onError: { _ in }
            )
            .withUnretained(self)
            .performRequest(request: { presenter, followModel -> AnyPublisher<[PostUserModel], Never> in
                presenter.useCases.postsUseCase.fetchPosts()
                    .map { posts in
                        let matchingPosts = posts.filter { post in
                            let myFollowingPosts = followModel?.following?.keys.contains(post.value.publisherId) ?? false
                            let myPosts = post.value.publisherId == FirebaseServiceImpl.shared.getCurrentUserUid()
                            
                            return myFollowingPosts || myPosts
                        }.values
                        return Array(matchingPosts)
                    }
                    .eraseToAnyPublisher()
            })
            .withUnretained(self)
            .eraseToAnyPublisher()
        
        userPostsPublisher
            .performRequest(request: { presenter, userPosts -> AnyPublisher<[PostModel], Never> in
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
                
            }, loadingClosure: { [weak self] loading in
                guard let self = self else { return }
                self.viewModel.loading = loading
            }, onError: { _ in }
            )
            .withUnretained(self)
            .sink(receiveValue: { presenter, data in
                presenter.viewModel.posts = data
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
                    fullName: model.fullName ?? "Unknown",
                    isCompanyProfile: !model.isFromUser
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
                    .compactMap({ $0 }) //If no image, post hidden
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
                    publisherId: post.publisherId
                )
            })
            .eraseToAnyPublisher()
    }
    
    func getPostFromCompanyInfo(post: PostUserModel) -> AnyPublisher<PostModel, Never> {
        return useCases.companyDataUseCase.getCompanyInfo(uid: post.publisherId)
            .withUnretained(self)
            .flatMapLatest({ presenter, companyInfo in
                presenter.getPostImagePublisher(image: post.postImage!)
                    .compactMap({ $0 }) //If no image, post hidden
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
                    publisherId: post.publisherId
                )
            })
            .eraseToAnyPublisher()
    }
    
    func getLocationFromCompanyPost(postLocation: String?, companylocation: String?) -> String {
        if let location = postLocation, let coord = truncateCoordinates(location) {
            return "📍 \(coord)"
           
        } else {
            if let companyLocation = companylocation,
                let coord = truncateCoordinates(companyLocation) {
                return "📍 \(coord)"
            }
            return "📍 \(companylocation ?? "")"
        }
    }
    
    func truncateCoordinates(_ coordinateString: String) -> String? {
        let components = coordinateString.split(separator: ",")

        if let lat = Double(components[0]), let lon = Double(components[1]) {
            let truncatedLat = String(format: "%.4f", lat)
            let truncatedLon = String(format: "%.4f", lon)
            
            let truncatedCoordinates = "\(truncatedLat),\(truncatedLon)"
            
            return truncatedCoordinates// "40.41,-3.70"
        }
        
        return nil
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
