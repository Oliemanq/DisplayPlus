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
            /// Make sure the URL contains `&format=flatbuffers`
            let location: [String] = ["46.81", "-92.09"]
            let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(location[0])&longitude=\(location[1])&current=temperature_2m,wind_speed_10m,relative_humidity_2m&forecast_days=1&wind_speed_unit=mph&temperature_unit=fahrenheit&precipitation_unit=inch&format=flatbuffers")!
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
            print("Temp: \(data.current.temperature2m)")
            print("Humidity: \(data.current.relativeHumidity2m)")
            print("Wind speed: \(data.current.windSpeed10m)")
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
