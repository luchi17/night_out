import SwiftUI
import PhotosUI

struct ManagementEventsView: View {
    
    let onClose: VoidClosure
    
    init(onClose: @escaping VoidClosure) {
        self.onClose = onClose
    }
    
    @StateObject private var viewModel = ManagementEventsViewModel()
    @State private var showDatePicker: Bool = false
    
    enum FocusField: Hashable, RawRepresentable {
        case nombreEvento
        case fechaEvento
        case description
        case nombre(UUID)
        case precio(UUID)
        case aforo(UUID)
        
        var rawValue: String {
            switch self {
            case .nombreEvento: return "nombreEvento"
            case .fechaEvento: return "fechaEvento"
            case .description: return "description"
            case .nombre(let id): return "nombre-\(id.uuidString)"
            case .precio(let id): return "precio-\(id.uuidString)"
            case .aforo(let id): return "aforo-\(id.uuidString)"
            }
        }
        
        init?(rawValue: String) {
            let components = rawValue.split(separator: "-")
            guard components.count == 2, let id = UUID(uuidString: String(components[1])) else {
                return nil
            }
            switch components[0] {
            case "nombre": self = .nombre(id)
            case "precio": self = .precio(id)
            case "aforo": self = .aforo(id)
            case "nombreEvento": self = .nombreEvento
            case "fechaEvento": self = .fechaEvento
            default:
                self = .description
            }
        }
    }
    
    @FocusState private var focusedField: FocusField?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                HStack {
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(Color.white)
                    }
                }
                .padding(.trailing, 5)
                .padding(.top, 22)
                
                // Imagen del evento
                imagePicker
                    .padding(.top, 16)
                
                Button(action: {
                    viewModel.showImagePicker.toggle()
                }) {
                    Text("Pincha círculo para agregar imagen")
                        .foregroundColor(.white)
                        .italic()
                        .font(.system(size: 16))
                }
                
                // Nombre del evento
                TextField("Nombre del Evento", text: $viewModel.eventName)
                    .textfieldStyle()
                    .focused($focusedField, equals: .nombreEvento)
                
                Text("Fecha del Evento")
                    .textfieldStyle()
                    .onTapGesture {
                        showDatePicker.toggle()
                    }
                
                // Tipo de Música
                HStack {
                    Text("Música")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Picker("Tipo de Música", selection: $viewModel.selectedMusicGenre) {
                        ForEach(viewModel.musicGenres, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity)
                }
                
                // Botones de Apertura y Cierre
                HStack {
                    TimeButtonView(
                        title: "APERTURA",
                        selectedTimeString: $viewModel.startTime
                    )
                    TimeButtonView(
                        title: "CIERRE",
                        selectedTimeString: $viewModel.endTime
                    )
                }
                
                // Descripción del evento
                TextField("", text: $viewModel.eventDescription, prompt: Text("Descripción del Evento").foregroundColor(Color.grayColor), axis: .vertical)
                    .textfieldStyle()
                    .frame(minHeight: 100)
                    .focused($focusedField, equals: .description)
                    .onSubmit {
                        hideKeyboard()
                    }
                
                
                // Campos adicionales
                VStack(alignment: .leading) {
                    ForEach($viewModel.entradas, id: \.id) { $entrada in
                        ForEach($entrada.entradasTipo.indices, id: \.self) { index in
                            
                            let fieldID = entrada.id
                            
                            Text("Entrada tipo \(index + 1)")
                                .foregroundStyle(.white)
                                .font(.system(size: 16, weight: .bold))
                            
                            TextField("", text: $entrada.entradasTipo[index].nombre, prompt: Text("Nombre").foregroundColor(Color.grayColor))
                                .textFieldEntradaType()
                                .focused($focusedField, equals: .nombre(fieldID))
                                .onSubmit {
                                    focusedField = .precio(fieldID)  // Pasar foco al siguiente campo
                                }
                                .submitLabel(.next)
                            
                            TextField("", text: $entrada.entradasTipo[index].precio, prompt: Text("Precio").foregroundColor(Color.grayColor))
                                .textFieldEntradaType()
                                .focused($focusedField, equals: .precio(fieldID))
                                .onSubmit {
                                    focusedField = .aforo(fieldID)
                                }
                                .submitLabel(.next)
                            
                            TextField("", text: $entrada.entradasTipo[index].aforo, prompt: Text("Aforo").foregroundColor(Color.grayColor))
                                .textFieldEntradaType()
                                .focused($focusedField, equals: .aforo(fieldID))
                                .onSubmit {
                                    focusedField = nil  // Cierra el teclado al finalizar
                                }
                                .submitLabel(.done)
                        }
                    }
                }
                
                belowButtons
            }
            .padding(.horizontal, 12)
        }
        .clipShape(Rectangle())
        .scrollClipDisabled(false)
        .scrollIndicators(.hidden)
        .edgesIgnoringSafeArea(.bottom)
        .background(
            Color.blackColor.edgesIgnoringSafeArea(.all)
        )
        .photosPicker(isPresented: $viewModel.showImagePicker, selection: $viewModel.selectedItem, matching: .images)
        .sheet(isPresented: $showDatePicker) {
            datePicker
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .onTapGesture(perform: {
            hideKeyboard()
        })
        .showToast(
            error: (
                type: viewModel.toast,
                showCloseButton: false,
                onDismiss: {
                    if case .success = viewModel.toast {
                        viewModel.toast = nil
                        onClose()
                    }
                }
            ),
            isIdle: viewModel.loading
        )
    }
    
    private var imagePicker: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 120, height: 120)

                if let selectedImage = viewModel.image {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Image("camara")
                        .resizable()
                        .foregroundStyle(.white)
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                }
            }
            .onTapGesture {
                viewModel.showImagePicker.toggle()
            }
        }
    }
    
    private var datePicker: some View {
        DatePicker("Selecciona una fecha", selection: Binding<Date> (
            get: { Date() },
            set: { newValue in
                viewModel.eventDate = formattedDate(newValue)
            }),
            displayedComponents: [.date]
        )
        .datePickerStyle(GraphicalDatePickerStyle())
    }
    
    private func formattedDate(_ date: Date) -> String {
        let day = String(format: "%02d", Calendar.current.component(.day, from: date))
        let month = String(format: "%02d", Calendar.current.component(.month, from: date))
        let year = Calendar.current.component(.year, from: date)
        return "\(day)-\(month)-\(year)"
    }
    
    var belowButtons: some View {
        VStack {
            // Botones + y - para añadir campos
            HStack {
                Button("+") {
                    viewModel.addEntrada()
                }
                .frame(width: 40, height: 40)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
                
                Button("-") {
                    viewModel.removeLastEntrada()
                }
                .frame(width: 40, height: 40)
                .background(Color.red)
                .foregroundColor(.white)
                .clipShape(Circle())
                
                Text("Añadir entradas al evento")
                    .foregroundColor(.white)
            }
            .padding()
            
            // Botón de Subir Evento
            Button(action: {
                viewModel.uploadEvent()
            }) {
                Text("Subir evento".uppercased())
                    .buttonStyle()
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private extension View {
    
    @ViewBuilder
    func textFieldEntradaType() -> some View {
        self
            .textFieldStyle(PlainTextFieldStyle())
            .foregroundColor(Color.blackColor)
            .accentColor(Color.blackColor)
            .padding()
            .background(
                Rectangle().fill(.white)
            )
    }
    
    @ViewBuilder
    func textfieldStyle() -> some View {
        self
            .textFieldStyle(PlainTextFieldStyle())
            .foregroundColor(Color.blackColor)
            .accentColor(Color.blackColor)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10).fill(.white)
            )
    }
    @ViewBuilder
    func buttonStyle() -> some View {
        self
            .font(.system(size: 16, weight: .bold))
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .background(Color.grayColor)
            .cornerRadius(25)
    }
}
