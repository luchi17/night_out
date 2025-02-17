import SwiftUI
import Combine

struct MyUserCompanySettingsView: View {
    
    @State private var showLocation = false
    @State private var showTagSelection = false
    @State private var showTimePicker = false
    @State private var locationModel = LocationModel()
    
    @Environment(\.dismiss) private var dismiss
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let saveInfoPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject var viewModel: MyUserCompanySettingsViewModel
    let presenter: MyUserCompanySettingsPresenter
    
    init(
        presenter: MyUserCompanySettingsPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Ubicación")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 8)
                
                locationButton
                
                Text("Horario Apertura")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 8)
                
                SettingsTimeButtonView(
                    title: viewModel.startTime,
                    selectedTimeString: $viewModel.startTime
                )
                
                Text("Horario Cierre")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 8)
                
                SettingsTimeButtonView(
                    title: viewModel.endTime,
                    selectedTimeString: $viewModel.endTime
                )
                
                Text("Vestimenta")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 8)
                
                selectTagButton
                
                Button(action: {
                    saveInfoPublisher.send()
                }) {
                    Text("GUARDAR CAMBIOS")
                        .font(.system(size: 18))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.all, 20)
        }
        .background(
            Color.black
                .edgesIgnoringSafeArea(.all)
        )
        .sheet(
            isPresented: $showLocation,
            onDismiss: {
                viewModel.locationString = locationModel.coordinate.location.latitude.description + "," + locationModel.coordinate.location.longitude.description
                
            }, content: {
                SignupMapView(locationModel: $locationModel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        )
        .onChange(of: viewModel.dismiss, { oldValue, newValue in
            if newValue {
                dismiss()
            }
        })
        .onAppear {
            viewDidLoadPublisher.send()
        }
    }
    
    private var selectTagButton: some View {
        Button(action: {
            showTagSelection.toggle()
        }) {
            Text(viewModel.selectedTag.title)
                .font(.system(size: 18))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .confirmationDialog("Elija etiqueta", isPresented: $showTagSelection) {
            Button(LocationSelectedTag.sportCasual.title) { viewModel.selectedTag = .sportCasual }
            Button(LocationSelectedTag.informal.title) { viewModel.selectedTag = .informal  }
            Button(LocationSelectedTag.semiInformal.title) { viewModel.selectedTag = .semiInformal  }
            Button("Cancel", role: .cancel) {
                viewModel.selectedTag = .none
            }
        } message: {
            Text("Elija etiqueta")
        }
    }
    
    private var locationButton: some View {
        Button(action: {
            showLocation.toggle()
        }) {
            Text(viewModel.locationString)
                .font(.system(size: 18))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}

private extension MyUserCompanySettingsView {
    func bindViewModel() {
        let input = MyUserCompanySettingsPresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            saveInfo: saveInfoPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}


private struct SettingsTimeButtonView: View {
    
    var title: String
    @State private var showTimePicker: Bool = false
    @State private var selectedTime = Date()
    @State private var firstTime: Bool = true
    @Binding var selectedTimeString: String
    
    var body: some View {
        Button(action: {
            firstTime = false
            showTimePicker.toggle()
        }) {
            Text(firstTime ? title : selectedTimeString)
                .font(.system(size: 18))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .if(showTimePicker) { view in
            VStack {
                view
                DatePicker("Seleccione la hora", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .onChange(of: selectedTime, { _ , newValue in
//                        showTimePicker.toggle() // Cierra el picker al seleccionar
                        selectedTimeString = timeString(from: selectedTime)
                    })
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 5)
            }
        }
    }
    
    // Formatear la fecha en una cadena de hora:minuto
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    
}
