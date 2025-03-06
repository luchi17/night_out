import SwiftUI
import Combine

struct TicketsView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let logoutPublisher = PassthroughSubject<Void, Never>()
    
    @State private var isCalendarVisible = false
    @State private var isGenreVisible = false
    @State private var isHistoryVisible = false
    
    @ObservedObject var viewModel: TicketsViewModel
    let presenter: TicketsPresenter
    
    init(
        presenter: TicketsPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        VStack {
            topView
                .padding(.top, 50)
            
            topTextfield
            
            // Filtros de Fecha y Música
            buttonsView
                .padding(.top, 12)
            
            Spacer()
            // Lista de eventos
#warning("Change image")
            if viewModel.isFirstTime {
                Image("descubrirEventos")
                    .resizable()
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .foregroundColor(.white)
                    .padding(.top, 50)
                
                Spacer()
                
            } else {
                ScrollView(.vertical) {
                    VStack {
                        ForEach(viewModel.events, id: \.id) { event in
                            EventRow(event: event)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .background(
            Color.blackColor.ignoresSafeArea()
        )
        .sheet(isPresented: $isGenreVisible) {
            GenreSheetView(genre: $viewModel.selectedMusicGenre) {
                isGenreVisible = false
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $isCalendarVisible) {
            CalendarPicker(selectedDate: $viewModel.selectedDate)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
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
            Spacer()
                .frame(maxWidth: .infinity)
            
            Text("Calendario")
                .foregroundStyle(.white)
                .font(.system(size: 20, weight: .bold))
                .frame(maxWidth: .infinity)
            
            HStack {
                Spacer()
                    .frame(maxWidth: .infinity)
                Button(action: {
                    isHistoryVisible.toggle()
                }) {
                    Image("ticket")
                        .resizable()
                        .frame(width: 45, height: 45)
                        .foregroundColor(.white)
                }
                .padding(.trailing, 20)
            }
        }
        .frame(height: 50)
    }
    
    var topTextfield: some View {
        
        HStack(spacing: 0) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .padding(.leading, 8)
            
            TextField("", text: $viewModel.searchText, prompt: Text("Busca tu discoteca o fiesta").foregroundColor(.white))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.all, 8)
                .foregroundColor(.white)
                .accentColor(.white)
                .autocorrectionDisabled()
            
            Spacer()
        }
        .frame(height: 40)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.grayColor.opacity(0.5))
                .stroke(Color.white, lineWidth: 2)
        )
        .shadow(radius: 5)
    }
    
    var buttonsView: some View {
        HStack {
            Button(action: {
                print("selectedDate2")
                print(viewModel.selectedDate)
                if let music = viewModel.selectedDate {
                    viewModel.selectedDate = nil
                } else {
                    isCalendarVisible.toggle()
                }
            }) {
                HStack(spacing: 3) {
                    if let date = viewModel.selectedDate {
                        Text(formattedDate(viewModel.selectedDate!))
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                        Image("borrar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(.black)
                    } else {
                        Text("Fecha".uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .padding(.all, 6)
                .background(viewModel.selectedDate != nil ? Color.yellow : Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(viewModel.selectedDate != nil ? Color.black : Color.yellow, lineWidth: 2)
                )
            }
            
            Button(action: {
                
              if let music = viewModel.selectedMusicGenre {
                viewModel.selectedMusicGenre = nil
              } else {
                  isGenreVisible.toggle()
              }
            }) {
                HStack(spacing: 3) {
                    if let music = viewModel.selectedMusicGenre {
                        Text(music.title.uppercased())
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                        Image("borrar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(.black)
                    } else {
                        Text("Música".uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .padding(.all, 8)
                .background(viewModel.selectedMusicGenre != nil ? Color.yellow : Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(viewModel.selectedMusicGenre != nil ? Color.black : Color.yellow, lineWidth: 2)
                )
            }
            
            Spacer()
        }
    }
}


private extension TicketsView {
    
    func bindViewModel() {
        let input = TicketsPresenterImpl.Input(
            viewIsLoaded: viewDidLoadPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date).uppercased()
    }
    
}

struct CalendarPicker: View {
    @Binding var selectedDate: Date?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Picker("Opciones de fecha", selection:  Binding {
                selectedDate ?? Date()
            } set: { newValue in
                selectedDate = newValue
            }) {
                Text("Hoy").tag(Calendar.current.startOfDay(for: Date()))
                Text("Mañana").tag(Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
                Text("Esta semana").tag(Calendar.current.date(byAdding: .day, value: 7, to: Date())!)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            DatePicker("Selecciona una fecha", selection:  Binding {
                return selectedDate ?? Date()
            } set: { newValue in
                selectedDate = newValue
            }, displayedComponents: [.date])
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()
            
            Button(action: {
                if selectedDate == nil {
                    selectedDate = Date()
                }
                print("selectedDate1")
                print(selectedDate)
                dismiss()
            }) {
                Text("Escoger fecha".uppercased())
                    .foregroundStyle(.white)
            }
            .padding()
            
            Button("Cerrar") {
                dismiss()
            }
            .padding()
        }
    }
}


struct EventRow: View {
    let event: Fiesta
    
    var body: some View {
        HStack {
            Text(event.name)
                .foregroundColor(.white)
            Spacer()
            Text(event.fecha)
                .foregroundColor(Color.grayColor)
        }
        .padding()
        .background(Color.grayColor.opacity(0.2))
        .cornerRadius(10)
    }
}

struct GenreSheetView: View {
    
    @Binding var genre: TicketGenreType?
    var close: VoidClosure
    
    var body: some View {
        VStack {
            ZStack {
                Color.grayColor
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    
                    Text("Selecciona un género musical")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(TicketGenreType.reggaeton.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            genre = .reggaeton
                            close()
                        }
                    
                    Text(TicketGenreType.pop.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            genre = .pop
                            close()
                        }
                    
                    Text(TicketGenreType.techno.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            genre = .techno
                            close()
                        }
                    
                    Text(TicketGenreType.jazz.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            genre = .jazz
                            close()
                        }
                    
                    Text(TicketGenreType.clasica.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            genre = .clasica
                            close()
                        }
                    
                    Text(TicketGenreType.latina.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            genre = .latina
                            close()
                        }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

enum TicketGenreType {
    case reggaeton
    case pop
    case techno
    case jazz
    case clasica
    case latina
    
    var title: String {
        switch self {
        case .reggaeton:
            return "Reggaeton"
        case .pop:
            return "Pop"
        case .techno:
            return "Techno"
        case .jazz:
            return "Jazz"
        case .clasica:
            return "Clasica"
        case .latina:
            return "Latina"
        }
    }
    
    init?(rawValue: String) {
        if rawValue == TicketGenreType.reggaeton.title {
            self = .reggaeton
        }
        else if rawValue == TicketGenreType.pop.title {
            self = .pop
        }
        else if rawValue == TicketGenreType.techno.title {
            self = .techno
        }
        else if rawValue == TicketGenreType.jazz.title {
            self = .jazz
        }
        else if rawValue == TicketGenreType.clasica.title {
            self = .clasica
        }
        else {
            self = .latina
        }
    }
}
