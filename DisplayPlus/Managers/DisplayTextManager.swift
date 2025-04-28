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
    
    var musicMonitor: MusicMonitor = MusicMonitor.init()
    var songProgAsBars: String = ""
    
    private var progressBar: CGFloat = 0.0
    
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
            value: Double(musicMonitor.curSong.currentTime),
            max: Double(musicMonitor.curSong.duration)
        )
    }

    func defaultDisplay() -> [String] {
        currentDisplayLines.removeAll()
        print(weather.currentTemp)
        
        if weather.currentTemp != 0 {
            currentDisplayLines.append(centerText(text:("\(time)  \(getTodayWeekDay()) | Phone - \(batteryLevelFormatted)% | \(weather.currentTemp)°F")))
        }else{
            currentDisplayLines.append(String(centerText(text: "\(time)  \(getTodayWeekDay()) | Phone - \(batteryLevelFormatted)%")))
        }
        
        
        return(currentDisplayLines)
        
    }
    
    func musicDisplay() -> [String]{
        currentDisplayLines.removeAll()

        if weather.currentTemp != 0 {
            currentDisplayLines.append(centerText(text:("\(time)  \(getTodayWeekDay()) | Phone - \(batteryLevelFormatted)% | \(weather.currentTemp)°F")))
        }else{
            currentDisplayLines.append(String(centerText(text: "\(time)  \(getTodayWeekDay()) | Phone - \(batteryLevelFormatted)%")))
        }
        
        if musicMonitor.curSong.title.count > 25{
            currentDisplayLines.append((centerText(text: "\(musicMonitor.curSong.title.prefix(25))... - \(musicMonitor.curSong.artist)")))
        }else{
            currentDisplayLines.append(centerText(text: ("\(musicMonitor.curSong.title) - \(musicMonitor.curSong.artist)")))
        }
        currentDisplayLines.append("\(Duration.seconds(musicMonitor.currentTime).formatted(.time(pattern: .minuteSecond))) \(songProgAsBars) \(Duration.seconds(musicMonitor.curSong.duration).formatted(.time(pattern: .minuteSecond)))")
        return currentDisplayLines
    }
    
    func calendarDisplay() -> [String]{
        currentDisplayLines.removeAll()
        
        if weather.currentTemp != 0 {
            currentDisplayLines.append(centerText(text:("\(time)  \(getTodayWeekDay()) | Phone - \(batteryLevelFormatted)% | \(weather.currentTemp)°F")))
        }else{
            currentDisplayLines.append(String(centerText(text: "\(time)  \(getTodayWeekDay()) | Phone - \(batteryLevelFormatted)%")))
        }

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
        }
        
        return currentDisplayLines
    }
    
    func getTodayWeekDay()-> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        let weekDay = dateFormatter.string(from: Date())
        return weekDay
    }
    
    func progressBar(value: Double, max: Double) -> String {
        let width = 46
        let percentage: Double = value/max
        let completedWidth = Int(percentage * Double(width))

        let completed = String(repeating: "-", count: completedWidth)
        let remaining = String(repeating: "_", count: Int(Double(width - completedWidth) * 1.2631578947))
        let fullBar = "[" + completed + "|" + remaining + "]"
        return fullBar
    }
    
    func centerText(text: String) -> String{
        let maxSpaces = 90.0
        let padding = Int(maxSpaces - (Double(text.count) * 1.15))
        let newText = String(repeating: " ", count: padding/2) + text
        return newText
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
