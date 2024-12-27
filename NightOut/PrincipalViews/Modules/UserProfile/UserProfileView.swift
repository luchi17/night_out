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
        VStack(spacing: 0) {
            navigationBar
            
            Text(viewModel.username)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.trailing, 10)
            
            profileInfo
            
            followButton
            
            clubContent
            
        }
        .navigationBarHidden(true)
        .background(Color.black.opacity(0.8))
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            viewDidLoadPublisher.send()
        }
    }
    
    var navigationBar: some View {
        HStack {
            Button(action: {
                goBackPublisher.send()
            }) {
                Image(systemName: "chevron.left")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(.white)
                    .padding(.leading, 5)
            }
            
            Spacer()
            
            Text(viewModel.username)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.top, 4)
        .frame(height: 50)
        .background(Color.blue)
    }
    
    var profileInfo: some View {
        ZStack {
            if let profileImage = viewModel.profileImageUrl {
                KingFisherImage(url: URL(string: profileImage))
                    .centerCropped(width: 300, height: 300, placeholder: {
                        ProgressView()
                    })
                    .scaledToFill()
                    .clipped()
            } else {
                Image("placeholder")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 300)
            }
           
            VStack {
                HStack {
                    Text(viewModel.fullname)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 16)
                        .padding(.leading, 16)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        whiskyTappedPublisher.send()
                    }) {
                        viewModel.imGoingToClub.whiskyImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.white)
                            .padding(.bottom, 20)
                    }
                }
            }
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
