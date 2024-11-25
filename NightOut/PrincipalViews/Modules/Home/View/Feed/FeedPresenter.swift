import SwiftUI
import Combine
import CoreLocation

#warning("Add cache of companies with UserDefaults.getCompanies() ")

final class FeedViewModel: ObservableObject {
    
    @Published var posts: [PostModel] = []
    
    @Published var loading: Bool = false
    @Published var toastError: ToastType?
    
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
        let userDataUseCase: UserDataUseCase
        let companyDataUseCase: CompanyDataUseCase
    }
    
    struct Actions {
        let onOpenMaps: InputClosure<(Double, Double)>
        let onOpenAppleMaps: InputClosure<(CLLocationCoordinate2D, String?)>
        let onShowUserProfile: InputClosure<UserModel>
        let onShowCompanyProfile: InputClosure<CompanyModel>
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let openMaps: AnyPublisher<PostModel, Never>
        let openAppleMaps: AnyPublisher<PostModel, Never>
        let showUserOrCompanyProfile: AnyPublisher<PostModel, Never>
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
        
        viewModel.loading = true
        
        let userPostsPublisher = input
            .viewDidLoad
            .withUnretained(self)
            .flatMap({ presenter, _ -> AnyPublisher<FollowModel?, Never> in
                presenter.useCases.postsUseCase.fetchFollow()
            })
            .withUnretained(self)
            .flatMap({ presenter, followModel -> AnyPublisher<[PostUserModel], Never> in
                presenter.useCases.postsUseCase.fetchPosts()
                    .map { posts in
                        let matchingPosts = posts.filter { post in
                            followModel?.following?.keys.contains(post.value.publisherId) ?? false
                        }
                        return Array(matchingPosts.values)
                    }
                    .eraseToAnyPublisher()
            })
            .withUnretained(self)
            .eraseToAnyPublisher()
        
        
        userPostsPublisher
            .flatMap({ presenter, userPosts ->  AnyPublisher<[PostModel], Never> in
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
            .sink { presenter, uid in
                //TODO
            }
            .store(in: &cancellables)
        
    }
    
   
}

private extension FeedPresenterImpl {
    func getPostFromUserInfo(post: PostUserModel) -> AnyPublisher<PostModel, Never> {
        return useCases.userDataUseCase.getUserInfo(uid: post.publisherId)
            .withUnretained(self)
            .map({ presenter, userInfo in
                return PostModel(
                    profileImageUrl: userInfo?.image,
                    postImage: post.postImage,
                    description: post.description,
                    location: presenter.getClubNameByPostLocation(postLocation: post.location),
                    username: userInfo?.username,
                    publisher: userInfo?.fullname,
                    uid: post.publisherId,
                    isFromUser: post.isFromUser ?? true
                )
            })
            .eraseToAnyPublisher()
    }
    
    func getPostFromCompanyInfo(post: PostUserModel) -> AnyPublisher<PostModel, Never> {
        useCases.companyDataUseCase.getCompanyInfo(uid: post.publisherId)
            .withUnretained(self)
            .map({ presenter, companyInfo in
                return PostModel(
                    profileImageUrl: companyInfo?.imageUrl,
                    postImage: post.postImage,
                    description: post.description,
                    location: presenter.getLocationFromCompanyPost(postLocation: post.location, companylocation: companyInfo?.location),
                    username: companyInfo?.username,
                    publisher: companyInfo?.fullname,
                    uid: post.publisherId,
                    isFromUser: post.isFromUser ?? false
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
    
    
    
}
