
import XCTest
import Combine
@testable import NightOut


final class TicketsPresenterTests: XCTestCase {
    
    var presenter: TicketsPresenterImpl!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        
        let actions = TicketsPresenterImpl.Actions(
            goToCompany: { _ in },
            goToEvent: { _ in },
            openHistoryTickets: {}
        )
        
        let useCases = TicketsPresenterImpl.UseCases()
        
        presenter = TicketsPresenterImpl(actions: actions, useCases: useCases)
        cancellables = []
    }

    override func tearDown() {
        presenter = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testFilterList_filtersBySearchTextAndGenre() {
       
        let expectation = self.expectation(description: "Filtered results set")
        
        let company = CompanyModel(username: "DiscotecaA", uid: "1")
        
        let fiesta1 = Fiesta(name: "Fiesta Techno", fecha: "16-06-2025", imageUrl: "", description: "", startTime: "22:00", endTime: "05:00", musicGenre: "Techno")
        let fiesta2 = Fiesta(name: "Fiesta Pop", fecha: "16-06-2025", imageUrl: "", description: "", startTime: "20:00", endTime: "03:00", musicGenre: "Pop")
        
        presenter.viewModel.companies = [(company, [fiesta1, fiesta2])]
        presenter.viewModel.selectedMusicGenre = TicketGenreType.techno
        presenter.viewModel.searchText = "DiscotecaA"
        
//        // Call filter
//        presenter.filterList()
//        
//        // Validate
//        XCTAssertEqual(presenter.viewModel.filteredResults.count, 1)
//        XCTAssertEqual(presenter.viewModel.filteredResults.first?.1.count, 1)
//        XCTAssertEqual(presenter.viewModel.filteredResults.first?.1.first?.name, "Fiesta Techno")
        
        presenter.viewModel.$filteredResults
                .dropFirst()
                .sink { filtered in
                    XCTAssertEqual(filtered.count, 1)
                    XCTAssertEqual(filtered.first?.1.count, 1)
                    XCTAssertEqual(filtered.first?.1.first?.name, "Fiesta Techno")
                    expectation.fulfill()
                }
                .store(in: &cancellables)

            presenter.filterList()

            wait(for: [expectation], timeout: 1.0)
    }
}
