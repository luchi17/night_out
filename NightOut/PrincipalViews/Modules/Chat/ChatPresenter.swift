import SwiftUI
import Combine
import FirebaseDatabase

final class ChatViewModel: ObservableObject {
    @Published var messages: [MessageModel] = []
    @Published var otherUsername: String = ""
    @Published var newMessage: String = ""
    @Published var myUid: String = ""
    @Published var loading: Bool = true
    @Published var toast: ToastType?
    
    init(otherUsername: String, myUid: String) {
        self.otherUsername = otherUsername
        self.myUid = myUid
    }
}

protocol ChatPresenter {
    var viewModel: ChatViewModel { get }
    func transform(input: ChatPresenterImpl.ViewInputs)
}

final class ChatPresenterImpl: ChatPresenter {
    
    struct UseCases {
        let chatUseCase: ChatUseCase
        let followUseCase: FollowUseCase
        let userDataUseCase: UserDataUseCase
        let companyDataUseCase: CompanyDataUseCase
    }
    
    struct Actions {
        let goBack: VoidClosure
        let goToProfile: InputClosure<ProfileModel>
        let goToPrivateProfile: InputClosure<ProfileModel>
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let goBack: AnyPublisher<Void, Never>
        let sendMessage: AnyPublisher<Void, Never>
        let goToProfile: AnyPublisher<Void, Never>
    }
    
    var viewModel: ChatViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    private let firebaseService: FirebaseServiceProtocol
    
    let chat: Chat
    
    init(
        useCases: UseCases,
        actions: Actions,
        chat: Chat,
        firebaseService: FirebaseServiceProtocol = FirebaseServiceImpl()
    ) {
        self.actions = actions
        self.useCases = useCases
        self.chat = chat
        self.firebaseService = firebaseService
        
        viewModel = ChatViewModel(otherUsername: chat.username, myUid: FirebaseServiceImpl.shared.getCurrentUserUid() ?? "")
    }
    
    func transform(input: ChatPresenterImpl.ViewInputs) {
        input
            .viewDidLoad
            .withUnretained(self)
            .handleEvents(receiveRequest: { [weak self] request in
                self?.viewModel.loading = true
            })
            .flatMap({ presenter, _ -> AnyPublisher<[MessageModel], Never> in
                guard let myUid = self.firebaseService.getCurrentUserUid() else {
                    return Just([]).eraseToAnyPublisher()
                }
                return presenter.useCases.chatUseCase.getChats(
                    fromUid: myUid,
                    toUid: presenter.chat.otherUserUid
                )
                
            })
            .withUnretained(self)
            .sink { presenter, messages in
                presenter.viewModel.loading = false
                presenter.viewModel.messages = messages
            }
            .store(in: &cancellables)
        
        input
            .sendMessage
            .handleEvents(receiveRequest: { [weak self] request in
                self?.viewModel.loading = true
            })
            .withUnretained(self)
            .flatMap({ presenter, _ -> AnyPublisher<Bool, Never> in
                guard let myUid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just(false).eraseToAnyPublisher()
                }
        
                return presenter.useCases.chatUseCase.sendMessage(
                    currentUserUid: myUid,
                    toUid: presenter.chat.otherUserUid,
                    text: presenter.viewModel.newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            })
            .withUnretained(self)
            .sink { presenter, sent in
                presenter.viewModel.loading = false
                presenter.viewModel.newMessage = "" // Limpiar mensaje
                if !sent {
                    presenter.viewModel.toast = .custom(.init(title: "Error", description: "Error al cargar mensajes.", image: nil))
                }
            }
            .store(in: &cancellables)
        
        
        input
            .goBack
            .withUnretained(self)
            .sink { presenter, chat in
                presenter.actions.goBack()
            }
            .store(in: &cancellables)
        
        input
            .goToProfile
            .withUnretained(self)
            .flatMap({ presenter, _ -> AnyPublisher<FollowModel?, Never> in
                guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just(nil).eraseToAnyPublisher()
                }
                return presenter.useCases.followUseCase.fetchFollow(id: uid)
                    .eraseToAnyPublisher()
            })
            .withUnretained(self)
            .flatMap({ presenter, followModel -> AnyPublisher<(FollowModel?, ProfileModel), Never> in
                
                if UserDefaults.getCompanies()?.users.values.first(where: { $0.uid == presenter.chat.otherUserUid }) != nil {
                    presenter.useCases.companyDataUseCase.getCompanyInfo(uid: presenter.chat.otherUserUid)
                        .compactMap({ $0 })
                        .map { companyModel in
                            let profileModel = ProfileModel(
                                profileImageUrl: companyModel.imageUrl,
                                username: companyModel.username,
                                fullname: companyModel.fullname,
                                profileId: companyModel.uid,
                                isCompanyProfile: true,
                                isPrivateProfile: companyModel.profileType == .privateProfile
                            )
                            return (followModel, profileModel)
                        }
                        .eraseToAnyPublisher()
                } else {
                    presenter.useCases.userDataUseCase.getUserInfo(uid: presenter.chat.otherUserUid)
                        .compactMap({ $0 })
                        .map { userModel in
                            let profileModel = ProfileModel(
                                profileImageUrl: userModel.image,
                                username: userModel.username,
                                fullname: userModel.fullname,
                                profileId: userModel.uid,
                                isCompanyProfile: false,
                                isPrivateProfile: userModel.profileType == .privateProfile
                            )
                            return (followModel, profileModel)
                        }
                        .eraseToAnyPublisher()
                }
            })
            .withUnretained(self)
            .sink { presenter, data in
                let profileModel = data.1
                let follow = data.0
                
                let following = follow?.following?.keys.first(where: { $0 == presenter.chat.otherUserUid }) != nil
                
                if following {
                    presenter.actions.goToProfile(profileModel)
                } else {
                    if profileModel.isPrivateProfile {
                        presenter.actions.goToPrivateProfile(profileModel)
                    } else {
                        presenter.actions.goToProfile(profileModel)
                    }
                }
            }
            .store(in: &cancellables)
    }
}
