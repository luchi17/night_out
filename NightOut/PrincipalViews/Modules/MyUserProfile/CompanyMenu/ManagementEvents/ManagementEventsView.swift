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
                .padding(.trailing, 15)
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
                TextField("", text: $viewModel.eventName, prompt: Text("Nombre del Evento").foregroundColor(Color.grayColor))
                    .textfieldStyle()
                    .focused($focusedField, equals: .nombreEvento)
                
                Text(viewModel.eventDate.isEmpty ? "Fecha del Evento" : viewModel.eventDate)
                    .foregroundColor(Color.blackColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10).fill(.white)
                    )
                    .onTapGesture {
                        showDatePicker.toggle()
                    }
                
                // Tipo de Música
                musicView
                
                // Botones de Apertura y Cierre
                HStack {
                    TimeButtonView(
                        title: "APERTURA",
                        selectedTimeString: $viewModel.startTime,
                        verticalPadding: 12
                    )
                    
                    TimeButtonView(
                        title: "CIERRE",
                        selectedTimeString: $viewModel.endTime,
                        verticalPadding: 12
                    )
                }
                
                // Descripción del evento
                TextField("", text: $viewModel.eventDescription, prompt: Text("Descripción del Evento").foregroundColor(Color.grayColor), axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(Color.blackColor)
                    .accentColor(Color.blackColor)
                    .frame(maxWidth: .infinity, minHeight: 55, alignment: .top)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10).fill(.white)
                    )
                    .focused($focusedField, equals: .description)
                    .onSubmit {
                        hideKeyboard()
                    }
                
                // Campos adicionales
                entradasView
                
                belowButtons
            }
            .padding(.horizontal, 20)
        }
        .clipShape(Rectangle())
        .scrollClipDisabled(false)
        .scrollIndicators(.hidden)
        .edgesIgnoringSafeArea(.bottom)
        .background(
            Color.blackColor.edgesIgnoringSafeArea(.all)
        )
        .photosPicker(isPresented: $viewModel.showImagePicker, selection: $viewModel.selectedItem, matching: .images)
        .onChange(of: viewModel.selectedItem) { _, newItem in
            Task {
                if let newItem = newItem {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        viewModel.image = uiImage
                    }
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            datePicker
                .padding()
                .presentationDetents([.medium])
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
    
    
    private var musicView: some View {
        HStack {
            Text("Música")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Picker("Tipo de Música", selection: $viewModel.selectedMusicGenre) {
                ForEach(viewModel.musicGenres, id: \.self) { type in
                    Text(type)
                        .foregroundStyle(Color.blackColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .italic()
                        .tag(type)
                }
            }
            .labelsHidden()
            .pickerStyle(MenuPickerStyle())
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Color.blackColor)
            .accentColor(Color.blackColor)
            .italic()
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white)
            )
            .onAppear {
                // Asegúrate de que la primera opción esté seleccionada si no hay ninguna
                if viewModel.selectedMusicGenre.isEmpty, let firstGenre = viewModel.musicGenres.first {
                    viewModel.selectedMusicGenre = firstGenre
                }
            }
        }
    }
    
    private var entradasView: some View {
        VStack(alignment: .leading, spacing: 2) {
            
            ForEach($viewModel.entradas.indices, id: \.self) { index in
                
                let uuid = $viewModel.entradas[index].id
                
                Text("Entrada tipo \(index + 1)")
                    .foregroundStyle(.white)
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 10)
                
                TextField("", text: $viewModel.entradas[index].nombre, prompt: Text("Nombre").foregroundColor(Color.grayColor))
                    .textFieldEntradaType()
                    .focused($focusedField, equals: .nombre(uuid))
                    .onSubmit {
                        focusedField = .precio(uuid)  // Pasar foco al siguiente campo
                    }
                    .submitLabel(.next)
                
                TextField("", text: $viewModel.entradas[index].precio, prompt: Text("Precio").foregroundColor(Color.grayColor))
                    .textFieldEntradaType()
                    .focused($focusedField, equals: .precio(uuid))
                    .onSubmit {
                        focusedField = .aforo(uuid)  // Pasar foco al siguiente campo
                    }
                    .submitLabel(.next)
                
                TextField("", text: $viewModel.entradas[index].aforo, prompt: Text("Aforo").foregroundColor(Color.grayColor))
                    .textFieldEntradaType()
                    .focused($focusedField, equals: .aforo(uuid))
                    .onSubmit {
                        hideKeyboard()
                    }
                    .submitLabel(.next)
                    .padding(.bottom, 15)
            }
        }
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
                    Image(systemName: "photo")
                        .resizable()
                        .foregroundStyle(.white)
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                }
            }
            .onTapGesture {
                viewModel.showImagePicker.toggle()
            }
        }
    }
    
    @State private var selectedTime: Date?
    
    private var datePicker: some View {
        VStack {
            DatePicker("Selecciona una fecha", selection: Binding<Date> (
                get: { selectedTime ?? Date()
                },
                set: { newValue in
                    selectedTime = newValue
                    viewModel.eventDate = formattedDate(newValue)
                    showDatePicker.toggle()
                }),
                       displayedComponents: [.date]
            )
            .datePickerStyle(GraphicalDatePickerStyle())

            Button("Escoger fecha".uppercased()) {
                if selectedTime == nil {
                    viewModel.eventDate = formattedDate(Date())
                }
                showDatePicker.toggle()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
       
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
                // Botón de Subir Evento
                Button(action: {
                    viewModel.addEntrada()
                }) {
                    Text("+".uppercased())
                        .font(.system(size: 18, weight: .bold))
                }
                .frame(width: 40, height: 40)
                .background(Color.grayColor)
                .foregroundColor(.white)
                .clipShape(Circle())
                
                Button(action: {
                    viewModel.removeLastEntrada()
                }) {
                    Text("-".uppercased())
                        .font(.system(size: 18, weight: .bold))
                }
                .frame(width: 40, height: 40)
                .background(Color.grayColor)
                .foregroundColor(.white)
                .clipShape(Circle())
                
                Text("Añadir entradas al evento")
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Botón de Subir Evento
            Button(action: {
                viewModel.uploadEvent()
            }) {
                Text("Subir evento".uppercased())
                    .buttonStyle()
            }
            .padding(.bottom, 25)
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 10)
            .padding(.vertical, 12)
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 10)
            .padding(.vertical, 12)
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
