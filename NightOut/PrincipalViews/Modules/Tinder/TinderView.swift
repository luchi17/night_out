import SwiftUI
import Combine

struct TinderView: View {
    
    @State private var showInitSheet: Bool = true
    
    private let initTinderTappedPublisher = PassthroughSubject<Void, Never>()
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let userLikedPublisher = PassthroughSubject<String, Never>()
    private let goBackPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject var viewModel: TinderViewModel
    let presenter: TinderPresenter
    
    init(
        presenter: TinderPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        ZStack {
            if showInitSheet || viewModel.showAlert {
                Color.blackColor
                    .edgesIgnoringSafeArea(.all)
            } else {
                
                if !viewModel.users.isEmpty {
                    if viewModel.currentIndex < viewModel.users.count {
                        let user = $viewModel.users[viewModel.currentIndex]
                        
                        TinderCardView(
                            user: user,
                            userLikedTapped: userLikedPublisher.send
                        )
                        .gesture(
                            DragGesture()
                                .onEnded { gesture in
                                    if gesture.translation.width < -100 {
                                        // Swipe Right (Next User)
                                        viewModel.currentIndex += 1
                                    } else if gesture.translation.width > 100 {
                                        // Swipe Left (Previous User)
                                        if viewModel.currentIndex > 0 {
                                            viewModel.currentIndex -= 1
                                        }
                                    }
                                }
                        )
                        
                    } else {
                        endView
                            .gesture(
                                DragGesture()
                                    .onEnded { gesture in
                                        if gesture.translation.width > 100 {
                                            // Swipe Left (Previous User)
                                            viewModel.currentIndex -= 1
                                        }
                                    }
                            )
                    }
                }
            }
        }
        .if(viewModel.showNoUsersForClub, transform: { view in
            Color.blackColor
                .edgesIgnoringSafeArea(.all)
                .overlay {
                    noUsersView
                }
        })
        .if(viewModel.showEndView, transform: { view in
            Color.blackColor
                .edgesIgnoringSafeArea(.all)
                .overlay {
                    endView
                }
        })
        .if(viewModel.loadingUsers, transform: { view in
            TinderLoadingUsersView(
                isLoading: $viewModel.loadingUsers) {}
        })
        .sheet(isPresented: $showInitSheet) {
            TinderInitView(
                showUsers: {
                    showInitSheet = false
                    initTinderTappedPublisher.send()
                },
                cancel: {
                    showInitSheet = false
                    goBackPublisher.send()
                }
            )
            .presentationDetents([.large])
            .interactiveDismissDisabled(true)
            .presentationDragIndicator(.hidden)
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle)
                    .foregroundColor(.white),
                message: Text(viewModel.alertMessage)
                    .foregroundColor(.white),
                dismissButton: .default(Text(viewModel.alertButtonText), action: {
                    viewModel.showAlert = false
                    goBackPublisher.send()
                })
            )
        }
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            showInitSheet = true
        }
    }
    
    var noUsersView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image("icon_sadface")
                .resizable()
                .scaledToFit()
                .frame(height: 60)
                .foregroundStyle(.white)
            
            Text("¡Lo sentimos! No hay usuarios en Social NighOut para el club al que asistes hoy.")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
            
            Spacer()
        }
    }
    
    var endView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image("tick_icon")
                .resizable()
                .scaledToFit()
                .frame(height: 70)
                .foregroundStyle(.white)
            
            Text("!Gracias por ver todos los perfiles!")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
            
            Text("!Suerte con tus matches!")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
            
            Image("icono_cupido")
                .resizable()
                .scaledToFit()
                .frame(height: 70)
            
            Spacer()
        }
    }
}

private extension TinderView {
    func bindViewModel() {
        let input = TinderPresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            userLiked: userLikedPublisher.eraseToAnyPublisher(),
            goBack: goBackPublisher.eraseToAnyPublisher(),
            initTinder: initTinderTappedPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}

struct TinderLoadingUsersView: View {
    @Binding var isLoading: Bool
    var onAnimationEnd: () -> Void
    
    var body: some View {
        if isLoading {
            ZStack {
                // Fondo semitransparente
                Color.blackColor.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                
                // Imagen de carga
                Image("carga_social_nbg")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200) // Ajusta el tamaño según necesites
                    .opacity(isLoading ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: isLoading)
            }
            .transition(.opacity)
        }
    }
}
