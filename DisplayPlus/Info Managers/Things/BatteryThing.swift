import Foundation
import UIKit

//
//  TimeThing.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

class BatteryThing: Thing {
    var battery: Int = 0
    
    init(name: String, size: String = "Small") {
        super.init(name: name, type: "Battery", thingSize: size)
        
    }
    
    override func update() {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"{
            battery = 75
        } else {
            if UIDevice.current.isBatteryMonitoringEnabled && UIDevice.current.batteryLevel >= 0.0 {
                battery = Int(UIDevice.current.batteryLevel * 100)
                data = "\(battery)%"
                updated = true
            } else {
                battery = 0
                data = "0%"
                updated = true
            }
        }
    }
    
    func setBatteryLevel(level: Int) {
        battery = level
        data = "\(battery)%"
    }
        
    
    override func toString() -> String {
        return data
    }
    func toInt() -> Int {
        return battery
    }
}
