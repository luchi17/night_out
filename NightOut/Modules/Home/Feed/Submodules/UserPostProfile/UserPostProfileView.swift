import SwiftUI
import Combine

struct UserPostProfileView: View {
    
    @State private var selectedImage: IdentifiableImage? = nil
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let goToFriendsListPublisher = PassthroughSubject<Void, Never>()
    private let goBackPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject var viewModel: UserPostProfileViewModel
    @ObservedObject var levelsViewModel: LevelsViewModel
    
    let presenter: UserPostProfilePresenter
    
    @State private var offset: CGFloat = 0
    
    init(
        presenter: UserPostProfilePresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        levelsViewModel = LevelsViewModel()
        bindViewModel()
    }
    
    var body: some View {
        ZStack {
            Color.blackColor
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                // Imagen de perfil
                CircleImage(
                    imageUrl: viewModel.profileImageUrl,
                    size: 100,
                    border: false
                )
                .padding(.top, 40)
                
                // Nombre y username
                ZStack(alignment: .trailing) {
                    Text(viewModel.fullname)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 8)
                    
                    if viewModel.isCompanyProfile {
                        Image("verified_profile_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .offset(x: 60)
                    }
                }
                
                Text(viewModel.username)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.top, 0)
                
                // Contadores
                HStack(spacing: 8) {
                    if !viewModel.isCompanyProfile {
                        CounterView(count: viewModel.discosCount, label: "Discotecas")
                        CounterView(count: viewModel.copasCount, label: "Copas")
                    } else {
                        CounterView(count: viewModel.followersCount, label: "Seguidores")
                            .onTapGesture {
                                goToFriendsListPublisher.send()
                            }
                    }
                }
                .padding(.vertical, 16)
                
                if viewModel.isCompanyProfile {
                    ImagesGrid(
                        images: $viewModel.images,
                        selectedImage: $selectedImage
                    )
                }
                
                if !viewModel.isCompanyProfile && !levelsViewModel.levelList.isEmpty {
                    RookieLevelsView(viewModel: levelsViewModel)
                }
                
                Spacer()
            }
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
        .fullScreenCover(item: $selectedImage) { imageName in
            FullScreenImageView(imageName: imageName, onClose: {
                selectedImage = nil
            })
        }
        .onAppear {
            viewDidLoadPublisher.send()
            levelsViewModel.loadUserLevels(profileId: viewModel.profileId)
        }
    }
}

private extension UserPostProfileView {
    func bindViewModel() {
        let input = UserPostProfilePresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            goToFriendsList: goToFriendsListPublisher.eraseToAnyPublisher(),
            goBack: goBackPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}


struct CounterView: View {
    var count: String
    var label: String
    
    var body: some View {
        VStack {
            Text(count)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: 100, height: 80)
        .background(Color.grayColor)
        .cornerRadius(10)
        .padding(.horizontal, 8)
    }
}
