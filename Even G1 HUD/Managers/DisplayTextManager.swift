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


class DisplayManager {    
    @State var currentDisplay: String = ""
    @State var currentDisplayLines: [String] = []
    @State var currentPage: String = "Default"
    @State var refresh = 0

    
    var time = Date().formatted(date: .omitted, time: .shortened)
    var timer: Timer?
    
    var musicMonitor: MusicMonitor = MusicMonitor.init()
    var songProgAsBars: String = ""
    
    private var progressBar: CGFloat = 0.0
    
    var curTemp: String = ""
    var curWind: String = ""
    var curHum: String = ""
    
    private let cal = CalendarManager()
    private var events: [EKEvent] = []
    private var authorizationStatus = ""
    private var errorMessage: String = ""
    private var eventString: String = ""
    
    //Updating needed info
    func updateHUDInfo(){
        time = Date().formatted(date: .omitted, time: .shortened)
        musicMonitor.updateCurrentSong()
        songProgAsBars = progressBar(
            value: Double(musicMonitor.curSong.currentTime.components.seconds),
            max: Double(musicMonitor.curSong.duration.components.seconds),
            width: 50
        )
        loadEvents()

        if refresh == 20 {
            refresh = 0
        }else{
            refresh += 1
        }
    }

    func defaultDisplay() -> [String] {
        currentPage = "Default"
        self.currentDisplayLines.append(centerText(text: "\(time) \(getTodayWeekDay()) - "))
        
        for event in events {
            if let title = event.title, let startDate = event.startDate, let endDate = event.endDate {
                self.currentDisplayLines.append("\(title)\n\(startDate) - \(endDate)\n")
            }
            if refresh == 10{
                print (event.title ?? "No title")
            }
        }
        
        return(self.currentDisplayLines)
        
    }
    
    func musicDisplay() -> [String]{
        currentDisplayLines.append(centerText(text: "\(time)  \(getTodayWeekDay())"))
        currentDisplayLines.append(("\(musicMonitor.curSong.title) - \(musicMonitor.curSong.artist)"))
        currentDisplayLines.append("\(musicMonitor.curSong.currentTime.formatted(.time(pattern: .minuteSecond))) \(songProgAsBars) \(musicMonitor.curSong.duration.formatted(.time(pattern: .minuteSecond)))")
        return currentDisplayLines
    }
    
    
    func getTodayWeekDay()-> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        let weekDay = dateFormatter.string(from: Date())
        return weekDay
    }
    
    func getCurrentWeather() async {
        do{
            let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=52.52&longitude=13.41&hourly=temperature_2m&format=flatbuffers")!
            let responses = try await WeatherApiResponse.fetch(url: url)
            
            /// Process first location. Add a for-loop for multiple locations or weather models
            let response = responses[0]
            
            /// Attributes for timezone and location
            let utcOffsetSeconds = response.utcOffsetSeconds
            let timezone = response.timezone
            let timezoneAbbreviation = response.timezoneAbbreviation
            let latitude = response.latitude
            let longitude = response.longitude
            
            let hourly = response.hourly!
            
            struct WeatherData {
                let hourly: Hourly
                
                struct Hourly {
                    let time: [Date]
                    let temperature2m: [Float]
                }
            }
            
            /// Note: The order of weather variables in the URL query and the `at` indices below need to match!
            let data = WeatherData(
                hourly: .init(
                    time: hourly.getDateTime(offset: utcOffsetSeconds),
                    temperature2m: hourly.variables(at: 0)!.values
                )
            )
            
            /// Timezone `.gmt` is deliberately used.
            /// By adding `utcOffsetSeconds` before, local-time is inferred
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = .gmt
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            
            for (i, date) in data.hourly.time.enumerated() {
                print(dateFormatter.string(from: date))
                print(data.hourly.temperature2m[i])
            }
        } catch {
            print("Failed to fetch weather data: \(error.localizedDescription)")
        }
    }
    
    func progressBar(value: Double, max: Double, width: Int = 50) -> String {
        let percentage: Double = value/max
        let completedWidth = Int(percentage * Double(width))
                
        let completed = String(repeating: "-", count: completedWidth)
        let remaining = String(repeating: "_", count: width - completedWidth)
        
        let fullBar = completed + "|" + remaining
        return fullBar
    }
    
    func centerText(text: String, width: Int = 60) -> String{
        let maxSpaces = 96
        let padding = Int(Double(maxSpaces - text.count)*1.05)/2
        let newText = String(repeating: " ", count: padding) + text + String(repeating: " ", count: padding)
        return newText
    }
    
    func loadEvents() {
        
        cal.fetchEventsForNextDay { result in
            DispatchQueue.main.async {
                self.updateAuthorizationStatus()
                switch result {
                case .success(let fetchedEvents):
                    self.events = fetchedEvents
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
