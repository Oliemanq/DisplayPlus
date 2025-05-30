//
//  InfoManager.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 5/27/25.
//

import Foundation
import EventKit
import UIKit

class InfoManager: ObservableObject { // Conform to ObservableObject
    let cal: CalendarManager
    let music: MusicMonitor
    let weather: WeatherManager
    
    //Time vars
    @Published var time: String // Mark with @Published
    
    //Event vars
    @Published var eventsFormatted: [event] = [] // Mark with @Published
    var events: [EKEvent] = [] // Keep this for internal fetching if needed
    @Published var authorizationStatus = "" // Mark with @Published
    @Published var errorMessage: String = "" // Mark with @Published
    
    //Battery var
    @Published var batteryLevelFormatted: Int = 0 // Mark with @Published
    
    // Weather vars
    @Published var currentTemperature: Int = 0 // New @Published property for temperature
    @Published var currentWindSpeed: Int = 0   // New @Published property for wind

    // Music var
    @Published var currentSong: Song = Song(title: "", artist: "", album: "", duration: 0.0, currentTime: 0.0, isPaused: true) // Mark with @Published, provide default

    init (cal: CalendarManager, music: MusicMonitor, weather: WeatherManager) {
        self.cal = cal
        self.music = music
        self.weather = weather
        time = Date().formatted(date: .omitted, time: .shortened)
        UIDevice.current.isBatteryMonitoringEnabled = true // Enable battery monitoring
    }
    
    
    public func update(updateWeatherBool: Bool) {
        loadEvents() // This already updates self.eventsFormatted which will publish changes
        
        // Check if battery monitoring is enabled and level is valid
        time = Date().formatted(date: .omitted, time: .shortened) // Update time
        
        if UIDevice.current.isBatteryMonitoringEnabled && UIDevice.current.batteryLevel >= 0.0 {
            self.batteryLevelFormatted = (Int)(UIDevice.current.batteryLevel * 100)
        } else {
            self.batteryLevelFormatted = 0 // Or some other default/error value like -1 if you prefer to indicate an issue
            print("Battery level not available or monitoring disabled. Current value: \(UIDevice.current.batteryLevel)")
        }
        
        Task{
            if updateWeatherBool {
                await updateWeather() // updateWeather will now update @Published properties
            }
        }
        
        self.time = Date().formatted(date: .omitted, time: .shortened) // This will publish changes
        
        music.updateCurrentSong()
        self.currentSong = music.curSong // Update the @Published property
    }
    
    private func loadEvents(completion: (() -> Void)? = nil) {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        cal.fetchEventsForNextDay { result in
            DispatchQueue.main.async { [self] in
                self.updateAuthorizationStatus() // This updates a @Published property
                switch result {
                case .success(let fetchedEvents):
                    var tempEventsFormatted: [event] = [] // Build locally then assign to @Published
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
                        
                        tempEventsFormatted.append(eventTemp)
                    }
                    self.eventsFormatted = tempEventsFormatted // Assign to @Published property
                    
                    completion?()
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription // This updates a @Published property
                    completion?()
                }
            }
        }
    }
    
    public func getCurSong() -> Song {
        return self.currentSong // Return the @Published property
    }
    
    public func getTime() -> String {
        return self.time
    }
    
    
    func updateWeather() async{
        do{
            try await weather.fetchWeatherData()
            // Update @Published properties after fetching
            self.currentTemperature = weather.currentTemp
            self.currentWindSpeed = weather.currentWind
            print("Weather fetch successful, InfoManager updated: Temp=\(self.currentTemperature)")
        }catch {
            print("failed weather fetch \(error)")
        }
    }
    func getCurrentTemp() -> Int {
        return self.currentTemperature // Return the @Published property
    }
    func getCurrentWind() -> Int {
        return self.currentWindSpeed // Return the @Published property
    }
    
    func getEvents() -> [event] {
        return self.eventsFormatted // Return the @Published property
    }
    
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
    func getBattery() -> Int {
        return batteryLevelFormatted // Return the @Published property
    }
    
    private func updateAuthorizationStatus() {
            let status = EKEventStore.authorizationStatus(for: .event)
            switch status {
            case .authorized: authorizationStatus = "Authorized"
            case .denied: authorizationStatus = "Denied"
            case .notDetermined: authorizationStatus = "Not Determined" // This updates a @Published property
            case .restricted: authorizationStatus = "Restricted" // This updates a @Published property
            case .fullAccess: authorizationStatus = "Full Access" // This updates a @Published property
            case .writeOnly: authorizationStatus = "Write Only" // This updates a @Published property
            @unknown default: authorizationStatus = "Unknown" // This updates a @Published property
            }
        }
}


struct event: Identifiable, Hashable{
    var id = UUID()
    var titleLine: String
    var subtitleLine: String
}
