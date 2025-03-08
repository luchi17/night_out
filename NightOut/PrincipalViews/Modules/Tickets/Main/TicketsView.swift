import SwiftUI
import Combine

struct TicketsView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let logoutPublisher = PassthroughSubject<Void, Never>()
    private let filterPublisher = PassthroughSubject<Void, Never>()
    private let goToCompanyPublisher = PassthroughSubject<(CompanyModel, [Fiesta]), Never>()
    private let goToEventPublisher = PassthroughSubject<(CompanyModel, Fiesta), Never>()
    
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
                    .frame(width: 400, height: 300)
                    .foregroundColor(.white)
                    .padding(.top, 50)
                
                Spacer()
                
            } else {
                ScrollView(.vertical) {
                    VStack {
                        ForEach(viewModel.filteredResults, id: \.0.uid) { result in
                            EventRow(
                                company: result,
                                goToCompany: goToCompanyPublisher.send,
                                goToEvent: goToEventPublisher.send
                            )
                        }
                    }
                }
                .padding(.top, 20)
                .scrollIndicators(.hidden)
            }
        }
        .padding(.horizontal, 20)
        .background(
            Color.blackColor.ignoresSafeArea()
        )
        .sheet(isPresented: $isGenreVisible) {
            GenreSheetView(genre: $viewModel.selectedMusicGenre) {
                isGenreVisible = false
                filterPublisher.send()
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $isCalendarVisible, onDismiss: {
            filterPublisher.send()
        }) {
            CalendarPicker(
                selectedDateFilter: $viewModel.selectedDateFilter
            )
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
        .onTapGesture {
            hideKeyboard()
        }
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
                .onSubmit {
                    hideKeyboard()
                }
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
                if viewModel.selectedDateFilter != nil {
                    viewModel.selectedDateFilter = nil
                    filterPublisher.send()
                } else {
                    isCalendarVisible.toggle()
                }
            }) {
                HStack(spacing: 3) {
                    if let date = viewModel.selectedDateFilter {
                        switch date {
                        case .day(let dateString):
                            Text(dateString)
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .bold))
                        case .week:
                            Text("ESTA SEMANA")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .bold))
                        case .today:
                            Text("HOY")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .bold))
                        case .tomorrow:
                            Text("MAÑANA")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .bold))
                        }
                    
                        Image("borrar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(.black)
                    } else {
                        Text("Fecha".uppercased())
                            .foregroundColor(.black)
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .frame(minHeight: 40)
                .padding(.horizontal, 8)
                .background(viewModel.selectedDateFilter != nil ? Color.yellow : Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(viewModel.selectedDateFilter != nil ? Color.black : Color.yellow, lineWidth: 2)
                )
            }
            
            Button(action: {
              if viewModel.selectedMusicGenre != nil {
                  viewModel.selectedMusicGenre = nil
                  filterPublisher.send()
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
                .frame(minHeight: 40)
                .padding(.horizontal, 8)
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
            viewIsLoaded: viewDidLoadPublisher.eraseToAnyPublisher(),
            filter: filterPublisher.eraseToAnyPublisher(),
            goToCompany: goToCompanyPublisher.eraseToAnyPublisher(),
            goToEvent: goToEventPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        let day = String(format: "%02d", calendar.component(.day, from: date))
        let month = String(format: "%02d", calendar.component(.month, from: date))
        let year = calendar.component(.year, from: date)
        return "\(day)-\(month)-\(year)"
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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


enum TicketDateFilterType: Hashable {
    case day(String)
    case week
    case today
    case tomorrow
    
    var title: String {
        switch self {
        case .day(let string):
            return string.uppercased()
        case .week:
            return "ESTA SEMANA"
        case .today:
            return "HOY"
        case .tomorrow:
            return "MAÑANA"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
    }
    
    static func == (lhs: TicketDateFilterType, rhs: TicketDateFilterType) -> Bool {
        return lhs.title == rhs.title
    }
}
