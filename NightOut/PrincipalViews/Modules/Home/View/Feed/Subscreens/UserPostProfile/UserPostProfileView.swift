import SwiftUI
import Combine

struct UserPostProfileView: View {
    
    @State private var selectedImage: IdentifiableImage? = nil
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let goToFriendsListPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject var viewModel: UserPostProfileViewModel
    @ObservedObject var levelsViewModel: LevelsViewModel
    
    let presenter: UserPostProfilePresenter
    
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
            Color.black
                .edgesIgnoringSafeArea(.all)
            VStack {
                // Imagen de perfil
                if let profileImageUrl = viewModel.profileImageUrl {
                    KingFisherImage(url: URL(string: profileImageUrl))
                        .centerCropped(width: 100, height: 100, placeholder: {
                            ProgressView()
                        })
                        .clipShape(Circle())
                        .padding(.top, 40)
                } else {
                    Image("profile")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .padding(.top, 40)
                }
                
                // Nombre y username
                HStack(spacing: 10) {
                    Text(viewModel.fullname)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 8)
                    if viewModel.isCompanyProfile {
                        Image("verified_profile_icon") // Ícono de ejemplo
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    }
                }
                
                Text(viewModel.username)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                
                // Contadores
                HStack(spacing: 8) {
                    CounterView(count: viewModel.followersCount, label: "Seguidores")
                        .onTapGesture {
                            goToFriendsListPublisher.send()
                        }
                    if !viewModel.isCompanyProfile {
                        CounterView(count: viewModel.discosCount, label: "Discotecas")
                        CounterView(count: viewModel.copasCount, label: "Copas")
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
        .fullScreenCover(item: $selectedImage) { imageName in
            FullScreenImageView(imageName: imageName, onClose: {
                selectedImage = nil
            })
        }
        .onAppear {
            viewDidLoadPublisher.send()
            levelsViewModel.loadUserLevels()
        }
    }
}

private extension UserPostProfileView {
    func bindViewModel() {
        let input = UserPostProfilePresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            goToFriendsList: goToFriendsListPublisher.eraseToAnyPublisher()
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
        .background(Color.gray)
        .cornerRadius(10)
        .padding(.horizontal, 8)
    }
}
