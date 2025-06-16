
import SwiftUI
import Combine

struct SearchView: View {
    
    @State private var isCancelVisible: Bool = false
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let searchPublisher = PassthroughSubject<Void, Never>()
    private let goToProfilePublisher = PassthroughSubject<ProfileModel, Never>()
    
    @FocusState private var isTextFieldFocused: Bool
    
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
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .padding(.leading, 8)
                
                TextField("", text: $viewModel.searchText, prompt: Text("Buscar...").foregroundColor(.white))
                    .padding(8)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocorrectionDisabled()
                    .foregroundColor(.white)
                    .accentColor(.white)
                    .overlay(
                        textfieldOverlay
                    )
                    .focused($isTextFieldFocused)
                    .onChange(of: isTextFieldFocused) { oldValue, newValue in
                        isCancelVisible = newValue || !viewModel.searchText.isEmpty
                    }
                    .onChange(of: viewModel.searchText) { oldValue, newValue in
                        isCancelVisible = isTextFieldFocused || !newValue.isEmpty
                    }
                
                Spacer()
            }
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.grayColor.opacity(0.5))
                    .stroke(Color.white, lineWidth: 2)
            )
            .shadow(radius: 5)
            .padding(.horizontal, 12)
            
            // Resultados de búsqueda
            if !viewModel.searchResults.isEmpty {
                ScrollView {
                    VStack(spacing: 22) {
                        ForEach(viewModel.searchResults, id: \.self) { user in
                            
                            Button(action: {
                                // Navegar al perfil del usuario
                                hideKeyboard()
                                goToProfilePublisher.send(user)
                            }) {
                                ListUserSubView(user: user)
                            }
                            
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .simultaneousGesture(DragGesture().onChanged { _ in
                    hideKeyboard() // Esconde el teclado cuando el usuario hace scroll
                })
                
            } else {
                Spacer() // Espaciador para centrar el contenido si no hay resultados
            }
            
            Spacer()
        }
        .onTapGesture {
            // Aseguramos que el tap en toda la vista también puede ocultar el teclado
            if isTextFieldFocused {
                isTextFieldFocused = false
                hideKeyboard()
            }
        }
        .background(
            Color.blackColor
                .edgesIgnoringSafeArea(.top)
                .onTapGesture(perform: {
                    if isTextFieldFocused {
                        isTextFieldFocused = false
                        hideKeyboard()
                    }
                })
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
            
            CircleImage(
                imageUrl: user.profileImageUrl,
                size: 50,
                border: false
            )
            .padding(.leading, 5)
            
            VStack(spacing: 5) {
                Text(user.fullname?.lowercased() ?? "Nombre desconocido")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(user.username?.lowercased() ?? "Nombre desconocido")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
            }
            
            Spacer()
        }
    }
}

