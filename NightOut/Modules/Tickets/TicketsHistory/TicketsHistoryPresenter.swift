import Combine
import SwiftUI
import Firebase
import PDFKit
import CoreImage
import UIKit
import FirebaseDatabase


class TicketsHistoryViewModel: ObservableObject {
    
    @Published var loading: Bool = false
    @Published var toast: ToastType?
    
    @Published var ticketsList: [TicketHistoryPDFModel] = []
    
    @Published var ticketToShow: TicketHistoryPDFModel?
    @Published var bottomSheetToShow: String?
    
}

protocol TicketsHistoryPresenter {
    var viewModel: TicketsHistoryViewModel { get }
    func transform(input: TicketsHistoryPresenterImpl.Input)
}

final class TicketsHistoryPresenterImpl: TicketsHistoryPresenter {
    var viewModel: TicketsHistoryViewModel
    
    struct Input {
        let viewIsLoaded: AnyPublisher<Void, Never>
        let goBack: AnyPublisher<Void, Never>
    }
    
    struct UseCases {
        
    }
    
    struct Actions {
        let goBack: VoidClosure
    }
    
    // MARK: - Stored Properties
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    
    // MARK: - Lifecycle
    init(actions: Actions, useCases: UseCases) {
        
        self.viewModel = TicketsHistoryViewModel()
        self.actions = actions
        self.useCases = useCases
        
    }
    
    func transform(input: Input) {
        
        input
            .viewIsLoaded
            .withUnretained(self)
            .sink { presenter, _ in
                
                presenter.viewModel.loading = true
                
                presenter.fetchUserTickets { tickets in
                    presenter.viewModel.loading = false
                    presenter.viewModel.ticketsList = tickets
                }
            }
            .store(in: &cancellables)
        
        input
            .goBack
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.actions.goBack()
            }
            .store(in: &cancellables)
        
        
    }
    
    func fetchUserTickets(completion: @escaping ([TicketHistoryPDFModel]) -> Void) {
        guard let currentUserUid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            print("Usuario no autenticado")
            completion([])
            return
        }
        
        let dbRef = Database.database().reference()
        var ticketsReference: DatabaseReference
        
        if FirebaseServiceImpl.shared.getImUser() {
            ticketsReference = dbRef.child("Users").child(currentUserUid).child("MisEntradas")
        } else {
            ticketsReference = dbRef.child("Company_Users").child(currentUserUid).child("MisEntradas")
        }

        ticketsReference.getData { error, snapshot in
            var tickets: [TicketHistoryPDFModel] = []
            
            if error != nil {
                DispatchQueue.main.async {
                    self.viewModel.toast = .custom(.init(title: "", description: "Error al cargar los tickets: \(error?.localizedDescription ?? "Desconocido")", image: nil))
                }
                completion([])
                return
            }
            guard let snapshot = snapshot, snapshot.exists() else {
                completion([])
                return
            }
            
            for child in snapshot.children.allObjects as? [DataSnapshot] ?? [] {
                let ticketUid = child.key
                let fecha = (child.value as? [String: Any])?["fecha"] as? String ?? "Fecha no disponible"
                let personName = (child.value as? [String: Any])?["nombre"] as? String ?? "Nombre no disponible"
                
//                /var/mobile/Containers/Data/Application/ECE6BF95-FEE9-4A25-A9E5-CC360F2461A9/Documents/EventTickets/ticket_Mari_TICKET-2.pdf
                let pdfURL: URL? = {
                    let pdfFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                        .appendingPathComponent("EventTickets")
                    
                    let pdfFilename = pdfFolder.appendingPathComponent("ticket_\(personName)_\(ticketUid).pdf")
                    
                    if FileManager.default.fileExists(atPath: pdfFilename.path()) {
                        return pdfFilename
                    } else {
                        return nil
                    }
                }()

                let model = TicketHistoryPDFModel(
                    date: fecha,
                    ticketNumber: ticketUid,
                    url: pdfURL
                )
                tickets.append(model)
            }
            
            completion(tickets)
        }
    }
}

struct TicketHistoryPDFModel: Hashable {
    let date: String
    let ticketNumber: String
    let url: URL?
}
