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
    private var formattingManager: FormattingManager
    private var infoManager: InfoManager
    
    var timer: Timer?
    var counter: Int = 0
    var HBCounter: Int = 1
    var displayOnCounter: Int = 0
    private var weatherUpdateTicker: Int = 0 // New counter for less frequent weather updates
    
    init(ble: G1BLEManager, info: InfoManager, formatting: FormattingManager) {
        self.ble = ble
        self.formattingManager = formatting
        self.infoManager = info
    }
    
    func startTimer() {
        if UserDefaults.standard.bool(forKey: "displayOn") && !UserDefaults.standard.bool(forKey: "autoOff") {
            displayOnCounter = 0
        }
        // Reset weather ticker when timer starts or restarts
        weatherUpdateTicker = 0
        
        // Invalidate existing timer before starting a new one
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1/2, repeats: true) { [weak self] _ in // Use weak self
            guard let self = self else {
                print("BackgroundTaskManager timer: self is nil, timer cannot continue.") // Log if self is nil
                return
            }
            if ble.connectionState == .connectedBoth {
                if counter%51 == 0{ //Sending heartbeat command every ~25 seconds to maintain connection
                    ble.sendHeartbeat(counter: HBCounter)
                    
                    HBCounter += 1
                    if HBCounter > 255{
                        HBCounter = 0
                    }
                }
                // Determine if it's time to update weather
                let shouldUpdateWeather = (weatherUpdateTicker >= 600) // 600 ticks * 0.5s/tick = 300 seconds = 5 mins
                
                // Update InfoManager's data
                infoManager.update(updateWeatherBool: shouldUpdateWeather)
                
                ble.fetchGlassesBattery()
                
                if shouldUpdateWeather {
                    weatherUpdateTicker = 0 // Reset ticker
                    print("BackgroundTaskManager timer: Triggered weather update.")
                } else {
                    weatherUpdateTicker += 1
                }
                
                let isAutoOff = UserDefaults.standard.bool(forKey: "autoOff")
                let isDisplayOnInitially = UserDefaults.standard.bool(forKey: "displayOn") // displayOn state at the start of this tick
                
                if isAutoOff {
                    if isDisplayOnInitially {
                        displayOnCounter += 1
                    }
                    if displayOnCounter >= 10 {
                        displayOnCounter = 0
                        UserDefaults.standard.set(false, forKey: "displayOn")
                    }
                }
                
                // Re-fetch displayOn as it might have been changed by the autoOff logic above in the same tick
                let currentDisplayOn = UserDefaults.standard.bool(forKey: "displayOn")
                
                if currentDisplayOn {
                    let pageText = pageHandler()
                    ble.sendText(text: pageText, counter: counter)
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
        var textOutput = ""
        textOutput = formattingManager.header()
        
        if let page = UserDefaults.standard.string(forKey: "currentPage") {
            if page == "Default" { // DEFAULT PAGE HANDLER
                let displayLines = formattingManager.defaultDisplay()
                
                textOutput.append(displayLines.joined(separator: "\n"))
                
                
            } else if page == "Music" { // MUSIC PAGE HANDLER
                let displayLines = formattingManager.musicDisplay()
                
                if displayLines.isEmpty {
                    textOutput = "broken"
                } else {
                    textOutput.append(displayLines.joined(separator: "\n"))
                }
                
            } else if page == "Calendar" { // CALENDAR PAGE HANDLER
                let displayLines = formattingManager.calendarDisplay()
                
                if displayLines.isEmpty {
                    textOutput = "broken"
                } else {
                    textOutput.append(displayLines.joined(separator: "\n"))
                }
            /*
            }else if page == "Debug" {
                for line in self.formattingManager.debugDisplay(index: self.counter%26) {
                    textOutput += line + "\n"
                }
             */
            }else {
                textOutput = "No page selected"
            }
        } else {
            textOutput = "No page selected"
        }
        
        return textOutput
    }
}
