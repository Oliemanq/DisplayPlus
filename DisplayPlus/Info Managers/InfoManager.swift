//
//  InfoManager.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 5/27/25.
//

import Foundation
import EventKit
import UIKit
import SwiftUI

class InfoManager: ObservableObject { // Conform to ObservableObject
    @Published var updated: Bool = false
    
    @Published var things: [Thing]
    
    @AppStorage("pages", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var pagesString: String = "Default,Music,Calendar"
    @AppStorage("currentPage", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var currentPage = "Default"
    
    @Published var curSong: Song = Song.empty
    @Published var eventsFormatted: [event] = []
    
    init (things: [Thing]) { //, health: HealthInfoGetter
        UIDevice.current.isBatteryMonitoringEnabled = true // Enable battery monitoring
        
        self.things = things
    }
        
    
    //MARK: - Update functions
    
    func updateThings(counter: Int) {
        for thing in things {
            if thing.type == "Weather" {
                if counter % 360 == 0 {
                    thing.update()
                }
            }else {
                thing.update()
                if thing.type == "Music" {
                    let temp: MusicThing = thing as! MusicThing
                    self.curSong = temp.getCurSong()
                } else if thing.type == "Calendar" {
                    let temp: CalendarThing = thing as! CalendarThing
                    eventsFormatted = temp.getEvents()
                }
            }
            
            if thing.updated {
                updated = true
            }
        }
    }
    
    func updateThingsSafe() {
        for thing in things {
            if thing.type != "Weather" {
                thing.update()
            }
            if thing.updated {
                updated = true
            }
        }
    }
    
    func updateWeather() {
        for thing in things {
            if thing.type == "Weather" {
                thing.update()
                if thing.updated {
                    updated = true
                }
            }
        }
    }
    
    //MARK: - Get functions
    func getThings() -> [Thing] {
        return things
    }
    func getTime() -> String {
        return things.first(where: { $0.type == "Time" })?.toString() ?? ""
    }
    
    func getTodayDate() -> String {
        return things.first(where: { $0.type == "Date" })?.toString() ?? ""
    }
    
    func getBattery() -> Int {
        return Int(things.first(where: { $0.type == "Battery" })?.toString() ?? "0")!
    }
    
    func getSongTitle() -> String {
        let temp: MusicThing = things.first(where: { $0.type == "Music" }) as! MusicThing
        return temp.getTitle()
    }
    func getSongArtist() -> String {
        let temp: MusicThing = things.first(where: { $0.type == "Music" }) as! MusicThing
        return temp.getArtist()
    }
    func getSongAlbum() -> String {
        let temp: MusicThing = things.first(where: { $0.type == "Music" }) as! MusicThing
        return temp.getAlbum()
    }
    func getCurSong() -> Song {
        let temp: MusicThing = things.first(where: { $0.type == "Music" }) as! MusicThing
        return temp.getCurSong()
    }
    
    func getCurrentTemp() -> Int {
        let temp: WeatherThing = things.first(where: { $0.type == "Weather" }) as! WeatherThing
        return temp.getCurrentTemp()
    }
    func getCity() -> String {
        let temp: WeatherThing = things.first(where: { $0.type == "Weather" }) as! WeatherThing
        return temp.weather.currentCity ?? "Resolving..."
    }
    func toggleLocation(){
        let temp: WeatherThing = things.first(where: { $0.type == "Weather" }) as! WeatherThing
        temp.toggleLocation()
    }
    
    func getEvents() -> [event] {
        let temp: CalendarThing = things.first(where: { $0.type == "Calendar" }) as! CalendarThing
        return temp.getEvents()
    }
    func getNumOfEvents() -> Int {
        let temp: CalendarThing = things.first(where: { $0.type == "Calendar" }) as! CalendarThing
        return temp.getNumOfEvents()
    }
}


struct event: Identifiable, Hashable{
    var id = UUID()
    var titleLine: String
    var subtitleLine: String
}
