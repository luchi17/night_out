import SwiftUI

struct TabViewScreen: View {
    
    private let presenter: TabViewPresenter
    @ObservedObject private var viewModel: TabViewModel
    
    init(presenter: TabViewPresenter) {
        self.presenter = presenter
        self.viewModel = presenter.viewModel
    }
    
    var body: some View {
        VStack(spacing: 0) {
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
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    presenter.onTapSelected(tabType: .search)
                }) {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    presenter.onTapSelected(tabType: .publish)
                }) {
                    VStack {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    presenter.onTapSelected(tabType: .map)
                }) {
                    VStack {
                        Image(systemName: "map")
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    presenter.onTapSelected(tabType: .user)
                }) {
                    VStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color(.black))
        }
        .navigationBarBackButtonHidden()
    }
}
