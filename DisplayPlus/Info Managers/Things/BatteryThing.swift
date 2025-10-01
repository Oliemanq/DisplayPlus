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
    
    init(name: String) {
        super.init(name: name, type: "Battery")
        
    }
    
    override func update() {
        if UIDevice.current.isBatteryMonitoringEnabled && UIDevice.current.batteryLevel >= 0.0 {
            battery = Int(UIDevice.current.batteryLevel * 100)
            updated = true
        } else {
            battery = 0
            updated = true
        }
    }
    
    override func toString() -> String {
        return "\(battery)%"
    }
    func toInt() -> Int {
        return battery
    }
}
