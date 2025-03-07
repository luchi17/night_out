import SwiftUI
import Combine

struct DiscotecaDetailView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let followTappedPublisher = PassthroughSubject<Void, Never>()

    @State private var showShareSheet = false
    
    @ObservedObject var viewModel: DiscotecaDetailViewModel
    let presenter: DiscotecaDetailPresenter
    
    init(
        presenter: DiscotecaDetailPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            
            if viewModel.fiestas.isEmpty {
                
                VStack {
                    Spacer()
                    
                    Text("No hay eventos para esta discoteca.")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                topBarView
                
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        CollapsingHeader(imageUrl: $viewModel.companyModel.imageUrl)
                        
                        clubInfoView
                            .padding(.horizontal, 12)
                        EventsSection(fiestas: $viewModel.fiestas)
                            .padding(.horizontal, 12)
                    }
                }
                .scrollIndicators(.hidden)
                
                topBarView
                    .padding(.top, 40)
                
            }
        }
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
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: ["¡Echa un vistazo a esta discoteca en NightOut! nightout://profile/\(viewModel.companyModel.uid)"])
        }
        .onAppear(perform: viewDidLoadPublisher.send)
    }
    
    var topBarView: some View {
        HStack {
            Button(action: {
                print("Back")
            }) {
                Image("back")
                    .resizable()
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
            }
            Spacer()
            Button(action: {
                print("Follow")
                followTappedPublisher.send()
            }) {
                Text(viewModel.following.title)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 90, height: 30)
                    .background(Color.darkBlueColor)
                    .cornerRadius(8)
            }
            Button(action: {
                print("Share")
                self.showShareSheet.toggle()
            }) {
                Image("share")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
            }
        }
        .background(Color.clear)
    }
    
    var clubInfoView: some View {
        HStack(spacing: 8) {
            Text(viewModel.companyModel.username ?? "Nombre desconocido")
                .font(.system(size: 22))
                .bold()
                .foregroundColor(.white)
            Image("verified_profile_icon")
                .resizable()
                .frame(width: 30, height: 30)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension DiscotecaDetailView {
    
    func bindViewModel() {
        let input = DiscotecaDetailPresenterImpl.Input(
            viewIsLoaded: viewDidLoadPublisher.eraseToAnyPublisher(),
            followTapped: followTappedPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
    
}

struct CollapsingHeader: View {
    @Binding var imageUrl: String?
    
    var body: some View {
        GeometryReader { geometry in
            if let imageUrl = imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: max(geometry.size.height, 230))
                        .clipped()
                } placeholder: {
                    Color.grayColor
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: max(geometry.size.height, 230))
                        .clipped()
                }
            } else {
                Image("loading")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: max(geometry.size.height, 230))
                    .clipped()
            }
           
        }
        .frame(height: 230)
    }
}

struct EventsSection: View {
    
    @Binding var fiestas: [Fiesta]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Próximos eventos")
                .font(.system(size: 18))
                .bold()
                .foregroundColor(.white)
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(fiestas, id: \.id) { fiesta in
                EventCardRow(fiesta: fiesta)
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .padding(.bottom)
            }
        }
    }
}
