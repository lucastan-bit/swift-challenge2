//
//  RouteInputView.swift
//  swift-challenge2
//
//  Created by T Krobot on 16/8/25.
//

import SwiftUI
import MapKit

struct RouteInputView: View {
    let singapore = CLLocationCoordinate2D(
        latitude: 1.3521,
        longitude: 103.8198
        )
    @State var text = ""
    @State private var searchResults: [MKMapItem] = []
    
    
    
    var body: some View {
        NavigationStack {
            Text("Let's plan your route!")
                .font(.largeTitle)
            TextField("Type in your destination!", text: $text)
                .textFieldStyle(.roundedBorder)
                .padding()
                .overlay(alignment: .bottom) {
                    
                }
            

            Button("View Search Results") {
                search(for: text)
            }
        }
    }
    private func search(for query: String) {
            // 3.
        let request = MKLocalSearch.Request()
        // 4.
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        request.region = MKCoordinateRegion(
            center: singapore,
            span: MKCoordinateSpan(
                latitudeDelta: 0.0125,
                longitudeDelta: 0.0125
            )
        )
        
        // 5.
        Task {
                // 6.
            let search = MKLocalSearch(request: request)
            // 7.
            let response = try? await search.start()
            // 8.
            searchResults = response?.mapItems ?? []
            print (searchResults)
        }
    }
}

#Preview {
    RouteInputView()
}
