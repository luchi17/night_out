import SwiftUI
import Combine
import CoreLocation

#warning("Add cache of companies with UserDefaults.getCompanies() ")

final class FeedViewModel: ObservableObject {
    
    @Published var posts: [PostModel] = []
    
    @Published var loading: Bool = false
    @Published var toastError: ToastType?
    @Published var headerError: ErrorState?
    
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
            .flatMap({ presenter, _ -> AnyPublisher<FollowModel?, Never> in
                presenter.useCases.postsUseCase.fetchFollow()
            })
            .handleEvents(receiveRequest: { [weak self] _ in
                self?.viewModel.loading = true
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
        
        input
            .showCommentsView
            .map { model in
                PostCommentsInfo(
                    postId: model.uid,
                    postImageUrl: model.postImage ?? "",
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
            .map({ presenter, userInfo in
                return PostModel(
                    profileImageUrl: userInfo?.image,
                    postImage: post.postImage,
                    description: post.description,
                    location: presenter.getClubNameByPostLocation(postLocation: post.location),
                    username: userInfo?.username,
                    publisherName: userInfo?.fullname,
                    uid: post.postID,
                    isFromUser: post.isFromUser ?? true,
                    publisherId: post.publisherId
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
                    publisherName: companyInfo?.fullname,
                    uid: post.postID,
                    isFromUser: post.isFromUser ?? false,
                    publisherId: post.publisherId
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

//
//    private fun openUserProfile(publisherID: String, username: String, ) {
//        CoroutineScope(Dispatchers.Main).launch {
//            // Obtener el número de seguidores de manera asíncrona
//            val followersCount = getUserFollowersCount(publisherID)
//
//            // Crear el fragmento y pasarle los argumentos
//            val fragment = ViewUserProfile().apply {
//                arguments = Bundle().apply {
//                    putString("publisherID", publisherID)
//                    putInt("followersCount", followersCount)
//                    putString("profileImageUrl", profileImageUrl)  // Usar la variable global
//                    putString("username", username)  // Pasar el nombre de usuario
//
//                }
//            }
//
//            // Reemplazar el fragmento actual con el nuevo
//            (context as FragmentActivity).supportFragmentManager.beginTransaction()
//                .replace(R.id.fragment_container, fragment)
//                .addToBackStack(null)
//                .commit()
//        }
//    }
//

//suspend fun getUserFollowersCount(publisherID: String): Int {
//        return try {
//            // Referencia al nodo 'Follow' donde está el nodo 'Followers' para el publisherID
//            val followersSnapshot = FirebaseDatabase.getInstance()
//                .getReference("Follow")
//                .child(publisherID)
//                .child("Followers")
//                .get()
//                .await()
//            followersSnapshot.childrenCount.toInt()
//        } catch (e: Exception) {
//            // Manejo de excepciones, retornando 0 en caso de error
//            0
//        }
//    }
