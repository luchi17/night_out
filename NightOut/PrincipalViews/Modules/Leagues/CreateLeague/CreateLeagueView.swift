
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
                
                topView
                
                if !viewModel.selectedFriends.isEmpty {
                    friendsView
                }
                
                if viewModel.isSearching {
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
                                }
                            }
                        }
                    }
                    .simultaneousGesture(DragGesture().onChanged { _ in
                        hideKeyboard() // Esconde el teclado cuando el usuario hace scroll
                    })
                }
                
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
                .padding()
            }
            
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
        .navigationBarBackButtonHidden()
        .onAppear {
            viewDidLoadPublisher.send()
        }
    }
    
    var textfieldOverlay: some View {
        HStack(spacing: 0) {
            Spacer()
            if isCancelVisible {
                Button(action: {
                    viewModel.searchText = ""
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    withAnimation {
                        isCancelVisible = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 24, height: 24)
                }
                .padding(.trailing, 8)
            }
        }
    }
    
    var friendsView: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(viewModel.selectedFriends, id: \.uid) { user in
                    HStack {
                        ZStack(alignment: .topTrailing) {
                            CircleImage(
                                imageUrl: user.imageUrl,
                                border: true
                            )
                            .frame(width: 80, height: 80)
                            .shadow(radius: 4)
                            
                            Button(action: {
                                removeFriendPublisher.send(user)
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
    }
    
    var topView: some View {
        
        VStack {
            TextField("", text: $viewModel.leagueName, prompt: Text("Nombre de la liga").foregroundColor(.white))
            textFieldStyle(PlainTextFieldStyle())
            .padding(.all, 8)
            .background(
                RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 1)
            )
            .foregroundColor(.yellow)
            .accentColor(.yellow)
            .autocorrectionDisabled()
            
            Text("Buscar amigos")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 0) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 24, height: 24)
                    .padding(.leading, 8)
                
                TextField("Buscar...", text: $viewModel.searchText, onEditingChanged: { isEditing in
                    isCancelVisible = isEditing || !viewModel.searchText.isEmpty
                })
                TextField("", text: $viewModel.leagueName, prompt: Text("Buscar...").foregroundColor(.white))
                textFieldStyle(PlainTextFieldStyle())
                .padding(.all, 8)
                .autocorrectionDisabled()
                .background(
                    RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 1)
                )
                .foregroundColor(.yellow)
                .accentColor(.yellow)
                .onChange(of: viewModel.searchText) {
                    searchUsersPublisher.send()
                }
                .overlay(
                    textfieldOverlay
                )
                
                Spacer()
            }
        }
        .padding()
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
    let imageUrl: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.uid == rhs.uid
    }
}
