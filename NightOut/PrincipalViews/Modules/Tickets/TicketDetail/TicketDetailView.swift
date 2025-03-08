import SwiftUI
import Combine

struct TicketDetailView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let followTappedPublisher = PassthroughSubject<Void, Never>()
    private let goBackPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject var viewModel: TicketDetailViewModel
    let presenter: TicketDetailPresenter
    
    init(
        presenter: TicketDetailPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
            VStack {
                
                backButton
                    .padding(.top, 50)
                    .padding(.bottom, 20)
                
                if !viewModel.loading {
                    ScrollView {
                        VStack(alignment: .leading) {
                            
                            topView
                                .padding(.bottom, 20)
                            
                            Spacer()
                                .frame(height: 1)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                            
                            clubInfoView
                                .padding(.bottom, 20)

                            Text("Entradas")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.top)
                            
                            if viewModel.loading {
                              
                                 Image("loading")
                                     .resizable()
                                     .scaledToFit()
                                     .frame(width: 70, height: 70)
                                     .padding(.top)
                                 
                                 Spacer()
                                
                            } else {
                                ForEach($viewModel.entradas, id: \.id) { entrada in
                                    EntradasView(entrada: entrada)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .edgesIgnoringSafeArea(.all)
            .navigationBarBackButtonHidden()
            .background(
                Color.blackColor.ignoresSafeArea()
            )
            .preferredColorScheme(.dark)
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
            .onAppear(perform: viewDidLoadPublisher.send)
        }
    
    var topView: some View {
        
        HStack {
            AsyncImage(url: URL(string: viewModel.fiesta.imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width / 2, height: 200)
                    .clipped()
                
            } placeholder: {
                Color.grayColor
                    .frame(width: UIScreen.main.bounds.width / 2, height: 200)
            }
            
            VStack(spacing: 10) {
                Text(viewModel.fiesta.name.capitalized)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Fecha: \(viewModel.fiesta.fecha)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.yellow)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: openMaps) {
                    HStack(spacing: 0) {
                        Image("localizacion")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .foregroundColor(.white)
                        
                        Text(viewModel.companyModel.username?.capitalized ?? "Ubicación no disponible")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical)
            .padding(.horizontal, 12)
        }
    }
    
    
    var backButton: some View {
        HStack(spacing: 10) {
            Button(action: {
                goBackPublisher.send()
            }) {
                Image("back")
                    .resizable()
                    .foregroundColor(Color.white)
                    .frame(width: 35, height: 35)
            }
            Spacer()
        }
    }
    
    var clubInfoView: some View {
        VStack(spacing: 0) {
            Text("Información del evento")
                .font(.system(size: 20))
                .bold()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)
            
            Text(viewModel.fiesta.description)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 20)
            
            HStack(spacing: 25) {
                
                if let imageUrl = viewModel.companyModel.imageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipped()
                    } placeholder: {
                        Color.grayColor
                            .frame(width: 70, height: 70)
                    }
                }
                
                Text(viewModel.companyModel.username ?? "Nombre desconocido")
                    .font(.system(size: 18))
                    .bold()
                    .foregroundColor(.white)
                
                Spacer()
            }
        }
    }
}

private extension TicketDetailView {
    
    func bindViewModel() {
        let input = TicketDetailPresenterImpl.Input(
            viewIsLoaded: viewDidLoadPublisher.eraseToAnyPublisher(),
            goBack: goBackPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
    
    func openMaps() {
        if let location = viewModel.companyModel.location?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: "https://www.google.com/maps/search/?api=1&query=\(location)") {
                UIApplication.shared.open(url)
            }
        }
    
}

