import SwiftUI
import Combine

struct PayDetailView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let goBackPublisher = PassthroughSubject<Void, Never>()
    private let pagarPublisher = PassthroughSubject<Void, Never>()
    
    @State private var showDatePicker = false
    
    @State private var selectedUserIndex: Int?
    @State private var selectedDate: Date?
    
    @ObservedObject var viewModel: PayDetailViewModel
    let presenter: PayDetailPresenter
    
    init(
        presenter: PayDetailPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            ScrollView(.vertical) {
                
                VStack {
                    topView
                        .padding(.top, 60)
                    
                    Text(viewModel.countdownText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 15)
                    
                    secondView
                    
                    ForEach(0..<viewModel.users.count, id: \.self) { index in
                        
                        PayUserCardView(
                            user: $viewModel.users[index],
                            showDatePicker: $showDatePicker,
                            selectedUserIndex: $selectedUserIndex,
                            index: index
                        )
                        .padding(.bottom, 15)
                    }
                    .padding(.top, 15)
                    
                    Spacer()
                        .frame(height: 200)
                }
                .padding(.horizontal, 20)
                
            }
            .scrollIndicators(.hidden)
            
            Rectangle()
                .foregroundStyle(Color.blackColor)
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .overlay {
                    Button(action: {
                        pagarPublisher.send()
                    }) {
                        Text("PAGAR: \(String(describing: Double(String(format: "%.2f", viewModel.finalPrice)) ?? 0.0 ))€")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.yellow)
                            .foregroundColor(Color.blackColor)
                            .cornerRadius(20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarBackButtonHidden()
        .background(
            Color.blackColor.ignoresSafeArea()
        )
        .overlay(alignment: .top, content: {
            backButton
                .padding(.leading, 20)
        })
        .sheet(isPresented: $showDatePicker, onDismiss: {
            if let index = selectedUserIndex {
                if let selectedDate = selectedDate {
                    viewModel.users[index].birthDate = formatBirthDate(selectedDate)
                } else {
                    viewModel.users[index].birthDate = ""
                }
            }
        }) {
            UserBirthDatePickerView(selectedDate: $selectedDate)
                .presentationDetents([.large])
            
        }
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
            AsyncImage(url: URL(string: viewModel.model.fiesta.imageUrl)) { image in
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
                Text(viewModel.model.entrada.type.capitalized)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("\(formatDateString(viewModel.model.fiesta.fecha) ?? "Fecha"), \(viewModel.model.fiesta.startTime)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.yellow)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical)
            .padding(.horizontal, 12)
        }
        .padding(12)
        .background(Color.grayColor)
        .cornerRadius(20)
    }
    
    
    var backButton: some View {
        HStack(spacing: 10) {
            Button(action: {
                goBackPublisher.send()
            }) {
                Image("back")
                    .resizable()
                    .foregroundColor(Color.white)
                    .frame(width: 30, height: 30)
            }
            Spacer()
        }
    }
    
    var secondView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("\(viewModel.model.quantity)x \(viewModel.model.entrada.type.capitalized)")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                Text("\(String(describing: Double(String(format: "%.2f", viewModel.model.entrada.price)) ?? 0.0 ))€")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.bottom, 10)
            
            HStack(spacing: 0) {
                Text("Gastos de gestión:")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                Text("\(String(describing: Double(String(format: "%.2f", viewModel.gastosGestion)) ?? 0.0 ))€")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
            }
            .padding(.bottom, 10)
            
            HStack(spacing: 0) {
                Text("Total")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                Text("\(String(describing: Double(String(format: "%.2f", viewModel.finalPrice)) ?? 0.0 ))€")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
            }
            .padding(.bottom, 10)
            
        }
        .padding(12)
        .background(Color.grayColor)
        .cornerRadius(20)
    }
}

private extension PayDetailView {
    
    func bindViewModel() {
        let input = PayDetailPresenterImpl.Input(
            viewIsLoaded: viewDidLoadPublisher.eraseToAnyPublisher(),
            goBack: goBackPublisher.eraseToAnyPublisher(),
            pagar: pagarPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
    
    
    // Función para formatear la fecha al estilo "DD/MM/YYYY"
    private func formatBirthDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.string(from: date)
    }
    
    func formatDateString(_ input: String) -> String? {
        // Crear un DateFormatter para analizar la fecha en el formato "12 de Febrero"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d 'de' MMMM"
        
        // Analizar la cadena de entrada a un objeto Date
        guard let date = dateFormatter.date(from: input.lowercased()) else { return nil }
        
        // Crear un nuevo DateFormatter para el formato "12 Feb"
        dateFormatter.dateFormat = "d MMM"
        
        // Convertir la fecha a la cadena formateada
        return dateFormatter.string(from: date)
    }
    
}
