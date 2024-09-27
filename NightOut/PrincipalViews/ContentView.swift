//
//  ContentView.swift
//  NightOut
//
//  Created by Apple on 27/9/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                }
            
            DiscotecasMapView() // Aquí agregas el mapa con las discotecas
                .tabItem {
                    Image(systemName: "magnifyingglass")
                }
            
            AddView()
                .tabItem {
                    Image(systemName: "heart")
                }
            
            DiscoView()
                .tabItem {
                    Image(systemName: "heart")
                }
            
            UserView()
                .tabItem {
                    Image(systemName: "person")
                }
        }
        .background(Color.white)
    }
}
