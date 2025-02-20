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
                Color.black
                    .edgesIgnoringSafeArea(.all)
            } else {
                
                if viewModel.users.isEmpty && !viewModel.loadingUsers {
                    noUsersView
                    
                } else {
                    if viewModel.currentIndex < viewModel.users.count {
                        let user = $viewModel.users[viewModel.currentIndex]
                        
                        CardView(
                            user: user,
                            userLikedTapped: userLikedPublisher.send
                        )
                        .gesture(
                            DragGesture()
                                .onEnded { gesture in
                                    print(gesture.translation.width)
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
        .background(
            Color.black
        )
        .if(viewModel.loadingAssistance, transform: { view in
            Color.black
                .edgesIgnoringSafeArea(.all)
                .overlay {
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text("Validando asistencia...")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
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
            
            Text("¡Lo sentimos! No hay usuarios en Social NighOut para el club al que asistes.")
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
                .frame(height: 60)
                .foregroundStyle(.white)
            
            Text("!Gracias por ver todos los perfiles!")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
            
            Text("!Suerte con tus matches!")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
            
            Image("icono_cupido")
                .resizable()
                .scaledToFit()
                .frame(height: 60)
            
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



struct CardView: View {
    
    @Binding var user: TinderUser
    @State private var userLiked: Bool = false
    
    var userLikedTapped: InputClosure<String>
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            AsyncImage(url: URL(string: user.image)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                        } placeholder: {
                            Color.gray
                        }
                        .edgesIgnoringSafeArea([.bottom, .horizontal])
            
            VStack(alignment: .center, spacing: 20) {
                
                Spacer()
                
                buttonView
                
                Text(user.name)
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.7)))
                    .padding(.bottom, 35)
            }
            
        }
    }
    
    var buttonView: some View {
        Button(action: {
            userLiked = true
            userLikedTapped(user.uid)
        }) {
            Image(userLiked ? "heart_clicked" : "heart")
                .resizable()
                .frame(width: 70, height: 70)
                .foregroundColor(.red)
        }
        .padding(.bottom, 64)
    }
}


struct TinderLoadingUsersView: View {
    @Binding var isLoading: Bool
    var onAnimationEnd: () -> Void
    
    var body: some View {
        if isLoading {
            ZStack {
                // Fondo semitransparente
                Color.black.opacity(0.8)
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
            .onAppear {
                // Mantener la imagen visible 2 segundos antes de desaparecer
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        //                        isLoading = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onAnimationEnd() // Llamar la acción al terminar la animación
                    }
                }
            }
        }
    }
}
