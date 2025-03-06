import Combine
import SwiftUI
import Firebase

struct Fiesta: Identifiable {
    let id = UUID()
    let name: String
    let fecha: String
    let imageUrl: String
    let description: String
    let startTime: String
    let endTime: String
    let musicGenre: String
}

class TicketsViewModel: ObservableObject {
    
    @Published var loading: Bool = false
    @Published var toast: ToastType?
    @Published var isFirstTime: Bool = true
    
    @Published var searchText: String = ""

    @Published var filteredResults:  [(CompanyModel, [Fiesta])] = []
    @Published var selectedMusicGenre: TicketGenreType?
    
    @Published var selectedDate: Date?
    @Published var selectedDateFilter: TicketDateFilterType?
    
    @Published var companies: [(CompanyModel, [Fiesta])] = []
    
    init() {
        
    }
}

protocol TicketsPresenter {
    var viewModel: TicketsViewModel { get }
    func transform(input: TicketsPresenterImpl.Input)
}

final class TicketsPresenterImpl: TicketsPresenter {
    var viewModel: TicketsViewModel
    
    struct Input {
        let viewIsLoaded: AnyPublisher<Void, Never>
    }
    
    struct UseCases {
        
    }
    
    struct Actions {
        //        let backToLogin: VoidClosure
    }
    
    // MARK: - Stored Properties
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    init(actions: Actions, useCases: UseCases) {
        self.viewModel = TicketsViewModel()
        self.actions = actions
        self.useCases = useCases
    }
    
    func transform(input: Input) {
        
        input
            .viewIsLoaded
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.loadEvents()
            }
            .store(in: &cancellables)
        
        viewModel.$selectedMusicGenre
            .map({ _ in })
            .merge(with: viewModel.$selectedDate.map({ _ in }), viewModel.$searchText.map({ _ in }))
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.viewModel.isFirstTime = presenter.viewModel.isFirstTime && presenter.viewModel.selectedDate == nil && presenter.viewModel.selectedMusicGenre == nil
                presenter.filterList()
            }
            .store(in: &cancellables)
    }
    
//    func filterEvents() {
//        if viewModel.selectedDate == nil && viewModel.selectedMusicGenre == nil {
//            return
//        }
//        
//        print("Filtrando discos por \(viewModel.selectedMusicGenre?.title) y fecha \(viewModel.selectedDate)")
//        
//        viewModel.events = viewModel.events.filter { event in
//            let matchesDate = viewModel.selectedDate == nil || formattedDate(viewModel.selectedDate!) == event.fecha
//            let matchesGenre = viewModel.selectedMusicGenre == nil || event.musicGenre == viewModel.selectedMusicGenre?.title.lowercased()
//            return matchesDate && matchesGenre
//        }
//    }
    
    private func filterList() {
        let query = viewModel.searchText.lowercased()
        
        let filteredResults = viewModel.companies.map { data -> (CompanyModel, [Fiesta]) in
            
            let company = data.0
            let fiestas = data.1
            
            let filteredFiestas = fiestas.filter { fiesta in
                //
                var matchesDate: Bool = {
                    
                    if let dateFilter = viewModel.selectedDateFilter {
                        switch dateFilter {
                        case .week:
                            let today = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
                            let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date())?.timeIntervalSince1970 ?? today
                            
                            let dateParts = fiesta.fecha.split(separator: "-").compactMap { Int($0) }
                            if dateParts.count == 3,
                               let day = dateParts.first,
                               let month = dateParts.dropFirst().first,
                               let year = dateParts.last {
                                
                                var fiestaDateComponents = DateComponents()
                                fiestaDateComponents.year = year
                                fiestaDateComponents.month = month
                                fiestaDateComponents.day = day
                                
                                if let fiestaDate = Calendar.current.date(from: fiestaDateComponents)?.timeIntervalSince1970 {
                                    return fiestaDate >= today && fiestaDate <= endOfWeek
                                }
                            }
                            return false
                        case .day(let dateString):
                            return fiesta.fecha == dateString
                        default:
                            return fiesta.fecha == self.formattedDate(Date())
                        }
                        
                    } else {
                        return true
                    }
                }()
                
                var matchesMusic: Bool = {
                    if let genre = viewModel.selectedMusicGenre {
                        fiesta.musicGenre.caseInsensitiveCompare(genre.title) == .orderedSame
                    } else {
                        true // Si no hay filtro de música, cualquier género es válido
                    }
                }()
                
                return matchesDate && matchesMusic
            }
            
            return (company, filteredFiestas)
            
        }
        .filter({ data in
                let company = data.0
                let fiestas = data.1
                
                let matchesSearch = company.username?.range(of: query, options: .caseInsensitive) != nil
                let hasValidFiestas = viewModel.selectedDate != nil || viewModel.selectedMusicGenre != nil
                
                if hasValidFiestas {
                    return fiestas.isEmpty == false && matchesSearch
                } else {
                    return matchesSearch
                }
                
        })
        
        self.viewModel.filteredResults = filteredResults
        
        //        filteredCompanies.removeAll()
        //        filteredCompanies.append(contentsOf: filteredResults)
    }
    
    
    func loadEvents() {
        
        let today = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970 * 1000 // Timestamp de hoy a las 00:00h
        
        FirebaseServiceImpl.shared.getCompanies().observeSingleEvent(of: .value) { [weak self] snapshot in
            
            guard let self = self else { return }
            
            self.viewModel.companies.removeAll()
            
            for companySnapshot in snapshot.children {
                
                var tempEvents: [Fiesta] = []
                
                guard let companyData = companySnapshot as? DataSnapshot,
                      let company = try? companyData.data(as: CompanyModel.self) else {
                    continue
                }
                
                for dateSnapshot in companyData.childSnapshot(forPath: "Entradas").children {
                    
                    guard let dateData = dateSnapshot as? DataSnapshot else {
                        return
                    }
                    
                    let fecha = dateData.key
                    
                    print("📅 Fecha en Firebase: \(fecha)")
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd-MM-yyyy"
                    
                    if let eventDate = dateFormatter.date(from: fecha), eventDate.timeIntervalSince1970 * 1000 >= today {
                        
                        for eventSnapshot in dateData.children {
                            
                            guard let eventData = eventSnapshot as? DataSnapshot else {
                                return
                            }
                            
                            let eventName = eventData.key
                            let eventInfo = eventData.value as? [String: Any] ?? [:]
                            
                            let imageUrl = eventInfo["image_url"] as? String ?? ""
                            let description = eventInfo["description"] as? String ?? "Sin descripción"
                            let startTime = eventInfo["start_time"] as? String ?? "No disponible"
                            let endTime = eventInfo["end_time"] as? String ?? "No disponible"
                            let musicGenre = eventInfo["musica"] as? String ?? "No especificado"
                            
                            let fiesta = Fiesta(
                                name: eventName,
                                fecha: fecha,
                                imageUrl: imageUrl,
                                description: description,
                                startTime: startTime,
                                endTime: endTime,
                                musicGenre: musicGenre
                            )
                            
                            tempEvents.append(fiesta)
                            
                            print("🎉 Fiesta agregada: \(fiesta.name) - Fecha: \(fiesta.fecha)")
                        }
                        
                    } else {
                        print("⏳ Evento descartado (fecha pasada): \(fecha)")
                    }
                }
                
                print("🏢 \(company.username) - Total fiestas cargadas: \(tempEvents.count)")
                self.viewModel.companies.append((company, tempEvents)) // ✅ Asignamos solo las fiestas futuras a la discoteca
            }
            
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        var calendar = Calendar.current
        
        let day = String(format: "%02d", calendar.component(.day, from: date))
        let month = String(format: "%02d", calendar.component(.month, from: date))
        let year = calendar.component(.year, from: date)
        return "\(day)-\(month)-\(year)"
    }
}
