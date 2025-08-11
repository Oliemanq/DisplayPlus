//
//  BackgroundTaskManager.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 5/25/25.
//


// File: BackgroundTaskManager.swift
import SwiftUI // For potential access to shared objects or UserDefaults

class BackgroundTaskManager: ObservableObject { // Added ObservableObject
    // Managers needed for the background task - make non-optional
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
    
    var logging: Bool = true // For debugging purposes
    
    
    @AppStorage("displayOn", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var displayOn = false
    @AppStorage("autoOff", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var autoOff = false
    @AppStorage("currentPage", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var currentPage = ""
    @AppStorage("useLocation", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var useLocation: Bool = false


     
    init(ble: G1BLEManager, info: InfoManager, page: PageManager) {
        self.ble = ble
        self.page = page
        self.info = info
    }
    
    func startTimer() {
        // Invalidate existing timer before starting a new one
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in // Use weak self
            guard let self = self else {
                print("BackgroundTaskManager timer: self is nil, timer cannot continue.") // Log if self is nil
                return
            }
            
            //update time and weather
            info.updateTime()
            info.updateMusic()
            
            //update battery
            if counter % 20 == 0 || forceUpdateInfo { // Every 10 seconds (20 * 0.5s)
                info.updateBattery()
                if logging {
                    print("Battery updated")
                }
            }
            
            //update calendar
            if counter % 120 == 0 || forceUpdateInfo { // Every 60 seconds (120 * 0.5s)
                info.updateCalendar()
                if logging {
                    print("Calendar updated")
                }
            }
            
            //update weather
            if useLocation && (counter % 600 == 0 || forceUpdateInfo) {  // 600 ticks * 0.5s/tick = 300 seconds = 5 mins
                Task {
                    if self.info.getLocationAuthStatus() {
                        await self.info.updateWeather()
                    }
                }
                if logging {
                    print("Weather updated")
                }
            }
            
            forceUpdateInfo = false // Reset after first full update
            
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
                if HBTriggerCounter % 56 == 0 || HBTriggerCounter == 1 { //Sending heartbeat command every ~28 seconds to maintain connection
                    ble.sendHeartbeat(counter: HBCounter%255)
                    HBCounter += 1
                    if logging {
                    }
                }
                
                if counter % 60 == 0 { // every 30 seconds (60 * 0.5s)
                    ble.fetchGlassesBattery()
                    if (ble.glassesBatteryAvg <= 3.0 || ble.glassesBatteryLeft <= 1 || ble.glassesBatteryRight <= 1) && ble.glassesBatteryAvg != 0.0{
                        Task{
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
                
                //info.changed is to reduce unnecesary updates to the glasses
                if currentDisplayOn && info.changed {
                    let pageText = pageHandler()
                    ble.sendText(text: pageText, counter: counter)
                    info.changed = false
                    
                }
                
            }
            counter += 1
        }
    }
        
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func pageHandler() -> String {
        textOutput = page.header()
        
        if currentPage == "Default" { // DEFAULT PAGE HANDLER
            let _ = 1 //placeholder cause this is stupid and shouldn't have to exist
            
        } else if currentPage == "Music" { // MUSIC PAGE HANDLER
            let displayLines = page.musicDisplay()
            
            if displayLines.isEmpty {
                textOutput = "broken"
            } else {
                textOutput.append(displayLines.joined(separator: "\n"))
            }
            
        } else if currentPage == "Calendar" { // CALENDAR PAGE HANDLER
            let displayLines = page.calendarDisplay()
            
            if displayLines.isEmpty {
                textOutput = "Broken"
            } else if info.numOfEvents >= 2 {

                for index in 0..<3 {
                    print(displayLines[index])
                    if index == 2{
                        textOutput.append(displayLines[index])
                    }else{
                        textOutput.append(displayLines[index] + "\n")
                    }
                }
            }else{
                textOutput.append(displayLines.joined(separator: "\n"))
            }
            /*
             }else if currentPage == "Debug" {
             for line in page.debugDisplay(index: counter%26) {
             textOutput += line + "\n"
             }
             */
        }else {
            textOutput = "No page selected"
        }
        
        return textOutput
    }
    
    @MainActor
    func lowBatteryDisconnect() async{
        //Stopping timer to stop overwritting eachother
        stopTimer()
        
        displayOn = true

        //Looping animation drawing attention to disconnecting glasses
        var i = 0
        while i < 3{
            textOutput = page.centerText(text: "Battery low, disconnecting") + "."
            ble.sendTextCommand(seq: 1, text: textOutput)
            try? await Task.sleep(nanoseconds: 500_000_000)
            textOutput = page.centerText(text: "Battery low, disconnecting") + ".."
            ble.sendTextCommand(seq: 2, text: textOutput)
            try? await Task.sleep(nanoseconds: 500_000_000)
            textOutput = page.centerText(text: "Battery low, disconnecting") + "..."
            ble.sendTextCommand(seq: 3, text: textOutput)
            try? await Task.sleep(nanoseconds: 500_000_000)
            i += 1
        }
        ble.sendBlank()
        try? await Task.sleep(nanoseconds: 10_000_000)
        ble.disconnect()
    }
    
    @MainActor
    func disconnectProper() async{
        //Stopping timer to stop overwritting eachother
        stopTimer()
        
        displayOn = true

        //Looping animation drawing attention to disconnecting glasses
        var i = 0
        while i < 3{
            textOutput = page.centerText(text: "Disconnecting") + "."
            ble.sendTextCommand(seq: 1, text: textOutput)
            try? await Task.sleep(nanoseconds: 500_000_000)
            textOutput = page.centerText(text: "Disconnecting") + ".."
            ble.sendTextCommand(seq: 2, text: textOutput)
            try? await Task.sleep(nanoseconds: 500_000_000)
            textOutput = page.centerText(text: "Disconnecting") + "..."
            ble.sendTextCommand(seq: 3, text: textOutput)
            try? await Task.sleep(nanoseconds: 500_000_000)
            i += 1
        }
        ble.sendBlank()
        try? await Task.sleep(nanoseconds: 10_000_000)
        ble.disconnect()
    }
}
