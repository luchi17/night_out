
import SwiftUI
import Combine

struct CreateLeagueView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let searchUsersPublisher = PassthroughSubject<Void, Never>()
    private let createLeaguePublisher = PassthroughSubject<Void, Never>()
    private let removeFriendPublisher = PassthroughSubject<CreateLeagueUser, Never>()
    private let addFriendPublisher = PassthroughSubject<CreateLeagueUser, Never>()
    
    
    @State private var isCancelVisible: Bool = false
    
    @ObservedObject var viewModel: CreateLeagueViewModel
    let presenter: CreateLeaguePresenter
    
    init(
        presenter: CreateLeaguePresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        ZStack {
            Color.blackColor.edgesIgnoringSafeArea(.all)
            
            VStack {
                
                TextField("", text: $viewModel.leagueName, prompt: Text("Nombre de la liga").foregroundColor(.white))
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.all, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white, lineWidth: 1)
                            .fill(Color.white.opacity(0.5))
                    )
                    .foregroundColor(.white)
                    .accentColor(.white)
                    .autocorrectionDisabled()
                
                if !viewModel.selectedFriends.isEmpty {
                    friendsView
                }
                
                searchView
               
                if !viewModel.searchResults.isEmpty {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(viewModel.searchResults, id: \.uid) { user in
                                Button(action: {
                                    hideKeyboard()
                                    addFriendPublisher.send(user)
                                }) {
                                    Text(user.username)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                    .simultaneousGesture(DragGesture().onChanged { _ in
                        hideKeyboard() // Esconde el teclado cuando el usuario hace scroll
                    })
                } else {
                    Spacer() // Espaciador para centrar el contenido si no hay resultados
                }
                
                Spacer()
                
                Button(action: {
                    createLeaguePublisher.send()
                }) {
                    Text("Crear Liga".uppercased())
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.grayColor)
                        .cornerRadius(25)
                        .shadow(radius: 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top)
        }
        .showToast(
            error: (
                type: viewModel.toast,
                showCloseButton: false,
                onDismiss: {
                    viewModel.toast = nil
                }
            ),
            isIdle: viewModel.loading
        )
        .onAppear {
            viewDidLoadPublisher.send()
        }
    }
    
    var friendsView: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(viewModel.selectedFriends, id: \.uid) { user in
                    ZStack(alignment: .topTrailing) {
                        CircleImage(
                            imageUrl: user.imageUrl,
                            border: false
                        )
                        .frame(width: 80, height: 80)
                        
                        if user.uid != FirebaseServiceImpl.shared.getCurrentUserUid() {
                            Button(action: {
                                removeFriendPublisher.send(user)
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                            }
                            .offset(x: -3)
                        }
                    }
                }
            }
        }
    }
    
    var searchView: some View {
        VStack {
            Text("Buscar amigos")
                .font(.system(size: 18))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
            
            HStack(spacing: 0) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 24, height: 24)
                
                TextField("", text: $viewModel.searchText, prompt: Text("Buscar...").foregroundColor(.white))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.all, 8)
                .background(.clear)
                .autocorrectionDisabled()
                .foregroundColor(.white)
                .accentColor(.white)
                
                Spacer()
            }
        }
    }
}

private extension CreateLeagueView {
    func bindViewModel() {
        let input = CreateLeaguePresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            createLeague: createLeaguePublisher.eraseToAnyPublisher(),
            removeFriend: removeFriendPublisher.eraseToAnyPublisher(),
            searchUsers: searchUsersPublisher.eraseToAnyPublisher(),
            addFriend: addFriendPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct CreateLeagueUser: Codable, Equatable {
    let uid: String
    let username: String
    let imageUrl: String?
    
    init(uid: String, username: String, imageUrl: String?) {
        self.uid = uid
        self.username = username
        self.imageUrl = imageUrl
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }
    
    static func == (lhs: CreateLeagueUser, rhs: CreateLeagueUser) -> Bool {
        return lhs.uid == rhs.uid
    }
}
