
//  ContentView.swift
//  NightOut
//
//  Created by Apple on 27/9/24.
//

import SwiftUI

struct DiscotecasMapView: View {
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        VStack {
            MapView(region: $locationManager.region, annotations: locationManager.discotecas)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    locationManager.locationManager.startUpdatingLocation() // Actualiza la ubicación al cargar la vista
                }
        }
    }
}
