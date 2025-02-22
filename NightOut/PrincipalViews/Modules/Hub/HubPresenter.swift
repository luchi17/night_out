import SwiftUI
import Combine
import Firebase

final class HubViewModel: ObservableObject {
    
    @Published var toast: ToastType?
    @Published var selectedGame: GameType?
    @Published var loading: Bool = false
    
    @Published var imageList: [String] = []
    @Published var currentIndex = 0
    
    let imageSwitchInterval: TimeInterval = 30.0
    var timer: Timer?
    
    init() {
        
    }
}

protocol HubPresenter {
    var viewModel: HubViewModel { get }
    func transform(input: HubPresenterImpl.ViewInputs)
}

final class HubPresenterImpl: HubPresenter {
    
    struct UseCases {
    }
    
    struct Actions {
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let stopImageSwitcher: AnyPublisher<Void, Never>
    }
    
    var viewModel: HubViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases

        viewModel = HubViewModel()
    }
    
    func transform(input: HubPresenterImpl.ViewInputs) {
        
        input
            .viewDidLoad
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.loadAdvertisementContent()
            }
            .store(in: &cancellables)
        
        input
            .stopImageSwitcher
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.stopImageSwitcher()
            }
            .store(in: &cancellables)
    }
}

extension HubPresenterImpl {
    private func loadAdvertisementContent() {
        let databaseRef = FirebaseServiceImpl.shared.getAdvertisement()

        databaseRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
                    var tempList: [String] = []

                    for child in snapshot.children {
                        if let childSnapshot = child as? DataSnapshot,
                           let contentUrl = childSnapshot.childSnapshot(forPath: "url").value as? String,
                           !contentUrl.isEmpty {
                            tempList.append(contentUrl)
                        }
                    }

                    DispatchQueue.main.async {
                        self.viewModel.imageList = tempList
                        if !self.viewModel.imageList.isEmpty {
                            self.viewModel.currentIndex = Int.random(in: 0..<self.viewModel.imageList.count)
                            self.startImageSwitcher()
                        }
                    }
                }
        }
    
    private func startImageSwitcher() {
        self.viewModel.timer = Timer.scheduledTimer(withTimeInterval: self.viewModel.imageSwitchInterval, repeats: true) { [weak self] _ in
            
            guard let self = self else { return }
            
            if !self.viewModel.imageList.isEmpty {
                    DispatchQueue.main.async {
                        self.viewModel.currentIndex = (self.viewModel.currentIndex + 1) % self.viewModel.imageList.count
                    }
                }
            }
        }

        private func stopImageSwitcher() {
            self.viewModel.timer?.invalidate()
            self.viewModel.timer = nil
        }
}


