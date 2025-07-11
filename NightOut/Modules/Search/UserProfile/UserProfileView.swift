import SwiftUI
import Combine

//Profile3

struct UserProfileView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let followPublisher = PassthroughSubject<Void, Never>()
    private let whiskyTappedPublisher = PassthroughSubject<Void, Never>()
    private let goBackPublisher = PassthroughSubject<Void, Never>()
    private let userSelectedPublisher = PassthroughSubject<UserGoingCellModel, Never>()
    private let openConfigPublisher = PassthroughSubject<Void, Never>()
    private let openDiscoPublisher = PassthroughSubject<Void, Never>()
    
    @State private var selectedImage: IdentifiableImage? = nil
    @State private var offset: CGFloat = 0
    
    @ObservedObject var viewModel: UserProfileViewModel
    let presenter: UserProfilePresenter
    
    init(
        presenter: UserProfilePresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        GeometryReader { geometry in
            
            ScrollView(.vertical, showsIndicators: false) {
                
                VStack(spacing: 0) {
                    
                    ZStack(alignment: .bottomLeading) {
                        if let profileImage = viewModel.profileImageUrl {
                            AsyncImage(url: URL(string: profileImage)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geometry.size.width, height: 350)
                                    .clipped()
                            } placeholder: {
                                Color.grayColor
                                    .frame(width: geometry.size.width, height: 350)
                            }
                        } else {
                            Image("profile")
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: 350)
                                .clipped()
                        }
                        
                        overlay
                    }
                    
                    followButton
                    
                    if viewModel.isCompanyProfile {
                        clubContent
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .offset(x: offset)
        .gesture(
            DragGesture()
            
                .onChanged { gesture in
                    if gesture.translation.width > 0 {
                        offset = gesture.translation.width
                    }
                }
                .onEnded { gesture in
                    if gesture.translation.width > 50 { // Detecta si el usuario arrastró lo suficiente hacia la derecha
                        goBackPublisher.send()
                    } else {
                        withAnimation {
                            offset = 0
                        }
                    }
                }
        )
        .background(Color.blackColor)
        .fullScreenCover(item: $selectedImage) { imageName in
            FullScreenImageView(imageName: imageName, onClose: {
                selectedImage = nil
            })
        }
        .showCustomNavBar(
            title: viewModel.username,
            goBack: goBackPublisher.send,
            image: {
                Image("verified_profile_icon") // Ícono de ejemplo
                    .resizable()
                    .scaledToFill()
                    .frame(width: viewModel.isCompanyProfile ? 45 : 0, height: viewModel.isCompanyProfile ? 45 : 0) // Ajusta el tamaño
                    .clipShape(Circle())
            }
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
        .edgesIgnoringSafeArea(.bottom)
        .alert(isPresented: $viewModel.showGenderAlert) {
            Alert(
                title: Text("Género")
                    .foregroundColor(.white),
                message: Text("Debes seleccionar el género en los ajustes de tu perfil.")
                    .foregroundColor(.white),
                dismissButton: .default(Text("Abrir configuración"), action: {
                    openConfigPublisher.send()
                })
            )
        }
        .onAppear {
            viewDidLoadPublisher.send()
        }
    }
    
    var overlay: some View {
        HStack {
            Text(viewModel.fullname)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            
            if viewModel.isCompanyProfile && FirebaseServiceImpl.shared.getImUser() {
                Button(action: {
                    openDiscoPublisher.send()
                }) {
                    Image("ticket")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 45, height: 45)
                        .foregroundStyle(.black)
                }
                
                Spacer()
                
                Button(action: {
                    whiskyTappedPublisher.send()
                }) {
                    viewModel.imGoingToClub.whiskyImage
                }
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    //In case showing a club profile
    var clubContent: some View {
        VStack {
            if viewModel.followingPeopleGoingToClub.isEmpty {
                Text("Todavía no tienes amigos que vayan al club")
                    .font(.system(size: 16, weight: .medium))
                    .padding(.top, 10)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .frame(alignment: .leading)
            } else {
                Text("Amigos que asisten al club")
                    .font(.system(size: 18, weight: .bold))
                    .padding(.top, 10)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                UsersGoingClubSubview(
                    users: $viewModel.followingPeopleGoingToClub,
                    onUserSelected: userSelectedPublisher.send
                )
            }
            
            if viewModel.usersGoingToClub.isEmpty {
                Text("Todavía no hay usuarios que asistan al club")
                    .font(.system(size: 16, weight: .medium))
                    .padding(.top, 10)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
            } else {
                Text("Usuarios que asisten al club")
                    .font(.system(size: 18, weight: .bold))
                    .padding(.top, 10)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                UsersGoingClubSubview(
                    users: $viewModel.usersGoingToClub,
                    onUserSelected: userSelectedPublisher.send
                )
            }
            
            ImagesGrid(
                images: $viewModel.images,
                selectedImage: $selectedImage
            )
        }
        .padding(.top, 20)
    }
    
    var followButton: some View {
        Button(action: {
            followPublisher.send()
        }) {
            Text(viewModel.followButtonType?.title ?? "")
                .font(.system(size: 18))
                .padding()
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                .foregroundColor(.blackColor)
                .padding(.horizontal, 10)
                .padding(.top, 15)
        }
        .padding(.top, 16)
    }
}

private extension UserProfileView {
    func bindViewModel() {
        let input = UserProfilePresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            followProfile: followPublisher.eraseToAnyPublisher(),
            goToClub: whiskyTappedPublisher.eraseToAnyPublisher(),
            goBack: goBackPublisher.eraseToAnyPublisher(),
            onUserSelected: userSelectedPublisher.eraseToAnyPublisher(),
            openConfig: openConfigPublisher.eraseToAnyPublisher(),
            openDiscoDetail: openDiscoPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
