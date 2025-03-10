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
                            .resizable()
                            .scaledToFill()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    viewModel.selectedTab = .search
                }) {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    viewModel.selectedTab = .publish
                }) {
                    VStack {
                        Image("camara")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                
                if FirebaseServiceImpl.shared.getImUser() {
                    Button(action: {
                        viewModel.selectedTab = .leagues
                    }) {
                        VStack {
                            Image("whisky_empty")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.white)
                                
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Button(action: {
                    viewModel.selectedTab = .calendar
                }) {
                    VStack {
                        Image("post_clicked")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 20, height: 20)
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
