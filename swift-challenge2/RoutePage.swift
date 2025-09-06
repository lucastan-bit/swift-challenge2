import SwiftUI
import MapKit
import CoreLocation

struct RoutePage: View {
    let destination: MKMapItem
    let travelTime: Double
    let transportMode: String
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var routes: [MKRoute] = []
    @State private var startCoordinate: CLLocationCoordinate2D?
    @State private var endCoordinate: CLLocationCoordinate2D
    @State private var isLoading = false
    @State private var detourPoints: [CLLocationCoordinate2D] = []
    @State private var locationUpdateCounter = 0 // track em location updates
    
    // LETS USE UR LOCATION MANAGER
    @EnvironmentObject var locationManager: LocationManager
    
    init(destination: MKMapItem, travelTime: Double, transportMode: String) {
        self.destination = destination
        self.travelTime = travelTime
        self.transportMode = transportMode
        self._endCoordinate = State(initialValue: destination.placemark.coordinate)
    }
    
    var body: some View {
        VStack {
            // this shows the time.
            VStack {
                Text("Route Duration: \(Int(travelTime)) minutes")
                    .font(.headline)
            }
            .padding()
            .onChange(of: travelTime) {
                if startCoordinate != nil {
                    isLoading = true
                    calculateExtendedRoute()
                }
            }
            
            ZStack {
                Map(position: $cameraPosition) {
                    // route drawer. Blue is the normal route, orange is alternate routes (which appears if the duration is long
                    ForEach(routes.indices, id: \.self) { index in
                        MapPolyline(routes[index])
                            .stroke(index == 0 ? .blue : .orange,
                                   lineWidth: index == 0 ? 6 : 4)
                    }
                    
                    // detuors
                    ForEach(detourPoints.indices, id: \.self) { index in
                        Annotation("Detour \(index + 1)", coordinate: detourPoints[index]) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple)
                                    .frame(width: 20, height: 20)
                                
                            }
                        }
                    }
                    
                    // start and end markers
                    if let startCoordinate = startCoordinate {
                        Annotation("Start", coordinate: startCoordinate) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.green)
                                .font(.title)
                        }
                    }
                    
                    Annotation("End", coordinate: endCoordinate) {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.red)
                            .font(.title)
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                
                if isLoading {
                    ProgressView("Creating \(Int(travelTime)) min route...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(10)
                }
            }
        }
        .onAppear {
            // Use the location from your existing LocationManager
            startCoordinate = locationManager.location
            calculateExtendedRoute()
            
            // Set up a timer to check for location updates periodically
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                locationUpdateCounter += 1
                startCoordinate = locationManager.location
            }
        }
        .onChange(of: locationUpdateCounter) { oldValue, newValue in
            // This will trigger when the location updates
            if routes.isEmpty {
                calculateExtendedRoute()
            }
        }
    }
    
    // MARK: - calculating the extendeed route
    
    private func calculateExtendedRoute() {
        guard let startCoordinate = startCoordinate else { return }
        
        routes.removeAll()
        detourPoints.removeAll()
        isLoading = true
        
        // how long is the original route first?
        calculateBaseRoute(from: startCoordinate, to: endCoordinate) { baseRoute in
            guard let baseRoute = baseRoute else {
                isLoading = false
                return
            }
            
            self.routes.append(baseRoute)
            let baseTime = baseRoute.expectedTravelTime / 60 // convert to minutes
            
            if baseTime >= travelTime {
                // what if base route is long enough already? (if the route duration put in is shorter than the duration
                self.updateCameraPosition()
                self.isLoading = false
            } else {
                // wanna make it longer? add deturos. (if the route duration is longer than theduration
                self.addDetoursToRoute(baseTime: baseTime, start: startCoordinate)
            }
        }
    }
    
    private func calculateBaseRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, completion: @escaping (MKRoute?) -> Void) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = transportTypeForMode(transportMode)
        
        let directions = MKDirections(request: request)
        
        //what if theres an error
        directions.calculate { response, error in
            guard let response = response, let route = response.routes.first else {
                print("Error calculating base route: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            completion(route)
        }
    }
    
    private func transportTypeForMode(_ mode: String) -> MKDirectionsTransportType {
        switch mode {
        case "Walking": return .walking
        case "Bus", "MRT": return .transit
        case "Car": return .automobile
        default: return .automobile
        }
    }
    
    private func addDetoursToRoute(baseTime: Double, start: CLLocationCoordinate2D) {
        let additionalTimeNeeded = travelTime - baseTime
        let numberOfDetours = Int(additionalTimeNeeded / 3) + 1 // detours which may take approxkeeimetly 3 minutes each
        
        var currentLocation = start
        var accumulatedRoutes: [MKRoute] = [routes[0]]
        
        // create a detour route and point (these will be shown in orange lines.) (not fully functional yet)
        for i in 0..<numberOfDetours {
            let detourPoint = generateDetourPoint(from: currentLocation,
                                                to: endCoordinate,
                                                detourIndex: i)
            detourPoints.append(detourPoint)
            
            calculateRouteSegment(from: currentLocation, to: detourPoint) { detourRoute in
                guard let detourRoute = detourRoute else { return }
                
                accumulatedRoutes.append(detourRoute)
                currentLocation = detourPoint
                
                // if this is the last detour, try to route back to the original route (blue line)
                if i == numberOfDetours - 1 {
                    self.calculateRouteSegment(from: currentLocation, to: self.endCoordinate) { finalRoute in
                        guard let finalRoute = finalRoute else { return }
                        
                        accumulatedRoutes.append(finalRoute)
                        self.routes = accumulatedRoutes
                        self.updateCameraPosition()
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    private func generateDetourPoint(from current: CLLocationCoordinate2D,
                                   to destination: CLLocationCoordinate2D,
                                   detourIndex: Int) -> CLLocationCoordinate2D {
        
        // potential sprial loop? xheck the midpoint near it
        let midLat = (current.latitude + destination.latitude) / 2
        let midLon = (current.longitude + destination.longitude) / 2
        
        // ok now then create the spiral loop detour thing based on our detour
        let detourStrength = 0.02 * Double(detourIndex + 1)
        let angle = Double(detourIndex) * .pi / 3 // using 60 degree units to calculate turns in a spiral
        
        // spiral like pattern
        let offsetLat = detourStrength * cos(angle)
        let offsetLon = detourStrength * sin(angle)
        
        return CLLocationCoordinate2D(
            latitude: midLat + offsetLat,
            longitude: midLon + offsetLon
        )
    }
    
    private func calculateRouteSegment(from start: CLLocationCoordinate2D,
                                     to end: CLLocationCoordinate2D,
                                     completion: @escaping (MKRoute?) -> Void) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = transportTypeForMode(transportMode)
        
        let directions = MKDirections(request: request)
        
        directions.calculate { response, error in
            guard let response = response, let route = response.routes.first else {
                print("Error calculating segment: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            completion(route)
        }
    }
    
    private func updateCameraPosition() {
        guard !routes.isEmpty else { return }
        
        // create a map
        var overallRect = MKMapRect.null
        for route in routes {
            let routeRect = route.polyline.boundingMapRect
            overallRect = overallRect.union(routeRect)
        }
        
        let padding = 100.0
        cameraPosition = .rect(MKMapRect(
            x: overallRect.origin.x - padding,
            y: overallRect.origin.y - padding,
            width: overallRect.size.width + padding * 2,
            height: overallRect.size.height + padding * 2
        ))
    }
    
    // MARK: - these variables can be used for later and dont have a use in this entire page yet
    
    var totalEstimatedTime: Double {
        routes.reduce(0) { $0 + $1.expectedTravelTime } / 60 // convert to minutes
    }
    
    var totalDistance: Double {
        routes.reduce(0) { $0 + $1.distance } / 1000 // convert to kilometers
    }
}

#Preview {
    RoutePage(
        destination: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.3382, longitude: -121.8863))),
        travelTime: 150,
        transportMode: "Car"
    )
    .environmentObject(LocationManager())
}
