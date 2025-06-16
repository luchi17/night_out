import XCTest
@testable import NightOut

final class TicketsViewModelTests: XCTestCase {
    var viewModel: TicketsViewModel!

    override func setUp() {
        super.setUp()
        viewModel = TicketsViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testInitialValues() {
        XCTAssertFalse(viewModel.loading)
        XCTAssertNil(viewModel.toast)
        XCTAssertTrue(viewModel.isFirstTime)
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertTrue(viewModel.filteredResults.isEmpty)
        XCTAssertNil(viewModel.selectedMusicGenre)
        XCTAssertNil(viewModel.selectedDateFilter)
        XCTAssertTrue(viewModel.companies.isEmpty)
        XCTAssertNil(viewModel.lastFetchTime)
    }
}

