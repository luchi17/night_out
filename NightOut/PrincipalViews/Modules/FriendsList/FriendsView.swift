
import SwiftUI
import Combine

struct FriendsView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<[String], Never>()
    private let goToProfilePublisher = PassthroughSubject<ProfileModel, Never>()
    
    @ObservedObject var viewModel: FriendsViewModel
    let presenter: FriendsPresenter
    let followerIds: [String]
    
    init(
        presenter: FriendsPresenter,
        followerIds: [String]
    ) {
        self.presenter = presenter
        self.followerIds = followerIds
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        VStack {
            
            Spacer().frame(height: 20)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.followers, id: \.self) { user in
                        
                        if user.profileId.isEmpty {
                            ListUserEmptySubView()
                        } else {
                            ListUserSubView(user: user)
                        }
                       
                    }
                }
            }
            Spacer()
        }
        .background(
            Color.blackColor
                .edgesIgnoringSafeArea(.all)
        )
        .applyStates(error: nil, isIdle: viewModel.loading)
        .onAppear {
            viewDidLoadPublisher.send(followerIds)
        }
    }
}

private extension FriendsView {
    func bindViewModel() {
        let input = FriendsPresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            goToProfile: goToProfilePublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}


struct FriendRow: View {
    
    var user: ProfileModel
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: user.profileImageUrl ?? "")) { image in
                image.resizable()
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.5)) // Color mientras carga
                    .frame(width: 50, height: 50)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            Text(user.username ?? "Desconocido")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .background(Color.blackColor)
        .cornerRadius(10)
    }
}

struct ListUserEmptySubView: View {
    
    var body: some View {
        
        HStack(spacing: 10) {
            
            Circle()
                .fill(Color.gray) // Color mientras carga
                .frame(width: 40, height: 40)
                .padding(.leading, 5)
            
            Text("Usuario eliminado")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

