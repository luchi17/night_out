import SwiftUI
import Combine

struct UserProfileView: View {

    @State private var showShareSheet = false
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let editProfilePublisher = PassthroughSubject<Void, Never>()
    
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
        ZStack {
//             Imagen de fondo
            #warning("IMAGE")
            Color.blue
                .edgesIgnoringSafeArea(.all)

            VStack {
                
                editProfileButton

                if let profileImageUrl = viewModel.profileImageUrl {
                    KingFisherImage(url: URL(string: profileImageUrl))
                        .centerCropped(width: 100, height: 100, placeholder: {
                            ProgressView()
                        })
                        .clipShape(Circle())
                        .padding(.top, 40)
                } else {
                    Image("placeholder")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .padding(.top, 40)
                }

                Text(viewModel.fullname)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 8)

                Text(viewModel.username)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                
                shareProfileButton
                
                HStack(spacing: 8) {
                    CounterView(count: viewModel.followersCount, label: "Seguidores")
                    CounterView(count: viewModel.discosCount, label: "Discotecas")
                    CounterView(count: viewModel.copasCount, label: "Copas")
                }
                .padding(.top, 16)
                
                Spacer()
                
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let currentId = FirebaseServiceImpl.shared.getCurrentUserUid() {
                // Presentar el ActivityViewController para compartir
                ShareSheet(activityItems: ["¡Echa un vistazo a este perfil en NightOut! nightout://profile/\(currentId)"])
            }
        }
        .applyStates(error: nil, isIdle: viewModel.loading)
        .onAppear {
            viewDidLoadPublisher.send()
        }
    }
    
    var editProfileButton: some View {
        HStack {
            Spacer()
            Button(action: {
                editProfilePublisher.send()
            }) {
                Text("Editar")
                    .font(.system(size: 16))
                    .foregroundColor(.yellow)
                    .padding()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.yellow, lineWidth: 3)
                    )
                    .frame(width: 80, height: 60)
            }
            .padding(.trailing, 16)
        }
        .padding(.top, 16)
    }
    
    var shareProfileButton: some View {
        Button(action: {
            self.showShareSheet.toggle()
        }) {
            Text("Compartir perfil")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.red)
                .padding()
                .background(Color.white)
                .cornerRadius(20)
        }
        .padding(.top, 16)
    }
}

private extension UserProfileView {
    func bindViewModel() {
        let input = UserProfilePresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            editProfile: editProfilePublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
