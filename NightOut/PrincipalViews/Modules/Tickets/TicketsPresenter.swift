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
    @Published var events: [Fiesta] = []
    @Published var selectedMusicGenre: TicketGenreType?
    
    @Published var selectedDate: Date?
    
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
            .merge(with: viewModel.$selectedDate.map({ _ in }))
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.viewModel.isFirstTime = presenter.viewModel.isFirstTime && presenter.viewModel.selectedDate == nil && presenter.viewModel.selectedMusicGenre == nil
                presenter.filterEvents()
            }
            .store(in: &cancellables)
    }
    
    func filterEvents() {
        if viewModel.selectedDate == nil && viewModel.selectedMusicGenre == nil {
            return
        }
        
        print("Filtrando discos por \(viewModel.selectedMusicGenre?.title) y fecha \(viewModel.selectedDate)")
        
        viewModel.events = viewModel.events.filter { event in
            let matchesDate = viewModel.selectedDate == nil || formattedDate(viewModel.selectedDate!) == event.fecha
            let matchesGenre = viewModel.selectedMusicGenre == nil || event.musicGenre == viewModel.selectedMusicGenre?.title.lowercased()
            return matchesDate && matchesGenre
        }
    }
    
    func loadEvents() {
        
        let today = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970 * 1000 // Timestamp de hoy a las 00:00h
        
        FirebaseServiceImpl.shared.getCompanies().observeSingleEvent(of: .value) { snapshot in
            var tempEvents: [Fiesta] = []
            
            for companySnapshot in snapshot.children {
                
                guard let companyData = companySnapshot as? DataSnapshot else {
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
                    
                    DispatchQueue.main.async {
                        self.viewModel.events = tempEvents
                    }
                    
                }
                
            }
        }
        
    }
    
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
}
