//
//  DisplayManager.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/13/25.
//

import Foundation
import SwiftUI
import Combine
import EventKit
import CoreLocation
import MapKit
import OpenMeteoSdk


class DisplayManager: ObservableObject {
    var time = Date().formatted(date: .omitted, time: .shortened)
    var timer: Timer?
    
    var rm = RenderingManager()
    let displayWidth: Float = 100.0
    
    var musicMonitor: MusicMonitor = MusicMonitor.init()
    var songProgAsBars: String = ""
    
    private var progressBar: CGFloat = 0.0
    
    var currentPage = UserDefaults.standard.string(forKey: "currentPage")
    
    public var weather: weatherManager
    private var curTemp: Int?
    private var curWind: Int?
    
    private let cal = CalendarManager()
    private var events: [EKEvent] = []
    @Published public var  eventsFormatted: [event] = []
    private var authorizationStatus = ""
    private var errorMessage: String = ""
    private var eventString: String = ""
    
    public var batteryLevelFormatted = (Int)(UIDevice.current.batteryLevel * 100)
    private var lastEventsUpdateTime: Date = Date.distantPast
    
    var currentDisplayLines: [String] = []
    
    init(weather: weatherManager){
        self.weather = weather
    }
    
    //Updating needed info
    func updateHUDInfo(){
        time = Date().formatted(date: .omitted, time: .shortened)
        
        musicMonitor.updateCurrentSong()
        
        songProgAsBars = progressBar(
            value: Float(musicMonitor.curSong.currentTime),
            max: Float(musicMonitor.curSong.duration),
            song: true
        )
        
    }

    func defaultDisplay() -> [String] {
        currentDisplayLines.removeAll()
        
        if weather.currentTemp != 0 {
            currentDisplayLines.append(centerText(text:("\(time) | \(getTodayDate()) | Phone - \(batteryLevelFormatted)% | \(weather.currentTemp)°F")))
        }else{
            currentDisplayLines.append(String(centerText(text: "\(time)  \(getTodayDate()) | Phone - \(batteryLevelFormatted)%")))
        }
        
        
        return(currentDisplayLines)
        
    }
    
    func musicDisplay() -> [String]{
        currentDisplayLines.removeAll()
        
        if weather.currentTemp != 0 {
            currentDisplayLines.append(centerText(text:("\(time) | \(getTodayDate()) | Phone - \(batteryLevelFormatted)% | \(weather.currentTemp)°F")))
        }else{
            currentDisplayLines.append(String(centerText(text: "\(time) | \(getTodayDate()) | Phone - \(batteryLevelFormatted)%")))
        } //Hiding weather display if API issues or unknown location
        
        var artist = ""
        if musicMonitor.curSong.artist.count > 25 {
            artist = ("\(musicMonitor.curSong.artist.prefix(25))...")
        }else{
            artist = musicMonitor.curSong.artist
        } //Setting maximum character count for artist and song name to avoid spilling over onto next line
        
        var songTitle: String = ""
        if musicMonitor.curSong.title.count > 25 {
            songTitle = ("\(musicMonitor.curSong.title.prefix(25))...")
        }else{
            songTitle = musicMonitor.curSong.title
        }
        
        currentDisplayLines.append((centerText(text: "\(songTitle) - \(artist)"))) //Appening song info
        
        if !musicMonitor.curSong.isPaused{
            //let tempProgBar = progressBar(value: 0.99, max: 1.0)
            //let tempProgBar = progressBar(value: 0.0001, max: 1.0)
            //let tempProgBar = progressBar(value: 0.5, max: 1.0)
            let tempProgBar = songProgAsBars
            //currentDisplayLines.append("\(Duration.seconds(musicMonitor.currentTime).formatted(.time(pattern: .minuteSecond))) \(tempProgBar) \(Duration.seconds(musicMonitor.curSong.duration).formatted(.time(pattern: .minuteSecond)))")
            currentDisplayLines.append(centerText(text:"\(Duration.seconds(musicMonitor.currentTime).formatted(.time(pattern: .minuteSecond))) \(tempProgBar) \(Duration.seconds(musicMonitor.curSong.duration).formatted(.time(pattern: .minuteSecond)))"))
        }else{
            currentDisplayLines.append(centerText(text: "--Paused--"))
        } //Hiding progress bar if song is paused, showing paused text
        
        return currentDisplayLines
    }
    
    func calendarDisplay() -> [String]{
        currentDisplayLines.removeAll()
        
        if weather.currentTemp != 0 {
            currentDisplayLines.append(centerText(text:("\(time) | \(getTodayDate()) | Phone - \(batteryLevelFormatted)% | \(weather.currentTemp)°F")))
        }else{
            currentDisplayLines.append(String(centerText(text: "\(time) | \(getTodayDate()) | Phone - \(batteryLevelFormatted)%")))
        } //Hiding weather display if API issues or unknown location

        if eventsFormatted.count <= 2 {
            for event in eventsFormatted {
                currentDisplayLines.append(centerText(text: (event.titleLine)))
                currentDisplayLines.append(centerText(text: (event.subtitleLine)))
            }
        }else{
            for i in 0...1{
                currentDisplayLines.append(centerText(text: eventsFormatted[i].titleLine))
                currentDisplayLines.append(centerText(text: eventsFormatted[i].subtitleLine))
            }
            //EVENTUAL HANDLING FOR MORE THAN 5 LINES
        } //Limiting number of shown events to 2, possibly scroll through them with touch bar in the future
        
        return currentDisplayLines
    }
    
    /*
    func debugDisplay(index: Int) -> [String] {
        currentDisplayLines.removeAll()
        let offsetIndex = index + 31
        
        
        if rm.key != nil {
            
            currentDisplayLines.append(String(repeating: selectedChar, count: keys[keys[offsetIndex]] ))
            currentDisplayLines.append(String(repeating: keys[offsetIndex+31], count: 80))
            
        }else{
            currentDisplayLines.append("No key found")
            print("rm.key is nil, UserDefaults empty")
        } //Printing out full row of character,
        
        return currentDisplayLines
    }
     */
    
    func getTodayDate()-> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        let weekDay = dateFormatter.string(from: Date())
        
        let date = Date()
        
        dateFormatter.dateFormat = "MMMM"
        let month = dateFormatter.string(from: date)
        dateFormatter.dateFormat = "d"
        let day = dateFormatter.string(from: date)
        
        return "\(weekDay), \(month) \(day)"
    }
    
    func progressBar(value: Float, max: Float, song: Bool) -> String {
        var fullBar: String = ""
        if song{
            if value != 0.0 && max != 0.0 {
                let constantWidth = Float(rm.getWidth(text: "\(Duration.seconds(Double(value)).formatted(.time(pattern: .minuteSecond))) [|] \(Duration.seconds(Double(max)).formatted(.time(pattern: .minuteSecond)))")) //Constant characters in the progress bar
                
                let workingWidth = (displayWidth-constantWidth)
                
                let percentage = value/max
                
                let percentCompleted = workingWidth * percentage
                let percentRemaining = workingWidth * (1.0-percentage)
                
                let completed = String(repeating: "-", count: Int((percentCompleted / rm.getWidth(text: "-"))))
                let remaining = String(repeating: "_", count: Int((percentRemaining / rm.getWidth(text: "_"))))
                
                fullBar = "[" + completed + "|" + remaining + "]"
            }else{
                fullBar = "Broken"
            }
        }
        
        return fullBar
    }
    
    func centerText(text: String) -> String {
        let widthOfText = rm.getWidth(text: text)
       
        let widthRemaining: Float = max(0, displayWidth-widthOfText)
        let padding = String(repeating: " ", count: Int(widthRemaining/rm.getWidth(text: " "))/2)
        
        let FinalText = padding + text
        return FinalText
    }
    
    public func loadEvents(completion: (() -> Void)? = nil) {
        // Only update if it's been at least 15 minutes since the last update
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        // Initial load or 15 minutes have passed
        lastEventsUpdateTime = Date() // Update timestamp
        
        cal.fetchEventsForNextDay { result in
            DispatchQueue.main.async { [self] in
                self.updateAuthorizationStatus()
                switch result {
                case .success(let fetchedEvents):
                    eventsFormatted.removeAll()
                    events = fetchedEvents
                    for event in events {
                        var eventTemp: event = .init(
                            titleLine: "",
                            subtitleLine: ""
                        )
                        
                        if event.title != nil {
                            let title = event.title
                            
                            if (title! == "Shift as Computer Maintenance at TechCenter at TC/Lib/Comp Maint") {
                                eventTemp.titleLine = ("Work")
                            } else {
                                eventTemp.titleLine = ("\(title!)")
                            }
                        }
                        
                        if event.startDate != nil && event.endDate != nil {
                            let startDate = event.startDate
                            let endDate = event.endDate
                            
                            eventTemp.subtitleLine = ("\(timeFormatter.string(from: startDate!)) - \(timeFormatter.string(from: endDate!))")
                        }
                        
                        eventsFormatted.append(eventTemp)
                    }
                    
                    completion?()
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion?()
                }
            }
        }
    }
    
    
    private func updateAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized: authorizationStatus = "Authorized"
        case .denied: authorizationStatus = "Denied"
        case .notDetermined: authorizationStatus = "Not Determined"
        case .restricted: authorizationStatus = "Restricted"
        case .fullAccess: authorizationStatus = "Full Access"
        case .writeOnly: authorizationStatus = "Write Only"
        @unknown default: authorizationStatus = "Unknown"
        }
    }
}

struct event: Identifiable, Hashable{
    var id = UUID()
    var titleLine: String
    var subtitleLine: String
}
