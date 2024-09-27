//
//  ContentView.swift
//  NightOut
//
//  Created by Apple on 27/9/24.
//

import SwiftUI

struct DiscoView: View {
    var body: some View {
        NavigationView {
                    VStack {
                        Text("Disco View")
//                        NavigationLink(destination: DetailView()) {
//                            Text("Go to Detail")
//                        }
                    }
                    .navigationTitle("Disco")
                }
    }
}


#Preview {
    DiscoView()
}
