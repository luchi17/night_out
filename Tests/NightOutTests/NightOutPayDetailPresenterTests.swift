//
//  NightOutPayDetailPresenter.swift
//  NightOut
//
//  Created by Apple on 16/6/25.
//

import XCTest
import Combine
@testable import NightOut

final class PayDetailPresenterTests: XCTestCase {
    
    private var cancellables: Set<AnyCancellable> = []
    
    func test_viewIsLoaded_updatesViewModel() {
        // Given
        let fiesta = Fiesta(name: "Fiesta Test", fecha: "2025-06-20", imageUrl: "", description: "", startTime: "", endTime: "", musicGenre: "")
     
        let entrada = Entrada(type: "General", price: 10.0, description: "", capacity: "")
        let model = PayDetailModel(fiesta: fiesta, quantity: 2, price: 20.0, entrada: entrada, companyUid: "company123")
        
        let expectation = XCTestExpectation(description: "Esperamos que el viewModel se configure correctamente")
        
        let actions = PayDetailPresenterImpl.Actions(
            goBack: {},
            openPDFPay: { _ in },
            navigateToHome: {}
        )
        
        let useCases = PayDetailPresenterImpl.UseCases()
        
        let sut = PayDetailPresenterImpl(actions: actions, useCases: useCases, model: model)
        
        // Publishers simulados
        let viewIsLoaded = PassthroughSubject<Void, Never>()
        let input = PayDetailPresenterImpl.Input(
            viewIsLoaded: viewIsLoaded.eraseToAnyPublisher(),
            goBack: Empty().eraseToAnyPublisher(),
            goBackFromExpired: Empty().eraseToAnyPublisher(),
            pagar: Empty().eraseToAnyPublisher()
        )
        
        // When
        sut.transform(input: input)
        viewIsLoaded.send(())
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let vm = sut.viewModel
            XCTAssertEqual(vm.users.count, 2, "Se deberían crear 2 usuarios vacíos.")
            XCTAssertEqual(vm.gastosGestion, 2.0, "Gastos de gestión mal calculados")
            XCTAssertEqual(vm.finalPrice, 22.0, "Precio final mal calculado (20 + 2)")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
