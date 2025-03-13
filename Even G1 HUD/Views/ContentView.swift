//
//  ContentView.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/4/25.
//

import SwiftUI
import EventKit

struct ContentView: View {
    @State var bleManager = G1BLEManager()
    @State private var counter: Int = 0
    
    @State private var showViewsButton = false
    
    @State var time = Date().formatted(date: .omitted, time: .shortened)
    @State private var curSong = MusicMonitor.init().curSong
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
            
            Text(bleManager.connectionStatus)
            
            NavigationLink("HUD Debug view", destination: HUDDebug())
                .padding(10)
                .buttonStyle(.borderedProminent)
                .scaleEffect(showViewsButton ? 1.5 : 1 )
        }
        .onAppear {
            // Create and store the timer
            bleManager.startScan()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                updateHUDInfo()
                counter += 1
                let songProgBars = getSongProgAsBar(progress: progressBar, width: 20)
                let textToSend = "  \(time) - \(getTodayWeekDay())\n\n  \(curSong.title)\n  \(curSong.artist) \n        \(songProgBars)"
                bleManager.sendTextCommand(seq: UInt8(counter), text: textToSend)
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            timer?.invalidate()
        }
    }
    func updateHUDInfo(){
        time = Date().formatted(date: .omitted, time: .shortened)
        musicMonitor.updateCurrentSong()
        curSong = musicMonitor.curSong
        progressBar = CGFloat(curSong.currentTime / curSong.duration)
    }
    func getTodayWeekDay()-> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        let weekDay = dateFormatter.string(from: Date())
        return weekDay
    }
    func getSongProgAsBar(progress: Double, width: Int = 20) -> String{
        let filledLength = Int(progress * Double(width))
            let bar = String(repeating: "-", count: filledLength) + String(repeating: "_", count: width - filledLength)
        return "\(curSong.currentTime.formatted(.time(pattern: .minuteSecond)))  \(bar) \(curSong.duration.formatted(.time(pattern: .minuteSecond)))"
        
    }
}


#Preview {
    ContentView()
}
