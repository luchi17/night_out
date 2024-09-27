//
//  ContentView.swift
//  NightOut
//
//  Created by Apple on 27/9/24.
//

import SwiftUI

struct ContentView: View {
    
    @State private var selectedTab: Int = 0
    
    var body: some View {
        VStack {
            // Contenido principal basado en la pestaña seleccionada
            Spacer()
            switch selectedTab {
            case 0:
                HomeView()
            case 1:
                SearchView()
            case 2:
                AddView()
            case 3:
                DiscotecasMapView()
            default:
                UserView()
            }
            Spacer()
            
            // Barra de navegación personalizada
            HStack {
                Button(action: {
                    selectedTab = 0
                }) {
                    VStack {
                        Image(systemName: "house.fill")
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    selectedTab = 1
                }) {
                    VStack {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    selectedTab = 2
                }) {
                    VStack {
                        Image(systemName: "plus")
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    selectedTab = 3
                }) {
                    VStack {
                        Image(systemName: "map")
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    selectedTab = 4
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
