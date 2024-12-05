import SwiftUI
import Combine

struct UserProfileView: View {

    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let shareProfilePublisher = PassthroughSubject<Void, Never>()
    
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
            // Imagen de fondo
            Image("fondo_azul")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)

            VStack {
                // Contenedor de imagen y botones en la parte superior
                VStack {
                    HStack {
                        // Botón de editar perfil
                        Button(action: {
                            // Acción para editar perfil
                        }) {
                            Text("Editar")
                                .font(.system(size: 12))
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                                .foregroundColor(.white)
                        }
                        .frame(width: 70, height: 40)
                        .padding(.top, 16)
                        .padding(.trailing, 16)
                        Spacer()
                    }

                    // Imagen de perfil
                    if let profileImageUrl = viewModel.profileImageUrl {
                        KingFisherImage(url: URL(string: profileImageUrl))
                            .centerCropped(width: 100, height: 100, placeholder: {
                                Image("placeholder")
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

                    // Botón para compartir perfil
                    Button(action: {
                        shareProfilePublisher.send()
                    }) {
                        Text("Compartir perfil")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                            .padding()
                            .background(Capsule().fill(Color.white))
                    }
                    .padding(.top, 16)

                    // Contadores
                    HStack {
                        CounterView(count: viewModel.followersCount, label: "Seguidores")
                        CounterView(count: viewModel.discosCount, label: "Discotecas")
                        CounterView(count: viewModel.copasCount, label: "Copas")
                    }
                    .padding(.top, 16)
                }
                .padding()
            }
        }
        .onAppear {
           
            viewDidLoadPublisher.send()
        }
    }
}

private extension UserProfileView {
    func bindViewModel() {
        let input = UserProfilePresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            shareProfile: shareProfilePublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}



//private func shareProfile(profileId: String) {
//    // Acción para compartir el perfil
//    let appLink = "nightout://profile/\(profileId)"
//    let activityVC = UIActivityViewController(activityItems: [appLink], applicationActivities: nil)
//    if let rootVC = UIApplication.shared.windows.first?.rootViewController {
//        rootVC.present(activityVC, animated: true, completion: nil)
//    }
//}

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
        .background(Color.blue)
        .cornerRadius(10)
        .padding(.horizontal, 8)
    }
}

struct UserProfilePostView: View {
    var post: PostUserModel

    var body: some View {
        VStack {
            Text(post.description ?? "")
            if let imageUrl = post.postImage {
                KingFisherImage(url: URL(string: imageUrl))
                    .centerCropped(width: 100, height: 100, placeholder: {
                        Image("placeholder")
                    })
                    .clipShape(Circle())
                    
            } else {
                Image("placeholder")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.bottom, 10)
    }
}
