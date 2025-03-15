//
//  ContentView.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/4/25.
//

import SwiftUI
import EventKit

struct ContentView: View {
    @State var displayManager = DisplayManager()
    @State var currentPage = "Default"
    @State var bleManager: G1BLEManager = G1BLEManager()
    @State var counter: Int = 0
    
    @State private var showViewsButton = false
    
    @State var time = Date().formatted(date: .omitted, time: .shortened)
    @State private var timer: Timer?
    @State private var progressBar: CGFloat = 0.0
    
    let musicMonitor = MusicMonitor()
    
    @State private var events: [EKEvent] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var authorizationStatus: String = "Checking..."
    
    
    private let cal = CalendarManager()
    private let daysOfWeek: [String] = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    let formatter = DateFormatter()
    
    
    var body: some View {
        NavigationStack{
            Button("Start scan"){
                bleManager.startScan()
            }.buttonStyle(.borderedProminent)
            
            Button("Cycle through pages\nCurrent page: \(currentPage)"){
                if currentPage == "Default"{
                    currentPage = "Music"
                    displayManager.currentPage = "Music"
                }else if currentPage == "Music"{
                    currentPage = "Default"
                    displayManager.currentPage = "Default"
                }
            }.buttonStyle(.borderedProminent)
            
            Text(bleManager.connectionStatus)
            
            NavigationLink("HUD Debug view", destination: HUDDebug())
                .padding(10)
                .buttonStyle(.borderedProminent)
                .scaleEffect(showViewsButton ? 1.5 : 1 )
        }
        .onAppear {
            // Create and store the timer
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                counter += 1
                displayManager.updateHUDInfo()
                let currentDisplay = mainDisplayLoop()
                bleManager.sendTextCommand(seq: UInt8(self.counter), text: currentDisplay)
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            timer?.invalidate()
        }
    }
    func mainDisplayLoop() -> String{
        print(currentPage)
        if currentPage == "Default"{
            return displayManager.defaultDisplay()
        }else if currentPage == "Music"{
            return displayManager.musicDisplay()
        }else{
            return "No page selected"
        }
    }
    
}


#Preview {
    ContentView()
}

