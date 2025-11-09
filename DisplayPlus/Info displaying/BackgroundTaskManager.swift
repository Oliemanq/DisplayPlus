//
//  BackgroundTaskManager.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 5/25/25.
//
import SwiftUI

class BackgroundTaskManager: ObservableObject {
    private var ble: G1BLEManager
    private var pm: PageManager
    
    var timer: Timer?
    
    var textOutput = ""
    
    //various counters
    var counter: Int = 0
    var HBTriggerCounter: Int = 0
    var HBCounter: Int = 0
    var autoOffCounter: Int = 0
    var forceUpdateInfo: Bool = true
    
    var hardwareFetched = false
    
    var logging: Bool = false // For debugging purposes
    
    @AppStorage("displayOn", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var displayOn = false
    @AppStorage("autoOff", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var autoOff = false
    @AppStorage("currentPage", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var currentPage = ""
    @AppStorage("useLocation", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var useLocation: Bool = false
    @AppStorage("glassesBattery", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var glassesBattery: Int = 0
    @AppStorage("caseBattery", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var caseBattery: Int = 0
    @AppStorage("glassesInCase", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var glassesInCase = false

    init(ble: G1BLEManager, pmIn: PageManager) {
        self.ble = ble
        self.pm = pmIn
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
        pm.updateCurrentPage()
                
        if ble.connectionState == .connectedBoth {
            if !hardwareFetched {
                ble.fetchHardwareInfo()
                hardwareFetched = true
            }
            // Less frequent updates
            if counter % 30 == 0 { // Every 15 seconds (30 * 0.5s)
                ble.fetchData()
                
                if logging {
                    print("glasses info fetched")
                }
            }
            
            if ((glassesBattery <= 3 && glassesBattery != 0) || ble.glassesBatteryLeft <= 1 || ble.glassesBatteryRight <= 1){
                Task {
                    await self.lowBatteryDisconnect()
                }
            }
            
            HBTriggerCounter += 1
            if HBTriggerCounter % 48 == 0 || HBTriggerCounter == 1 { //Sending heartbeat command every ~24 seconds to maintain connection
                ble.sendHeartbeat(counter: HBCounter % 255)
                HBCounter += 1
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

            if displayOn && !glassesInCase {
                let pageText = pm.getCurrentPage().outputPage()
                ble.sendText(text: pageText, counter: counter)
            }
            
            forceUpdateInfo = false // Reset after first full update
        }
        
        if counter % 20 == 0 { // Every 10 seconds (20 * 0.5s)
            ble.la.updateActivity()
        }
        
        counter += 1
    }
        
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
