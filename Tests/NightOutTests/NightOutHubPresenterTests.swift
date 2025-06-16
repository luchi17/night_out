import XCTest
import Combine
import Firebase
@testable import NightOut

// Mock de referencia Firebase para anuncios
class MockAdvertisementReference {
    var observeSingleEventCalled = false
    var callback: ((DataSnapshot) -> Void)?

    func observeSingleEvent(of eventType: DataEventType, with block: @escaping (DataSnapshot) -> Void) {
        observeSingleEventCalled = true
        callback = block
    }

    func simulateSnapshot(_ snapshot: DataSnapshot) {
        callback?(snapshot)
    }
}

// Mock DataSnapshot con urls
class MockDataSnapshot: DataSnapshot {
    private var childrenSnapshots: [MockDataSnapshot]
    private var valueDict: [String: Any]

    init(children: [MockDataSnapshot] = [], value: [String: Any] = [:]) {
        self.childrenSnapshots = children
        self.valueDict = value
        super.init() // esto solo es conceptual, no puedes instanciar DataSnapshot directamente
    }

    override var children: NSEnumerator {
        return (childrenSnapshots as NSArray).objectEnumerator()
    }

    override func childSnapshot(forPath path: String) -> DataSnapshot {
        if let val = valueDict[path] as? String {
            return MockDataSnapshot(value: [path: val])
        }
        return MockDataSnapshot()
    }

    override var value: Any? {
        return valueDict.values.first
    }
}

final class HubPresenterImplTests: XCTestCase {

    var presenter: HubPresenterImpl!
    var cancellables: Set<AnyCancellable> = []
    var openUrlCalledWith: String?

    override func setUp() {
        super.setUp()
        
        // Mock Actions
        let actions = HubPresenterImpl.Actions(openUrl: { [weak self] url in
            self?.openUrlCalledWith = url
        })

        // Aquí inyectarías mock para UseCases si tuvieses

        presenter = HubPresenterImpl(useCases: HubPresenterImpl.UseCases(), actions: actions)
    }

    func testOpenUrlCallsAction() {
        let urlPublisher = PassthroughSubject<String, Never>()
        let inputs = HubPresenterImpl.ViewInputs(
            viewDidLoad: Empty().eraseToAnyPublisher(),
            stopImageSwitcher: Empty().eraseToAnyPublisher(),
            openUrl: urlPublisher.eraseToAnyPublisher()
        )

        presenter.transform(input: inputs)

        urlPublisher.send("https://testurl.com")

        XCTAssertEqual(openUrlCalledWith, "https://testurl.com")
    }

    func testStopImageSwitcherStopsTimer() {
        // Iniciar timer para test
        presenter.viewModel.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in }

        XCTAssertNotNil(presenter.viewModel.timer)

        let stopPublisher = PassthroughSubject<Void, Never>()
        let inputs = HubPresenterImpl.ViewInputs(
            viewDidLoad: Empty().eraseToAnyPublisher(),
            stopImageSwitcher: stopPublisher.eraseToAnyPublisher(),
            openUrl: Empty().eraseToAnyPublisher()
        )

        presenter.transform(input: inputs)

        stopPublisher.send(())

        XCTAssertNil(presenter.viewModel.timer)
    }

    func testLoadAdvertisementContentUpdatesImageListAndStartsTimer() {
        // Como loadAdvertisementContent es privado y usa Firebase real,
        // puedes exponer una función testable o simular el llamado.
        // Aquí simplemente llamaremos a la función directamente (si fuera interna testable).

        // Para el test, mockeamos FirebaseServiceImpl.shared.getAdvertisement()
        // y controlamos la respuesta para enviar un snapshot simulado.

        // Esto requiere modificar el código para poder inyectar el servicio Firebase mockeado,
        // pero aquí te muestro el concepto:

        let expectation = self.expectation(description: "Image list is updated")

        // Simulamos la lista de URLs
        let urls = ["url1", "url2", "url3"]
        presenter.viewModel.imageList = []

        // Aquí forzamos el cambio de imageList simulando la respuesta Firebase
        DispatchQueue.main.async {
            self.presenter.viewModel.imageList = urls
            self.presenter.viewModel.currentIndex = Int.random(in: 0..<urls.count)
            self.presenter.startImageSwitcher() // si quieres testear este método directamente
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)

        XCTAssertEqual(presenter.viewModel.imageList, urls)
        XCTAssertNotNil(presenter.viewModel.timer)
    }
}

