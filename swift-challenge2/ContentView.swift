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
        NavigationStack {
            ZStack {
                Map(coordinateRegion: .constant(MKCoordinateRegion(center: locationManager.location, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))), showsUserLocation: true)
                    .clipShape(.circle) // Making the small map a circle
                    .frame(width: 250, height: 250)
                    .shadow(radius: 15)
            }
            NavigationLink ("Done! Next >") {
                RouteInputView()
                    .navigationBarBackButtonHidden(true)
            }
            .padding()
        }
        .environmentObject(locationManager)
    }
}

#Preview {
    ContentView()
}
