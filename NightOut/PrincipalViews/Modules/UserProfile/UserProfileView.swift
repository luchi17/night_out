import SwiftUI
import Combine

//Profile3

struct UserProfileView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let followPublisher = PassthroughSubject<Void, Never>()
    private let whiskyTappedPublisher = PassthroughSubject<Void, Never>()
    private let goBackPublisher = PassthroughSubject<Void, Never>()
    private let userSelectedPublisher = PassthroughSubject<UserGoingCellModel, Never>()
    
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
        Color.black
            .overlay(
                VStack(spacing: 0) {

                    profileInfo
                    
                    followButton
                    
                    if viewModel.isCompanyProfile {
                        clubContent
                    }
                    
                    Spacer()
                }
            )
            .showCustomNavBar(
                title: viewModel.username,
                goBack: goBackPublisher.send
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
            .onAppear {
                viewDidLoadPublisher.send()
            }
    }
    
    var profileInfo: some View {
        ZStack(alignment: .bottomLeading) {
            if let profileImage = viewModel.profileImageUrl {
                KingFisherImage(url: URL(string: profileImage))
                    .centerCropped(width: .infinity, height: 300, placeholder: {
                        ProgressView()
                    })
            } else {
                Image("placeholder")
                    .resizable()
                    .scaledToFill()
            }
            HStack {
                Text(viewModel.fullname)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if viewModel.isCompanyProfile {
                    Button(action: {
                        whiskyTappedPublisher.send()
                    }) {
                        viewModel.imGoingToClub.whiskyImage
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
        }
    }
    
    //In case showing a club profile
    var clubContent: some View {
        VStack {
            Text("Usuarios que asisten al club")
                .font(.system(size: 18, weight: .bold))
                .padding(.top, 10)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
            UsersGoingClubSubview(
                users: viewModel.usersGoingToClub.map({
                    UserGoingCellModel(
                        id: $0.uid,
                        username: $0.username,
                        profileImageUrl: $0.image
                    )
                }),
                onUserSelected: userSelectedPublisher.send
            )
            
            Text("Amigos que asisten al club")
                .font(.system(size: 18, weight: .bold))
                .padding(.top, 10)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
            UsersGoingClubSubview(
                users: viewModel.usersGoingToClub.map({
                    UserGoingCellModel(
                        id: $0.uid,
                        username: $0.username,
                        profileImageUrl: $0.image
                    )
                }),
                onUserSelected: userSelectedPublisher.send
            )
        }
        .padding(.top, 20)
    }
    
    var followButton: some View {
        Button(action: {
            followPublisher.send()
        }) {
            Text(viewModel.followButtonType == .follow ? "Follow" : "Following")
                .font(.system(size: 18))
                .padding()
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                .foregroundColor(.black)
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
            onUserSelected: userSelectedPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
