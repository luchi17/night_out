import SwiftUI

struct TabViewScreen: View {
    
    private let presenter: TabViewPresenter
    @ObservedObject private var viewModel: TabViewModel
    
    init(presenter: TabViewPresenter) {
        self.presenter = presenter
        self.viewModel = presenter.viewModel
    }
    
    var body: some View {
        VStack {
            // Contenido principal basado en la pestaña seleccionada
            Spacer()
            
            viewModel.viewToShow
            // Barra de navegación personalizada
            HStack {
                Button(action: {
                    presenter.onTapSelected(tabType: .home)
                }) {
                    VStack {
                        Image(systemName: "house.fill")
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    presenter.onTapSelected(tabType: .search)
                }) {
                    VStack {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    presenter.onTapSelected(tabType: .publish)
                }) {
                    VStack {
                        Image(systemName: "plus")
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    presenter.onTapSelected(tabType: .map)
                }) {
                    VStack {
                        Image(systemName: "map")
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    presenter.onTapSelected(tabType: .user)
                }) {
                    VStack {
                        Image(systemName: "person.fill")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color(.white))
        }
        .navigationBarBackButtonHidden()
    }
}
