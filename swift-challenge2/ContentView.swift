//
//  ContentView.swift
//  swift-challenge2
//
//  Created by panaporn huadchai on 2/8/25.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        ZStack {
            if let location = locationManager.location {
                Map(coordinateRegion: .constant(MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))), showsUserLocation: true)
                    .clipShape(.circle) // Making the small map a circle
                    .frame(width: 250, height: 250)
                    .shadow(radius: 10)
            } else {
                ProgressView("Hang tight - we're currently locating you!")
                    .padding()
            }
        }
    }
}

#Preview {
    ContentView()
}
