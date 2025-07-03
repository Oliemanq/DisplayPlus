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
    @Published var time: String // Mark with @Published
    
    //Event vars
    @Published var eventsFormatted: [event] = [] // Mark with @Published
    var events: [EKEvent] = [] // Keep this for internal fetching if needed
    @Published var authorizationStatus = "" // Mark with @Published
    @Published var errorMessage: String = "" // Mark with @Published
    
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
    
    public func update(updateWeatherBool: Bool) {
        changed = false
        
        let newTime = Date().formatted(date: .omitted, time: .shortened)
        if time != newTime {
            time = newTime
            changed = true
        }
        
        //Update battery level var
        if UIDevice.current.isBatteryMonitoringEnabled && UIDevice.current.batteryLevel >= 0.0 {
            if batteryLevelFormatted != (Int)(UIDevice.current.batteryLevel * 100){
                batteryLevelFormatted = (Int)(UIDevice.current.batteryLevel * 100)
                changed = true
            }
        } else {
            batteryLevelFormatted = 0
        }
        
        //check calendar auth then update events
        if getCalendarAuthStatus(){
            loadEvents()
        }
         
        //Update weather only when needed (every 5 minutes or so)
        Task{
            if updateWeatherBool {
                if getLocationAuthStatus() {
                    await updateWeather() // updateWeather will now update @Published properties
                }
            }
        }
        
        //Check if music auth is granted and update current song
        if getMusicAuthStatus() {
            music.updateCurrentSong()
            if currentSong.title != music.curSong.title || currentSong.duration != music.curSong.duration || currentSong.currentTime != music.curSong.currentTime {
                currentSong = music.curSong
                changed = true
            }
        }
        
        // Fetch health data asynchronously
        /* DISABLING FOR TESTFLIGHT BUILD, NOT IMPLEMENTED YET
        Task{
            await fetchHealthData() // Fetch health data asynchronously
        }
        */
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
        return currentSong // Return the @Published property
    }
    
    public func getTime() -> String {
        return time
    }
    
    func updateWeather() async{
        do{
            try await weather.fetchWeatherData()
            // Update @Published properties after fetching
            print("Weather fetch successful, InfoManager updated: Temp=\(weather.currentTemp)")
        }catch {
            print("failed weather fetch \(error)")
        }
    }
    func getCurrentTemp() -> Int {
        return weather.currentTemp
    }
    func getCurrentWind() -> Int {
        return weather.currentWind
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
    
    func getBattery() -> Int {
        return batteryLevelFormatted // Return the @Published property
    }
    
    
    
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
    
    
    //AUTH FUNCS _____________________________________________________________________________________________________________________________________________________________________________________
    /* Removing until I implement it fully
    func getHealthAuthStatus() -> Bool {
        return (health.getAuthStatus()[0] == true && health.getAuthStatus()[1] == true && health.getAuthStatus()[2] == true) //return true if all health data is authorized, otherwise returns false
    }
     */
    func getMusicAuthStatus() -> Bool {
        return music.getAuthStatus() // Return the music authorization status
    }
    func getCalendarAuthStatus() -> Bool {
        return cal.getAuthStatus() // Return the calendar authorization status
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
