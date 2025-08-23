//
//  RoutePage.swift
//  swift-challenge2
//
//  Created by panaporn huadchai on 23/8/25.
//

import SwiftUI
import MapKit



struct RoutePage: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
   
    
    var body: some View {
        VStack() {
            Map(coordinateRegion: $region)
                .edgesIgnoringSafeArea(.all)
            
            
            Text("test text")
                .padding()
                .font(.system(size: 60))
            
            
        
            
            
                
                
                
               
                    
            
        }
    }
}
#Preview {
    RoutePage()
}
