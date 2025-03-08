import SwiftUI
import Combine

struct DiscotecaDetailView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let followTappedPublisher = PassthroughSubject<Void, Never>()
    private let goBackPublisher = PassthroughSubject<Void, Never>()

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
            
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    CollapsingHeader(imageUrl: $viewModel.companyModel.imageUrl)
                    
                    clubInfoView
                        .padding([.horizontal, .top], 20)
                    EventsSection(fiestas: $viewModel.fiestas)
                        .padding([.horizontal, .top], 20)
                        .padding(.bottom, 50)
                }
            }
            .scrollIndicators(.hidden)
            
            topBarView
                .padding(.top, 60)
                .padding(.horizontal, 20)
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
            
            HStack(alignment: .bottom) {
                Button(action: {
                    followTappedPublisher.send()
                }) {
                    Text(viewModel.following.title)
                        .font(.system(size: 18))
                        .bold()
                        .foregroundColor(.white)
                        .frame(width: 95, height: 35)
                        .background(Color.darkBlueColor)
                        .cornerRadius(16)
                }
                Button(action: {
                    self.showShareSheet.toggle()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 35, height: 35)
                        .foregroundColor(Color.white)
                        .bold()
                }
            }
        }
        .background(Color.clear)
    }
    
    var clubInfoView: some View {
        HStack(spacing: 8) {
            Text(viewModel.companyModel.username?.capitalized ?? "Nombre desconocido")
                .font(.system(size: 24))
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
            followTapped: followTappedPublisher.eraseToAnyPublisher(),
            goBack: goBackPublisher.eraseToAnyPublisher()
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
            
            if fiestas.isEmpty {
                VStack {
                    Spacer()
                    
                    Text("No hay eventos para esta discoteca.")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                    
                    Spacer()
                }
            } else {
                Text("Próximos eventos")
                    .font(.system(size: 22))
                    .bold()
                    .foregroundColor(.white)
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(fiestas, id: \.id) { fiesta in
                    VStack {
                        EventCardRow(
                            fiesta: fiesta,
                            imageWidth: (UIScreen.main.bounds.width / 2) - 30,
                            imageHeight: 250 - 16
                        )
                        .frame(maxWidth: .infinity)
                        
                        Spacer()
                            .frame(height: 20)
                    }
                }
            }
        }
    }
}
