import SwiftUI
import Combine
import CoreLocation
import FirebaseMessaging
import FirebaseAuth
import FirebaseDatabase


final class FeedViewModel: ObservableObject {
    
    @Published var posts: [PostModel] = []
    
    @Published var loading: Bool = false
    @Published var toastError: ToastType?
    @Published var headerError: ErrorState?
    @Published var followersCount: Int = 0
    @Published var followModel: FollowModel?
    @Published var userModel: UserModel?
    @Published var companyModel: CompanyModel?
    
    @Published var showDiscoverEvents: Bool = false
    
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
        let onShowPostComments: InputClosure<PostCommentsInfo>
        let onOpenCalendar: VoidClosure
        
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
        let openCalendar: AnyPublisher<Void, Never>
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
        
        input
            .viewDidLoad
            .withUnretained(self)
            .flatMap { presenter, _ in //Get user info and save it when feed appears
                presenter.getUserInfo()
            }
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.observeFollowInRealTime()
            }
            .store(in: &cancellables)
        
        outinput
            .reload
            .withUnretained(self)
            .flatMap { presenter, _ in
                //Get user info and save it when feed appears
                presenter.getUserInfo()
            }
            .withUnretained(self)
            .sink { presenter, _ in
                
                // update Posts After Editing User
                guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
                
                presenter.viewModel.posts = presenter.viewModel.posts.map({ postModel in
                    
                    if postModel.publisherId == uid {
                        
                        var newPostModel = postModel
                        
                        if postModel.isFromUser {
                            newPostModel.fullName = presenter.viewModel.userModel?.fullname
                            newPostModel.username = presenter.viewModel.userModel?.username
                            newPostModel.profileImageUrl = presenter.viewModel.userModel?.image
                            
                            return newPostModel
                        } else {
                            newPostModel.fullName = presenter.viewModel.companyModel?.fullname
                            newPostModel.username = presenter.viewModel.companyModel?.username
                            newPostModel.profileImageUrl = presenter.viewModel.companyModel?.imageUrl
                            
                            return newPostModel
                        }
                       
                    } else {
                        return postModel
                    }
                })
            }
            .store(in: &cancellables)
    }
    
    func listenToInput(input: FeedPresenterImpl.ViewInputs) {
        
        input
            .openCalendar
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.actions.onOpenCalendar()
            }
            .store(in: &cancellables)
        
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
                    isCompanyProfile: (!model.isFromUser && !(model.location?.isEmpty ?? true))
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
    
    func getUserInfo() -> AnyPublisher<Void, Never> {
        
        guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            return Just(()).eraseToAnyPublisher()
        }
        if FirebaseServiceImpl.shared.getImUser() {
            return useCases.userDataUseCase.getUserInfo(uid: uid)
                .handleEvents(receiveOutput: { [weak self] output in
                    self?.viewModel.userModel = output
                })
                .map({ _ in })
                .eraseToAnyPublisher()
        } else {
            return useCases.companyDataUseCase.getCompanyInfo(uid: uid)
                .handleEvents(receiveOutput: { [weak self] output in
                    self?.viewModel.companyModel = output
                })
                .map({ _ in })
                .eraseToAnyPublisher()
        }
    }
    
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
                    publisherId: post.publisherId,
                    timestamp: post.timestamp ?? 0
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
                    publisherId: post.publisherId,
                    timestamp: post.timestamp ?? 0
                )
            })
            .eraseToAnyPublisher()
    }
    
    func observeFollowInRealTime() {
        guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            return
        }
        
        useCases.followUseCase.observeFollow(id: uid)
            .handleEvents(receiveOutput: { [weak self] output in
                self?.viewModel.followModel = output
            })
            .map({ _ in })
            .withUnretained(self)
            .flatMap { presenter, _ in
                presenter.getPosts()
            }.withUnretained(self)
            .sink { presenter, posts in
                presenter.viewModel.loading = false
                if posts.isEmpty {
                    presenter.viewModel.showDiscoverEvents = true
                } else {
                    presenter.viewModel.showDiscoverEvents = false
                    
                    //Update view only when posts have changed
                    if posts.count != presenter.viewModel.posts.count {
                        presenter.viewModel.posts = posts.sorted(by: { ($0.timestamp) > ($1.timestamp) })
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func getPosts() -> AnyPublisher<[PostModel], Never> {
        return useCases.postsUseCase.fetchPosts()
            .merge(with: useCases.postsUseCase.observePosts().compactMap({ $0 }))
            .compactMap({ $0 })
            .map { posts -> [PostUserModel] in
                return posts.values.filter { post in
                    let isFollowing = self.viewModel.followModel?.following?.keys.contains(post.publisherId) ?? false
                    let isOwnPost = post.publisherId == FirebaseServiceImpl.shared.getCurrentUserUid()
                    return isFollowing || isOwnPost
                }
            }
            .replaceError(with: [])
            .withUnretained(self)
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
            .removeDuplicates { oldPosts, newPosts in
                return Set(oldPosts) == Set(newPosts)
            }
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
        
        guard components.count == 2,
              let latString = components.first, let lonString = components.last,
              let lat = Double(latString), let lon = Double(lonString) else {
            return nil
        }
        
        let truncatedLat = String(format: "%.4f", lat)
        let truncatedLon = String(format: "%.4f", lon)
        
        return "\(truncatedLat),\(truncatedLon)" // "40.4123,-3.7038"
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
