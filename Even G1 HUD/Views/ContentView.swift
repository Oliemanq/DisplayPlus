//
//  ContentView.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/4/25.
//

import SwiftUI
import EventKit

struct ContentView: View {
    @State var displayOn: Bool = true
    
    @State var displayManager = DisplayManager()
    @State var currentPage = "Default"
    @State var bleManager: G1BLEManager = G1BLEManager()
    @State var counter: CGFloat = 0
    
    @State private var showViewsButton = false
    
    @State var time = Date().formatted(date: .omitted, time: .shortened)
    @State private var timer: Timer?
    @State private var progressBar: CGFloat = 0.0
    
    let musicMonitor = MusicMonitor()
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var authorizationStatus: String = "Checking..."
    
    private let daysOfWeek: [String] = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    let formatter = DateFormatter()
    
    var body: some View {
        NavigationStack{
            Button("Start scan"){
                bleManager.startScan()
            }.buttonStyle(.borderedProminent)
            
            Button(displayOn ? "Turn display off" : "Turn display on"){
                displayOn.toggle()
                print(String(displayOn))
                sendTextCommand()
            }
            
            Button("Cycle through pages\nCurrent page: \(currentPage)"){
                if currentPage == "Default"{
                    currentPage = "Music"
                    displayManager.currentPage = "Music"
                    
                    let currentDisplay = mainDisplayLoop()
                    sendTextCommand(text: currentDisplay)
                }else if currentPage == "Music"{
                    currentPage = "Default"
                    displayManager.currentPage = "Default"
                    
                    let currentDisplay = mainDisplayLoop()
                    sendTextCommand(text: currentDisplay)
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
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                
                if displayOn{
                    counter += 1
                    displayManager.updateHUDInfo()
                    displayManager.getCurrentWeather()
                    
                    let currentDisplay = mainDisplayLoop()
                    sendTextCommand(text: currentDisplay)
                }else{
                    sendTextCommand()
                }
                
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            timer?.invalidate()
            bleManager.disconnect()
        }
    }
    func mainDisplayLoop() -> String{
        var textOutput: String = ""
        if currentPage == "Default"{
            for line in displayManager.defaultDisplay() {
                print(line)
                textOutput += line + "\n"
            }
        }else if currentPage == "Music"{
            for line in displayManager.musicDisplay() {
                textOutput += line + "\n"
            }
        }else{
            return "No page selected"
        }
        return textOutput
    }
    
    func sendTextCommand(text: String = ""){
        if UInt8(self.counter) >= 255{
            self.counter = 0
        }
        bleManager.sendTextCommand(seq: UInt8(self.counter), text: text)

    }
    
}


#Preview {
    ContentView()
}

