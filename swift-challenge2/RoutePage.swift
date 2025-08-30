//
//  RoutePage.swift
//  swift-challenge2
//
//  Created by panaporn huadchai on 23/8/25.
//

import SwiftUI
import MapKit



struct RoutePage: View {
    @State var destination: MKMapItem
    @State private var route: MKRoute?
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        Map {
            // Adding the marker for the starting point
            Marker("Start", coordinate: self.locationManager.location)
            
            // Show the route if it is available
            if let route {
                MapPolyline(route)
                    .stroke(.blue, lineWidth: 5)
            }
        }
        .onAppear {
            getDirections()
        }
    }
    
    func getDirections() {
        self.route = nil
        
        // Create and configure the request
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: self.locationManager.location))
        request.destination = self.destination
        
        // Get the directions based on the request
        Task {
            let directions = MKDirections(request: request)
            let response = try? await directions.calculate()
            route = response?.routes.first
        }
    }
    
}

#Preview {
    RoutePage(destination: MKMapItem())
}
