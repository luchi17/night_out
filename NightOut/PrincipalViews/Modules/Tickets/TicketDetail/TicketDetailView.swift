import SwiftUI
import Combine

struct TicketDetailView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let goBackPublisher = PassthroughSubject<Void, Never>()
    private let openMapsPublisher = PassthroughSubject<Void, Never>()
    private let openAppleMapsPublisher = PassthroughSubject<Void, Never>()
    private let pagarPublisher = PassthroughSubject<Void, Never>()
    
    @State private var showNavigationAlert = false
    @State private var isSheetPresented = false
    
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
                                .padding(.bottom, 10)
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundStyle(.white.opacity(0.3))
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 20)
                            
                            clubInfoView
                                .padding(.bottom, 20)

                            Text("Entradas")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.bottom, 20)
                            
                            if viewModel.loading {
                              
                                 Image("loading")
                                     .resizable()
                                     .scaledToFit()
                                     .frame(width: 70, height: 70)
                                     .padding(.top)
                                 
                                 Spacer()
                                
                            } else {
                                ForEach($viewModel.entradas, id: \.id) { entrada in
                                    VStack {
                                        EntradasView(entrada: entrada)
                                            .onTapGesture {
                                                viewModel.entradaTapped = entrada.wrappedValue
                                                isSheetPresented.toggle()
                                            }
                                        Spacer()
                                            .frame(height: 20)
                                    }
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
            .alert("Abrir localización", isPresented: $showNavigationAlert) {
                Button("Apple Maps") {
                    openAppleMapsPublisher.send()
                    showNavigationAlert = false
                }
                Button("Google Maps") {
                    openMapsPublisher.send()
                    showNavigationAlert = false
                }
                Button("Cerrar", role: .cancel) {
                    showNavigationAlert = false
                }
            } message: {
                Text("Elige una app para abrir la localización.")
            }
            .sheet(isPresented: $isSheetPresented, onDismiss: {
                // Reset values
                viewModel.entradaTapped = nil
                viewModel.finalPrice = 0.0
                viewModel.quantity = 1
            }) {
                BuyTicketBottomSheet(
                    quantity: $viewModel.quantity,
                    precio: $viewModel.finalPrice,
                    precioInicial: viewModel.entradaTapped?.price ?? 0.0,
                    pagar: {
                        isSheetPresented = false
                        pagarPublisher.send()
                    }
                )
                .presentationDetents([.height(250)])
            }
            .onChange(of: viewModel.entradaTapped, { oldValue, newValue in
                viewModel.finalPrice = newValue?.price ?? 0.0
            })
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
                    .frame(width: (UIScreen.main.bounds.width / 2) - 45, height: 200)
                    .clipped()
                
            } placeholder: {
                Color.grayColor
                    .frame(width: (UIScreen.main.bounds.width / 2) - 45, height: 200)
            }
            
            VStack(spacing: 10) {
                Text(viewModel.fiesta.name.capitalized)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("\(Utils.formatDate(viewModel.fiesta.fecha) ?? "Fecha")")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.yellow)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: {
                    showNavigationAlert = true
                }) {
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
            goBack: goBackPublisher.eraseToAnyPublisher(),
            openMaps: openMapsPublisher.eraseToAnyPublisher(),
            openAppleMaps: openAppleMapsPublisher.eraseToAnyPublisher(),
            pagar: pagarPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}

