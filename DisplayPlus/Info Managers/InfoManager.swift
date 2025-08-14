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
    let music: AMMonitor
    let weather: WeatherManager
    let health: HealthInfoGetter
    
    @Published var changed: Bool = false
    
    //Time vars
    @Published var time: String
    
    //Event vars
    @Published var eventsFormatted: [event] = []
    var events: [EKEvent] = []
    @Published var numOfEvents: Int = 0
    @Published var authorizationStatus = ""
    @Published var errorMessage: String = ""
    
    //Battery var
    @Published var batteryLevelFormatted: Int = 0 // Mark with @Published
    
    // Health var
    @Published var healthData: RingData = RingData(steps: 0, exercise: 0, standHours: 0) // Mark with @Published

    // Music var
    @Published var currentSong: Song = Song(title: "", artist: "", album: "", duration: 0.0, currentTime: 0.0, isPaused: true) // Mark with @Published, provide default

    init (cal: CalendarManager, music: AMMonitor, weather: WeatherManager, health: HealthInfoGetter) {
        self.cal = cal
        self.music = music
        self.weather = weather
        self.health = health
        time = Date().formatted(date: .omitted, time: .shortened)
        UIDevice.current.isBatteryMonitoringEnabled = true // Enable battery monitoring
        
    }
    
    public func updateTime() {
        let newTime = Date().formatted(date: .omitted, time: .shortened)
        if time != newTime {
            time = newTime
            changed = true
        }
    }
    
    public func updateBattery() {
        if UIDevice.current.isBatteryMonitoringEnabled && UIDevice.current.batteryLevel >= 0.0 {
            if batteryLevelFormatted != (Int)(UIDevice.current.batteryLevel * 100){
                batteryLevelFormatted = (Int)(UIDevice.current.batteryLevel * 100)
                changed = true
            }
        } else {
            if batteryLevelFormatted != 0 {
                batteryLevelFormatted = 0
                changed = true
            }
        }
    }
    
    public func updateCalendar() {
        if getCalendarAuthStatus() {
            let tempEventHolder = eventsFormatted.count
            loadEvents {
                if tempEventHolder != self.eventsFormatted.count {
                    self.changed = true
                    print("Calendar changed \(tempEventHolder) -> \(self.eventsFormatted.count)")
                }
            }
        }
    }
    
    public func updateMusic() {
        if getMusicAuthStatus() {
            music.updateCurrentSong()
            if currentSong.title != music.curSong.title || currentSong.isPaused != music.curSong.isPaused || currentSong.currentTime != music.curSong.currentTime {
                currentSong = music.curSong
                changed = true
            }
        }
    }
    public func updateWeather() async{
        do{
            try await weather.fetchWeatherData()
            print("Weather with\(!weather.useLocation ? "out" : "") location, fetch successful, InfoManager updated: Temp=\(weather.currentTemp)")
        }catch {
            print("failed weather fetch \(error)")
        }
    }
    
    
    //MARK: - Music functions
    public func getCurSong() -> Song {
        return currentSong // Return the @Published property
    }
    
    //MARK: - Time functions
    public func getTime() -> String {
        return time
    }
    
    //MARK: - Weather functions
    func getCurrentTemp() -> Int {
        return weather.currentTemp
    }
    func getCurrentWind() -> Int {
        return weather.currentWind
    }
    
    //MARK: - Cal functions
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
                    numOfEvents = 0
                    for event in events {
                        numOfEvents += 1
                        
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
    func getEvents() -> [event] {
        return self.eventsFormatted
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
    
    //MARK: - Getting PHONE battery
    func getBattery() -> Int {
        return batteryLevelFormatted
    }
    
    
    //MARK: - HealthKit Functions - Unused
    func getHealthData() -> RingData {
        // Simply return the current value - no async operations
        print("Steps \(healthData.steps), Exercise \(healthData.exercise), Stand Hours \(healthData.standHours)")
        return healthData
    }
    // Separate function to handle fetching health data asynchronously
    func fetchHealthData() async {
        do {
            let fetchedData = try await health.getRingData()
            // Use MainActor to update the @Published property on the main thread
            await MainActor.run {
                self.healthData = fetchedData
            }
        } catch {
            print("Error fetching health data: \(error)")
        }
    }
    
    
    //MARK: - Auth funcs
    
    
    /* Removing until I implement it fully
    func getHealthAuthStatus() -> Bool {
        return (health.getAuthStatus()[0] == true && health.getAuthStatus()[1] == true && health.getAuthStatus()[2] == true) //return true if all health data is authorized, otherwise returns false
    }
     */
    
    
    func getMusicAuthStatus() -> Bool {
        return music.getAuthStatus() // Return the music authorization status
    }
    func getCalendarAuthStatus() -> Bool {
        if cal.getAuthStatus() {
            return true
        } else {
            // If calendar access is denied, run this func to force request
            cal.fetchEventsForNextDay { result in
                let _ = result // just need to trigger function to force request access
            }
            return false
        }
    }
    func getLocationAuthStatus() -> Bool {
        return weather.getAuthStatus() // Return the location authorization status
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
