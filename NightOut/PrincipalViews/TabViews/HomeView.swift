//
//  ContentView.swift
//  NightOut
//
//  Created by Apple on 27/9/24.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
                    VStack {
                        Text("Home View")
//                        NavigationLink(destination: DetailView()) {
//                            Text("Go to Detail")
//                        }
                    }
                    .navigationTitle("Home")
                }
    }
}


#Preview {
    HomeView()
}
