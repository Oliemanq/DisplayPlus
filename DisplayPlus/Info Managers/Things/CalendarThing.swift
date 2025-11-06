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
import SwiftUI

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
    
    var overrides: [String: String] {
        get {
            guard let data = UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.data(forKey: "calendarOverrides"),
                  let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
                return [:]
            }
            return decoded
        }
        set {
            guard let encoded = try? JSONEncoder().encode(newValue) else { return }
            UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.set(encoded, forKey: "calendarOverrides")
        }
    }
    
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
                            let title = event.title!
                            
                            // Check if there's an override for this title
                            let displayTitle = overrides[title] ?? title
                            
                            if displayTitle.count > 30 {
                                eventTemp.titleLine = String(displayTitle.prefix(27)) + "..."
                            } else {
                                eventTemp.titleLine = displayTitle
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
                let tempEventTitle = tm.shorten(to: 50-tm.getWidth("10:00 > "), text: nextEvent!.titleLine)
                if nextEvent!.startTime > Date() {
                    return "\(timeFormatter.string(from: nextEvent!.startTime)) > \(tempEventTitle)"
                } else {
                    return "\(tempEventTitle) > \(timeFormatter.string(from: nextEvent!.endTime))"
                }
            }
        } else if size == "Large" {
            let nextEvent = getEvents().first
            if nextEvent == nil {
                return "No events left for today"
            } else {
                let tempEventTitle = tm.shorten(to: 100-tm.getWidth("10:00 >  > 10:00"), text: nextEvent!.titleLine)
                return "\(timeFormatter.string(from: nextEvent!.startTime)) > \(tempEventTitle) > \(timeFormatter.string(from: nextEvent!.endTime))"
            }
        } else if size == "XL" {
            var output: String = ""
            for event in getEvents() {
                if output != "" {
                    output += "\n"
                }
                let tempEventTitle = tm.shorten(to: 100-tm.getWidth("10:00 >  > 10:00"), text: event.titleLine)
                output += "\(timeFormatter.string(from: event.startTime)) > \(tempEventTitle) > \(timeFormatter.string(from: event.endTime))"
            }
            return output
        } else {
            return "Incorrect size input for Calendar thing: \(size), must be Medium, Large, or XL"
        }
    }
    
    override func getSettingsView() -> AnyView {
        AnyView(
            NavigationStack {
                ZStack {
                    //backgroundGrid(themeIn: theme)
                    (theme.darkMode ? theme.backgroundDark : theme.backgroundLight)
                        .ignoresSafeArea()
                    VStack{
                        HStack {
                            Text("Calendar Thing Settings")
                            Spacer()
                            Text("|")
                            NavigationLink {
                                calendarSettingsPage(thing: self, themeIn: theme)
                            } label: {
                                Image(systemName: "arrow.up.right.circle")
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 24)
                            .font(.system(size: 24))
                            .mainButtonStyle(themeIn: theme)
                        }
                        .settingsItem(themeIn: theme)
                    }
                }
            }
        )
    }
}

struct calendarSettingsPage: View {
    @ObservedObject var thing: CalendarThing
    @StateObject var theme: ThemeColors
    
    @State private var originalTitle: String = ""
    @State private var replacementTitle: String = ""
    
    @State var showOverridePopup: Bool = false
    @State var showAlert: Bool = false
    
    init(thing: CalendarThing, themeIn: ThemeColors) {
        self.thing = thing
        _theme = StateObject(wrappedValue: themeIn)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack{
                //backgroundGrid(themeIn: theme)
                (theme.darkMode ? theme.backgroundDark : theme.backgroundLight)
                    .ignoresSafeArea()
                ScrollView(.vertical) {
                    //Has not been implemented
                    HStack {
                        Text("Text overrides")
                        Spacer()
                        Button {
                            showOverridePopup = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .settingsButton(themeIn: theme)
                        }
                    }
                    .settingsItem(themeIn: theme)
                    
                    Text("Override event titles. Titles to be overriden must be exact matches.")
                        .explanationText(themeIn: theme, width: geometry.size.width * 0.9)
                }
            }
            .toolbar{
                ToolbarItem(placement: .title) {
                    Text("Calendar Thing Settings")
                        .pageHeaderText(themeIn: theme)
                }
            }
            .sheet(isPresented: $showOverridePopup) {
                ZStack {
                    (theme.darkMode ? theme.backgroundDark : theme.backgroundLight)
                        .ignoresSafeArea()
                    
                    VStack {
                        HStack {
                            Text("Title Overrides allow you to change the text that's displayed on the glasses for certain events that you might not be able to control.\n\nExamples:\n  Shift at front desk -> Work\n  General Biology Lecture -> Bio lecture")
                                .font(theme.bodyFont)
                                .frame(width: UIScreen.main.bounds.width * 0.85)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(!theme.darkMode ? theme.lightTert : theme.darkTert)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(!theme.darkMode ? theme.dark : theme.light, lineWidth: 0.5)
                                        )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                        ScrollView(.vertical) {
                            ForEach(thing.overrides.keys.sorted(), id: \.self) { key in
                                HStack {
                                    VStack{
                                        Text(key)
                                    }
                                    VStack{
                                        Text("->")
                                    }
                                    VStack{
                                        Text(thing.overrides[key] ?? "")
                                    }
                                    Spacer()
                                    Button {
                                        thing.overrides.removeValue(forKey: key)
                                    } label: {
                                        Image(systemName: "minus.circle")
                                            .settingsButton(themeIn: theme)
                                    }
                                }
                                .settingsItem(themeIn: theme)
                            }
                            Divider()
                                .background(theme.darkMode ? theme.backgroundLight : theme.backgroundDark)
                                .opacity(0.3)
                                .padding(.vertical, 4)
                            
                            HStack{
                                Text("Add title override")
                                Spacer()
                                Button {
                                    showAlert = true
                                } label: {
                                    Image(systemName: "plus.circle")
                                        .settingsButton(themeIn: theme)
                                }
                            }
                            .settingsItem(themeIn: theme)
                        }
                    }
                }
                .alert("Add Title Override", isPresented: $showAlert) {
                    TextField("Original Event Title", text: $originalTitle)
                    TextField("Replacement Title", text: $replacementTitle)
                    Button("Cancel", role: .cancel) {
                        originalTitle = ""
                        replacementTitle = ""
                    }
                    Button("Add") {
                        thing.overrides[originalTitle] = replacementTitle
                        originalTitle = ""
                        replacementTitle = ""
                    }
                } message: {
                    Text("Enter the original event title and its replacement")
                }
            }
        }
    }
}
