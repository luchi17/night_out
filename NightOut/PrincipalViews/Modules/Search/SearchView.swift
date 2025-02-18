
import SwiftUI
import Combine

struct SearchView: View {
    
    @State private var isCancelVisible: Bool = false
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let searchPublisher = PassthroughSubject<Void, Never>()
    private let goToProfilePublisher = PassthroughSubject<ProfileModel, Never>()
    
    @ObservedObject var viewModel: SearchViewModel
    let presenter: SearchPresenter
    
    init(
        presenter: SearchPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        VStack {
            // Título
            Text("Buscar amigos")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 60)
            
            Spacer().frame(height: 10)
            
            // Barra de búsqueda
            HStack(spacing: 0) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 24, height: 24)
                    .padding(.leading, 8)
                
                TextField("Search", text: $viewModel.searchText, onEditingChanged: { isEditing in
                    isCancelVisible = isEditing || !viewModel.searchText.isEmpty
                })
                .padding(8)
                .textFieldStyle(PlainTextFieldStyle())
                .autocorrectionDisabled()
                .foregroundColor(.white)
                .overlay(
                    textfieldOverlay
                )
                
                Spacer()
            }
            .frame(height: 40)
            .background(Color.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            .shadow(radius: 5)
            .padding(.horizontal, 12)
            
            // Resultados de búsqueda
            if !viewModel.searchResults.isEmpty {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(viewModel.searchResults, id: \.self) { user in
                            ListUserSubView(user: user)
                                .onTapGesture {
                                    hideKeyboard()
                                    goToProfilePublisher.send(user)
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
        }
        .background(
            Color.black
                .edgesIgnoringSafeArea(.top)
        )
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
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private extension SearchView {
    func bindViewModel() {
        let input = SearchPresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            search: searchPublisher.eraseToAnyPublisher(),
            goToProfile: goToProfilePublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}

struct ListUserSubView: View {
    
    var user: ProfileModel
    
    var body: some View {
        
        HStack(spacing: 10) {
            
            if let profileImage = user.profileImageUrl {
                KingFisherImage(url: URL(string: profileImage))
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .padding(.leading, 5)
                
            } else {
                Image("profile")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .padding(.leading, 5)
            }
            
            Text(user.username ?? "Nombre desconocido")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

