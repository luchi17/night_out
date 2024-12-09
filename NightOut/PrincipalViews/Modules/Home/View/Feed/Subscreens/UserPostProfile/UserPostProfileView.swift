import SwiftUI
import Combine

struct UserPostProfileView: View {

    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject var viewModel: UserPostProfileViewModel
    let presenter: UserPostProfilePresenter
    
    init(
        presenter: UserPostProfilePresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        ZStack {
//             Imagen de fondo
            #warning("IMAGE")
            Image("fondo_azul")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
                .background(Color.blue)

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
                    Image("placeholder")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .padding(.top, 40)
                }

                // Nombre y username
                Text(viewModel.fullname)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 8)

                Text(viewModel.username)
                    .font(.system(size: 14))
                    .foregroundColor(.white)

                // Contadores
                HStack(spacing: 8) {
                    CounterView(count: viewModel.followersCount, label: "Seguidores")
                    CounterView(count: viewModel.discosCount, label: "Discotecas")
                    CounterView(count: viewModel.copasCount, label: "Copas")
                }
                .padding(.top, 16)
                
                Spacer()
            }
        }
        .onAppear {
            viewDidLoadPublisher.send()
        }
    }
}

private extension UserPostProfileView {
    func bindViewModel() {
        let input = UserPostProfilePresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher()
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


//viewuserprofile
//profile3 al buscar amigos
