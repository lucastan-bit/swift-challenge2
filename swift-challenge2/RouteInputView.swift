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
    
    @State private var searchText = ""
    
    //SEARCH RESULTS VARIABLE, SHOWS U THE AMOUNT OF ITEMS IT CAN FIND AND SHOW POSSIBLY [below me] fjeerfjg
    
    @State private var searchResults: [MKMapItem] = []
    @State private var searchSuggestions: [MKLocalSearchCompletion] = []
    @State private var isSearching = false
    
    private let searchCompleter = MKLocalSearchCompleter()
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Let's plan your route!")
                    .font(.largeTitle)
                    .padding(.top)
                
                // TYPE IN YOUR DESTINATIOJN INSDIE THIS TEXTBOX YEAHHH UH HHUH
                VStack(alignment: .leading) {
                    TextField("Type in your destination!", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                        .onChange(of: searchText) { oldValue, newValue in
                            if newValue.count > 2 {
                                searchCompleter.queryFragment = newValue
                                isSearching = true
                            } else {
                                searchSuggestions.removeAll()
                                isSearching = false
                            }
                        }
                        .overlay(alignment: .trailing) {
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                    searchSuggestions.removeAll()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 25)
                                }
                            }
                        }
                    
                    // THEN ITS GONNA SEARCH FOR LISTS SIMILAR TO IT YEAH THANKS TO HACKING WITH SWIFT FOR THIS
                    if isSearching && !searchSuggestions.isEmpty {
                        List(searchSuggestions, id: \.self) { suggestion in
                            Button {
                                searchText = suggestion.title
                                searchSuggestions.removeAll()
                                isSearching = false
                                search(for: suggestion.title)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(suggestion.title)
                                        .font(.headline)
                                    Text(suggestion.subtitle)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                        .frame(height: 200)
                        .padding(.horizontal)
                    }
                }
                
                Button("Search Destination") {
                    search(for: searchText)
                }
                .buttonStyle(.borderedProminent)
                .disabled(searchText.isEmpty)
                
                // OK SO ONE CE U CLCI K ON THE LOCATIION U SEARCHED UP, THEN IT SHOWS THIS LLOL
                
                //this is a LIST OF ALL OF THE STUPID UGLY POOPY LOCATIONS IT CAN FIND YEAH YEAH YEAH
                List {
                    
                    //HEY IF U WANNA ADD A TEXT INTO THIS SURE JUST PUT "FEKSJEFJSERGJ" OR SMTH INSIDE SECTION()
                    
                    Section() {
                        ForEach(searchResults, id: \.self) { result in
                            if let name = result.name {
                                NavigationLink(destination: RouteInputTwoView(destinationName: name)) {
                                    VStack(alignment: .leading) {
                                        Text(name)
                                            .font(.headline)
                                        if let address = result.placemark.title {
                                            Text(address)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .onAppear {
                setupSearchCompleter()
            }
        }
    }
    
    
    //i had to figure out why i needed to change this function
    private func setupSearchCompleter() {
        searchCompleter.delegate = makeCoordinator()
        searchCompleter.resultTypes = .address
        searchCompleter.region = MKCoordinateRegion(
            center: singapore,
            span: MKCoordinateSpan(
                latitudeDelta: 0.1,
                longitudeDelta: 0.1
            )
        )
    }
    
    private func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func search(for query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        request.region = MKCoordinateRegion(
            center: singapore,
            span: MKCoordinateSpan(
                latitudeDelta: 0.1,
                longitudeDelta: 0.1
            )
        )
        
        Task {
            let search = MKLocalSearch(request: request)
            let response = try? await search.start()
            await MainActor.run {
                searchResults = response?.mapItems ?? []
                print("Search results: \(searchResults.count) items found")
            }
        }
    }
    
    // WOW YOY GOT SEARCH THIS UP?? OK SURE LETS PLAN YOUR ROUTE OUT LOL
    class Coordinator: NSObject, MKLocalSearchCompleterDelegate {
        var parent: RouteInputView
        
        init(_ parent: RouteInputView) {
            self.parent = parent
        }
        
        func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
            DispatchQueue.main.async {
                self.parent.searchSuggestions = completer.results
            }
        }
        
        
        }
    }


#Preview {
    RouteInputView()
}
