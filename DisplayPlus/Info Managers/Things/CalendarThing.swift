//
//  BatteryThing 2.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

import Foundation
import UIKit
import EventKit
import Combine

//
//  TimeThing.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

class CalendarThing: Thing {
    
    var calendar: CalendarManager = CalendarManager()
    
    var events: [EKEvent] = []
    var eventsFormatted: [event] = []
    @Published var numOfEvents: Int = 0
    @Published var authorizationStatus = ""
    @Published var errorMessage: String = ""
    
    init(name: String, size: String = "Small") {
        super.init(name: name, type: "Calendar", thingSize: size)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    private func loadEvents(completion: (() -> Void)? = nil) {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        calendar.fetchEventsForNextDay { result in
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
                            subtitleLine: "",
                            startTime: event.startDate,
                            endTime: event.endDate
                        )
                        
                        if event.title != nil {
                            let title = event.title
                            
                            if (title! == "Shift as Computer Maintenance at TechCenter at TC/Lib/Comp Maint") {
                                eventTemp.titleLine = ("Work")
                            } else {
                                if title!.count > 30 {
                                    eventTemp.titleLine = String(title!.prefix(27)) + "..."
                                } else {
                                    eventTemp.titleLine = title!
                                }
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
        return eventsFormatted
    }
    func getNumOfEvents() -> Int {
        return numOfEvents
    }
    
    func getCalendarAuthStatus() -> Bool {
        if calendar.getAuthStatus() {
            return true
        } else {
            // If calendar access is denied, run this func to force request
            calendar.fetchEventsForNextDay { result in
                let _ = result // just need to trigger function to force request access
            }
            return false
        }
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
    
    override func update() {
        if getCalendarAuthStatus() {
            let tempEventHolder = eventsFormatted.count
            loadEvents {
                if tempEventHolder != self.eventsFormatted.count {
                    self.updated = true
                    print("Calendar updated \(tempEventHolder) -> \(self.eventsFormatted.count)")
                }
            }
        }
    }
    
    override func toString(mirror: Bool = false) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        if size == "Medium" {
            let nextEvent = getEvents().first
            if nextEvent == nil {
                return "No events"
            } else {
                if tm.getWidth("\(nextEvent!.titleLine) > \(nextEvent!.subtitleLine)") < 40 {
                    if nextEvent!.startTime < Date() {
                        return "\(nextEvent!.titleLine) > \(timeFormatter.string(from: nextEvent!.endTime))"
                    } else {
                        return "\(nextEvent!.titleLine) > \(timeFormatter.string(from: nextEvent!.startTime))"
                    }
                } else {
                    if nextEvent!.startTime < Date() {
                        return "\(nextEvent!.titleLine) > \(timeFormatter.string(from: nextEvent!.endTime))"
                    } else {
                        return "\(nextEvent!.titleLine) > \(timeFormatter.string(from: nextEvent!.startTime))"
                    }
                }
            }
        } else if size == "Large" {
            let nextEvent = getEvents().first
            if nextEvent == nil {
                return "No events left for today"
            } else {
                return "\(nextEvent!.titleLine) >  \(nextEvent!.subtitleLine)"
            }
        } else if size == "XL" {
            var output: String = ""
            for event in getEvents() {
                if output != "" {
                    output += "\n"
                }
                output += "\(event.titleLine) >  \(event.subtitleLine)"
            }
            return output
        } else {
            return "Incorrect size input for Calendar thing: \(size), must be Medium, Large, or XL"
        }
    }
}

