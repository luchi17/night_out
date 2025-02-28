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
                    viewModel.selectedTab = .home
                }) {
                    VStack {
                        Image(systemName: "house.fill")
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    viewModel.selectedTab = .search
                }) {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    viewModel.selectedTab = .publish
                }) {
                    VStack {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    viewModel.selectedTab = .leagues
                }) {
                    VStack {
                        Image("leaguesIcon")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 25, height: 25)
                            .foregroundColor(.white)
                            
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    viewModel.selectedTab = .user
                }) {
                    VStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color.blackColor)
        }
        .navigationBarBackButtonHidden()
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
