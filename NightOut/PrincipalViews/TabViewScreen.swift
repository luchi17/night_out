//
//  ContentView.swift
//  NightOut
//
//  Created by Apple on 27/9/24.
//

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
            
            // Barra de navegación personalizada
            HStack {
                Button(action: {
                    presenter.openTab(.home)
                }) {
                    VStack {
                        Image(systemName: "house.fill")
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    presenter.openTab(.search)
                }) {
                    VStack {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    presenter.openTab(.publish)
                }) {
                    VStack {
                        Image(systemName: "plus")
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    presenter.openTab(.map)
                }) {
                    VStack {
                        Image(systemName: "map")
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    presenter.openTab(.user)
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
    }
}
