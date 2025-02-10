import SwiftUI
import Combine

//Profile3

struct PrivateUserProfileView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let requestPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject var viewModel: PrivateUserProfileViewModel
    let presenter: PrivateUserProfilePresenter
    
    init(
        presenter: PrivateUserProfilePresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            Image("private_profile")
                .resizable()
                .scaledToFill()
                .frame(width: 70, height: 70)
                .foregroundStyle(.white)
                .padding(.bottom, 20)
            
            
            Text("Este perfil es privado.")
                .foregroundStyle(.white)
                .bold()
                .font(.system(size: 18))
                .padding(.bottom, 12)
            
            Text("Envía una solicitud para seguir este perfil.")
                .foregroundStyle(.gray)
                .font(.system(size: 16))
                .padding(.bottom, 20)
            
            requestButton
            
            Spacer()
            
            HStack {
                Spacer()
                
                Image("logo_inicio_app")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.white)
            }
            
        }
        .padding()
        .background(Color.black.opacity(0.9))
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
    
    var requestButton: some View {
        Button(action: {
            requestPublisher.send()
        }) {
            Text(viewModel.buttonTitle)
                .font(.system(size: 18))
                .padding(.all, 12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.black))
                .foregroundColor(.white)
        }
        .padding(.top, 16)
    }
}

private extension PrivateUserProfileView {
    func bindViewModel() {
        let input = PrivateUserProfilePresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            requestProfile: requestPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
