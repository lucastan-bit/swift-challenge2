//
//  RouteInputTwoView.swift
//  swift-challenge2
//
//  Created by T Krobot on 16/8/25.
//

import MapKit
import SwiftUI

struct RouteInputTwoView: View {
    
    @State var destination: MKMapItem
    @State private var selectedHour = 00
    let hours = [00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23]
    @State private var selectedMinute = 00
    let minutes = [00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]
    @State private var selectedModeOfTransport = "Select mode of transport"
    
    @State var isShowingSheet = false
    let transportModes = ["Walking", "Bus", "MRT", "Car"]
    
    var body: some View {
        NavigationStack {
            Form {
                
                //oo fancy bold
                Text("You picked ") + Text(destination.name ?? "").bold() + Text(" as your destination.")
                
                
                    .font(.subheadline)
                    
                Section {
                    HStack {
                        
                        VStack {
                            
                        Text("Hours")
                                .font(.system(size: 25))
                                .bold()
                            
                            
                        Picker("Hours", selection: $selectedHour) {
                            ForEach(hours, id: \.self) {
                                Text(String(format: "%02d", $0))
                            }
                            }
                            
                        .pickerStyle(.wheel)
                        }
                        
                        VStack {
                            Text("Minutes")
                                .font(.system(size: 25))
                                .bold()
                            
                                
                            Picker("Minutes", selection: $selectedMinute) {
                                ForEach(minutes, id: \.self) {
                                    Text(String(format: "%02d", $0))
                                    
                                   
                                    
                                }
                            }
                            
                            .pickerStyle(.wheel)
                            
                        }
                    }
                } header : {
                    Text("Time you want to arrive")
                }
                Section {
                    HStack {
                        Picker("Mode of transport", selection: $selectedModeOfTransport) {
                            ForEach(transportModes, id: \.self) {
                                Text($0)
                            }
                        }
                    }
                } header: {
                    Text("Mode of transportation")
                }
                
                
                Button("Let's go!") {
                    isShowingSheet.toggle()
                    let startOfDay = Calendar.current.startOfDay(for: Date())
                    print(startOfDay.addingTimeInterval(TimeInterval(selectedHour*3600 + selectedMinute*60)))
                }
                
                .sheet(isPresented: $isShowingSheet){
                    RoutePage(destination: destination)
                }
                
                
                
                .frame(maxWidth: .infinity)
            }
        }
    }
}


#Preview {
    RouteInputTwoView(destination: MKMapItem())
}

