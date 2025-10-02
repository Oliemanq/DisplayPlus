//
//  BackgroundTaskManager.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 5/25/25.
//
import SwiftUI

class BackgroundTaskManager: ObservableObject {
    private var ble: G1BLEManager
    private var page: PageManager
    private var info: InfoManager
    
    var timer: Timer?
    
    var textOutput = ""
    
    //various counters
    var counter: Int = 0
    var HBTriggerCounter: Int = 0
    var HBCounter: Int = 0
    var autoOffCounter: Int = 0
    var forceUpdateInfo: Bool = true
    
    var logging: Bool = false // For debugging purposes
    
    @AppStorage("displayOn", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var displayOn = false
    @AppStorage("autoOff", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var autoOff = false
    @AppStorage("currentPage", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var currentPage = ""
    @AppStorage("useLocation", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var useLocation: Bool = false
    @AppStorage("glassesBattery", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var glassesBattery: Int = 0
    @AppStorage("caseBattery", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var caseBattery: Int = 0

    init(ble: G1BLEManager, info: InfoManager, page: PageManager) {
        self.ble = ble
        self.page = page
        self.info = info
    }
    
    func startTimer() {
        // Invalidate existing timer before starting a new one
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else {
                print("BackgroundTaskManager timer: self is nil, timer cannot continue.")
                return
            }
            // Hop to the main actor for all UI-bound and @MainActor work
            Task { @MainActor in
                self.tick()
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // Run one timer tick on the main actor to safely call @MainActor methods and touch @AppStorage.
    @MainActor
    private func tick() {
        
        if useLocation {
            info.updateThingsSafe()
        } else {
            info.updateThings(counter: counter)
        }
                
        if ble.connectionState == .connectedBoth {
            // Less frequent updates
            if counter % 20 == 0 { // Every 10 seconds (20 * 0.5s)
                ble.fetchBrightness()
                ble.fetchSilentMode()
                if logging {
                    print("Brightness and silent mode fetched")
                }
            }
            
            HBTriggerCounter += 1
            if HBTriggerCounter % 48 == 0 || HBTriggerCounter == 1 { //Sending heartbeat command every ~24 seconds to maintain connection
                ble.sendHeartbeat(counter: HBCounter % 255)
                HBCounter += 1
            }
            
            if counter % 60 == 0 || forceUpdateInfo{ // every 30 seconds (60 * 0.5s)
                ble.fetchGlassesBattery()
                if ((glassesBattery <= 3 && glassesBattery != 0) || ble.glassesBatteryLeft <= 1 || ble.glassesBatteryRight <= 1){
                    Task {
                        await self.lowBatteryDisconnect()
                    }
                }
                if logging {
                    print("Glasses battery fetched")
                }
            }
            
            if autoOff {
                if displayOn {
                    autoOffCounter += 1
                    print("ticked autoOff +1, at \(autoOffCounter)")
                }
                if autoOffCounter >= 10 { // 5 seconds (10 * 0.5s)
                    autoOffCounter = 0
                    displayOn = false
                }
            }
            
            // Re-fetch displayOn as it might have been changed by the autoOff logic above in the same tick
            let currentDisplayOn = displayOn
            
            //info.changed is to reduce unnecessary updates to the glasses
            if (currentDisplayOn && info.updated) || forceUpdateInfo { // Only update display if it's on and info has changed
                let pageText = "broken rn"
                ble.sendText(text: pageText, counter: counter)
                info.updated = false
            }
            
            forceUpdateInfo = false // Reset after first full update
        }
        
        if counter % 20 == 0 { // Every 10 seconds (20 * 0.5s)
            ble.la.updateActivity()
        }
        
        counter += 1
    }
    
//    func pageHandler(mirror: Bool = false) -> String {
//        page.mirror = mirror //Checking if handler is being called from display mirror, stops centering text if true
//        textOutput = page.header()
//        
//        
//        if currentPage == "Default" { // DEFAULT PAGE HANDLER
//            let _ = 1 //placeholder cause this is stupid and shouldn't have to exist
//            
//        } else if currentPage == "Music" { // MUSIC PAGE HANDLER
//            let displayLines = page.musicDisplay()
//            
//            if displayLines.isEmpty {
//                textOutput = "broken"
//            } else {
//                textOutput.append(displayLines.joined(separator: "\n"))
//            }
//            
//        } else if currentPage == "Calendar" { // CALENDAR PAGE HANDLER
//            let displayLines = page.calendarDisplay()
//            
//            if displayLines.isEmpty {
//                textOutput = "Broken"
//            } else if info.getNumOfEvents() >= 2 {
//                for index in 0..<3 {
//                    print(displayLines[index])
//                    if index == 2 {
//                        textOutput.append(displayLines[index])
//                    } else {
//                        textOutput.append(displayLines[index] + "\n")
//                    }
//                }
//            } else {
//                textOutput.append(displayLines.joined(separator: "\n"))
//            }
//        } else {
//            textOutput = "No page selected"
//        }
//        
//        return textOutput
//    }
    
    func lowBatteryDisconnect() async {
        print("Low battery disconnect triggered")
        //Stopping timer to stop overwritting eachother
        stopTimer()
        
        displayOn = true

        //Looping animation drawing attention to disconnecting glasses
        var i = 0
        while i < 3 {
            textOutput = tm.centerText( "Battery low, disconnecting") + "."
            ble.sendTextCommand(seq: 1, text: textOutput)
            try? await Task.sleep(nanoseconds: 500_000_000)
            textOutput = tm.centerText( "Battery low, disconnecting") + ".."
            ble.sendTextCommand(seq: 2, text: textOutput)
            try? await Task.sleep(nanoseconds: 500_000_000)
            textOutput = tm.centerText( "Battery low, disconnecting") + "..."
            ble.sendTextCommand(seq: 3, text: textOutput)
            try? await Task.sleep(nanoseconds: 500_000_000)
            i += 1
        }
        ble.sendBlank()
        try? await Task.sleep(nanoseconds: 10_000_000)
        ble.disconnect()
    }
    
    @MainActor
    func disconnectProper() async {
        //Stopping timer to stop overwritting eachother
        stopTimer()
        
        displayOn = true

        //Looping animation drawing attention to disconnecting glasses
        var i = 0
        while i < 3 {
            textOutput = tm.centerText( "Disconnecting") + "."
            ble.sendTextCommand(seq: 1, text: textOutput)
            try? await Task.sleep(nanoseconds: 500_000_000)
            textOutput = tm.centerText( "Disconnecting") + ".."
            ble.sendTextCommand(seq: 2, text: textOutput)
            try? await Task.sleep(nanoseconds: 500_000_000)
            textOutput = tm.centerText( "Disconnecting") + "..."
            ble.sendTextCommand(seq: 3, text: textOutput)
            try? await Task.sleep(nanoseconds: 500_000_000)
            i += 1
        }
        ble.sendBlank()
        try? await Task.sleep(nanoseconds: 10_000_000)
        ble.disconnect()
    }
}
