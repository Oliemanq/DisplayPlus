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
    
    @State var time = Date().formatted(date: .omitted, time: .shortened)
    @State private var timer: Timer?
    @State private var progressBar: CGFloat = 0.0
    
    let musicMonitor = MusicMonitor()
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var authorizationStatus: String = "Checking..."
    
    private let daysOfWeek: [String] = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    let formatter = DateFormatter()
    
    var body: some View {
        let curSong = musicMonitor.curSong
        let events = displayManager.getEvents()
        let darkMode: Bool = (colorScheme == .dark)
        
        NavigationStack{
            List {
                HStack{
                    Spacer()
                    VStack{
                        Text(time)
                        HStack{
                            ForEach(daysOfWeek, id: \.self) { day in
                                if day == displayManager.getTodayWeekDay() {
                                    Text(day).bold().padding(0)
                                }else{
                                    Text(day).padding(-1)
                                }
                            }
                        }
                    }
                    Spacer()
                }
                //Current playing music plus progress bar
                VStack(alignment: .leading){
                    Text(curSong.title).font(.headline)
                    HStack{
                        Text(curSong.album).font(.subheadline)
                        Text(curSong.artist).font(.subheadline)
                    }
                    HStack{
                        ProgressView(value: progressBar)
                        Text(String(describing: curSong.duration.formatted(.time(pattern: .minuteSecond)))).font(.caption)
                    }
                }
                Text("Calendar events").font(.headline)
                if isLoading {
                    ProgressView("Loading events...")
                } else {
                    // Use ForEach with proper event data handling
                    ForEach(events, id: \.eventIdentifier) { event in
                        VStack(alignment: .leading) {
                            Text(event.title)
                                .font(.caption)
                            
                            HStack {
                                Text(formatter.string(from: event.startDate)).font(.caption2)
                                Text("-")
                                Text(formatter.string(from: event.endDate)).font(.caption2)
                            }
                            .font(.caption)
                        }
                    }
                }
                Text("end calendar").font(.headline)
                
                Spacer()
                
                HStack{
                    Spacer()
                    Button("Start scan"){
                        bleManager.startScan()
                    }.buttonStyle(.bordered)
                        .padding(2)
                }
                
                HStack{
                    Spacer()
                    Button(displayOn ? "Turn display off" : "Turn display on"){
                        displayOn.toggle()
                        print(String(displayOn))
                        sendTextCommand()
                    }
                    .buttonStyle(.bordered)
                    .padding(2)
                }
                
                HStack{
                    Spacer()
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
                    }
                    .buttonStyle(.bordered)
                    .padding(2)
                }
                HStack{
                    Spacer()
                    Text("Connection status: \(bleManager.connectionStatus)")
                }
            }
            .scrollContentBackground(.hidden)
            .background(LinearGradient(colors: darkMode ? [Color(red: 10/255, green: 10/255, blue: 30/255), Color(red: 28/255, green: 28/255, blue: 30/255)] : [Color(red: 220/255, green: 220/255, blue: 255/255), .white], startPoint: .bottom, endPoint: .top))
            .edgesIgnoringSafeArea(.bottom)
            .frame(width: 400)
    }
        .onAppear {
            // Create and store the timer
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                progressBar = CGFloat(curSong.currentTime / curSong.duration)
                
                Task.detached {
                    await displayManager.getCurrentWeather()
                }
                
                displayManager.updateHUDInfo()
                counter += 1
                if displayOn{
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
        
        if currentPage == "Default"{ // DEFAULT PAGE HANDLER
            let displayLines = displayManager.defaultDisplay()
            if displayLines.isEmpty{
                textOutput = "broken"
            }else{
                for line in displayLines {
                    textOutput += line + "\n"
                }
            }
        }else if currentPage == "Music"{ //MUSIC PAGE HANDLER
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

