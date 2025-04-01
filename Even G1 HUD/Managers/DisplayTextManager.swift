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
    @State var currentDisplay: String = ""
    @State var currentPage: String = "Default"
    
    var time = Date().formatted(date: .omitted, time: .shortened)
    var timer: Timer?
    
    var musicMonitor: MusicMonitor = MusicMonitor.init()
    var songProgAsBars: String = ""
    
    private var progressBar: CGFloat = 0.0
    
    var curTemp: Float?
    var curWind: Float?
    
    private let cal = CalendarManager()
    private var events: [EKEvent] = []
    public var eventsFormatted: [event] = []
    private var authorizationStatus = ""
    private var errorMessage: String = ""
    private var eventString: String = ""
    
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
        var currentDisplayLines: [String] = []
        
        currentDisplayLines.append(String(centerText(text: "\(time) \(getTodayWeekDay())")))

        if curTemp != nil {
            currentDisplayLines.append(centerText(text:("\(Int(curTemp ?? 0.0))°F")))
        }

        if eventsFormatted.count <= 2 {
            for event in eventsFormatted {
                currentDisplayLines.append(event.titleLine)
                currentDisplayLines.append(event.subtitleLine)
            }
        }else{
            for i in 0...1{
                currentDisplayLines.append(eventsFormatted[i].titleLine)
                currentDisplayLines.append(eventsFormatted[i].subtitleLine)
            }
            //EVENTUAL HANDLING FOR MORE THAN 5 LINES
        }
        
        
        return(currentDisplayLines)
        
    }
    
    func musicDisplay() -> [String]{
        var currentDisplayLines: [String] = []

        currentDisplayLines.append(String(centerText(text: "\(time) \(getTodayWeekDay())")))
        if curTemp != nil {
            currentDisplayLines.append(centerText(text:("\(Int(curTemp ?? 0.0))°F")))
        }
        
        
        if musicMonitor.curSong.title.count > 25{
            currentDisplayLines.append((centerText(text: "\(musicMonitor.curSong.title.prefix(25))... - \(musicMonitor.curSong.artist)")))
        }else{
            currentDisplayLines.append(centerText(text: ("\(musicMonitor.curSong.title) - \(musicMonitor.curSong.artist)")))
        }
        currentDisplayLines.append("\(Duration.seconds(musicMonitor.currentTime).formatted(.time(pattern: .minuteSecond))) \(songProgAsBars) \(Duration.seconds(musicMonitor.curSong.duration).formatted(.time(pattern: .minuteSecond)))")
        return currentDisplayLines
    }
    
    func getEvents() -> [EKEvent]{
        return events
    }
    
    func getTodayWeekDay()-> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        let weekDay = dateFormatter.string(from: Date())
        return weekDay
    }
    
    
    func getCurrentWeather() async {
        do{
            /// Make sure the URL contains `&format=flatbuffers`
            let location: [String] = ["46.81", "-92.09"]
            let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(location[0])&longitude=\(location[1])&current=temperature_2m,wind_speed_10m&forecast_days=1&wind_speed_unit=mph&temperature_unit=fahrenheit&precipitation_unit=inch&format=flatbuffers")!
            let responses = try await WeatherApiResponse.fetch(url: url)
            /// Process first location. Add a for-loop for multiple locations or weather models
            let response = responses[0]
            
            /// Attributes for timezone and location
            let utcOffsetSeconds = response.utcOffsetSeconds
            
            let current = response.current!
            
            struct WeatherData {
                let current: Current
                struct Current {
                    let time: Date
                    let temperature2m: Float
                    let windSpeed10m: Float
                    let relativeHumidity2m: Float
                }
            }
            
            /// Note: The order of weather variables in the URL query and the `at` indices below need to match!
            let data = WeatherData(
                current: .init(
                    time: Date(timeIntervalSince1970: TimeInterval(current.time + Int64(utcOffsetSeconds))),
                    temperature2m: current.variables(at: 0)!.value,
                    windSpeed10m: current.variables(at: 1)!.value,
                    relativeHumidity2m: current.variables(at: 2)!.value
                )
            )
            
            /// Timezone `.gmt` is deliberately used.
            /// By adding `utcOffsetSeconds` before, local-time is inferred
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = .gmt
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            curTemp = data.current.temperature2m
            curWind = data.current.windSpeed10m
        } catch {
            print("Failed to fetch weather data: \(error.localizedDescription)")
        }
    }
    
    func progressBar(value: Double, max: Double) -> String {
        let width = 45
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
    
    func loadEvents() {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        cal.fetchEventsForNextDay { result in
            DispatchQueue.main.async {
                self.updateAuthorizationStatus()
                switch result {
                case .success(let fetchedEvents):
                    self.events = fetchedEvents
                    for event in self.events {
                        var eventTemp: event = .init(
                            titleLine: "",
                            subtitleLine: ""
                        )
                        
                        if let title = event.title, let startDate = event.startDate, let endDate = event.endDate {
                            if (title == "Shift as Computer Maintenance at TechCenter at TC/Lib/Comp Maint"){
                                eventTemp.titleLine = ("Work")
                            }else{
                                eventTemp.titleLine = ("\(title)")
                            }
                            eventTemp.subtitleLine = ("\(timeFormatter.string(from: startDate)) - \(timeFormatter.string(from: endDate))")
                            self.eventsFormatted.append(eventTemp)
                        }
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
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

struct event{
    var titleLine: String
    var subtitleLine: String
}
