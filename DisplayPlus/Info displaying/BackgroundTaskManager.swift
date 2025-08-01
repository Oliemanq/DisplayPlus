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
    var batteryCounter: Int = 0
    var displayOnCounter: Int = 0
    var weatherCounter: Int = 0
    var silentTrigger: Bool = true
    
    @AppStorage("displayOn", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var displayOn = false
    @AppStorage("autoOff", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var autoOff = false
    @AppStorage("showingCalibration", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var showingCalibration = false
     
    init(ble: G1BLEManager, info: InfoManager, page: PageManager) {
        self.ble = ble
        self.page = page
        self.info = info
    }
    
    func startTimer() {
        if displayOn && !autoOff {
            displayOnCounter = 0
        }
        
        // Reset weather ticker when timer starts or restarts
        weatherCounter = 0
        
        // Invalidate existing timer before starting a new one
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1/2, repeats: true) { [weak self] _ in // Use weak self
            guard let self = self else {
                print("BackgroundTaskManager timer: self is nil, timer cannot continue.") // Log if self is nil
                return
            }
            if ble.connectionState == .connectedBoth {
                HBTriggerCounter += 1
                if HBTriggerCounter%56 == 0 || HBTriggerCounter == 1{ //Sending heartbeat command every ~28 seconds to maintain connection
                    ble.sendHeartbeat(counter: HBCounter%255)
                    HBCounter += 1
                }
                // Determine if it's time to update weather
                if (weatherCounter == 600) {  // 600 ticks * 0.5s/tick = 300 seconds = 5 mins
                    print("BackgroundTaskManager timer: Triggered weather update.")
                    info.update(updateWeatherBool: true)
                    weatherCounter = 0
                } else {
                    weatherCounter += 1
                }
                
                // Update info's data
                
                if batteryCounter % 15 == 0{
                    ble.fetchGlassesBattery()
                    if (ble.glassesBatteryAvg <= 3.0 || ble.glassesBatteryLeft <= 1 || ble.glassesBatteryRight <= 1) && ble.glassesBatteryAvg != 0.0{
                        Task{
                            await self.lowBatteryDisconnect()
                        }
                    }
                }
                
                
                
                let isAutoOff = autoOff
                let isDisplayOnInitially = displayOn
                
                if isAutoOff {
                    if isDisplayOnInitially {
                        displayOnCounter += 1
                    }
                    if displayOnCounter >= 10 {
                        displayOnCounter = 0
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
                
                counter += 1
                if counter > 255 {
                    counter = 0
                }
            }
        }
    }
        
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func pageHandler() -> String {
        @AppStorage("currentPage", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var currentPage = ""
        textOutput = page.header()
        
        if currentPage == "Default" { // DEFAULT PAGE HANDLER
            let displayLines = page.defaultDisplay()
            
            textOutput.append(displayLines.joined(separator: "\n"))
            
            
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
             for line in self.page.debugDisplay(index: self.counter%26) {
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

