import SwiftUI
import Combine

struct TinderView: View {
    
    @State private var currentIndex: Int = 0
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
            if showInitSheet {
                Color.black
                    .edgesIgnoringSafeArea(.all)
            } else {
                
                if viewModel.users.isEmpty {
                    noUsersView
                    
                } else {
                    if currentIndex < viewModel.users.count {
                        let user = $viewModel.users[currentIndex]
                        
                        CardView(user: user)
                            .gesture(
                                DragGesture()
                                    .onEnded { gesture in
                                        if gesture.translation.width > 100 {
                                            // Swipe Right (Next User)
                                            if currentIndex < viewModel.users.count - 1 {
                                                currentIndex += 1
                                            }
                                        } else if gesture.translation.width < -100 {
                                            // Swipe Left (Previous User)
                                            if currentIndex > 0 {
                                                currentIndex -= 1
                                            }
                                        }
                                    }
                            )
                            
                    } else {
                        endView
                    }
                }
            }
            
        }
        //        .padding(.horizontal, 20)
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
        .sheet(isPresented: $showInitSheet) {
            TinderInitView(
                openUsers: {
                    showInitSheet = false
                    initTinderTappedPublisher.send()
//                    viewDidLoadPublisher.send()
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
                dismissButton: .default(Text("ACEPTAR"))
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
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            if let image = user.image {
                KingFisherImage(url: URL(string: image))
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            } else {
                Image("profile")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack {
                
                Spacer()
                
                Text(user.name)
                    .font(.system(size: 16))
                    .bold()
                    .foregroundColor(.white)
                
                HStack {
                    Spacer()
                    Button(action: {
                        user.isLiked.toggle()
                    }) {
                        Image(user.isLiked ? "heart_clicked" : "heart")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(user.isLiked ? .red : .white)
                            .padding()
                    }
                }
            }
        }
        .padding()
        .background(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]), startPoint: .bottom, endPoint: .top))
    }
}
