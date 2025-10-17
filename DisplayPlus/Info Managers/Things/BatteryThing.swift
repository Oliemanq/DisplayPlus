import Foundation
import SwiftUI
import UIKit

//
//  TimeThing.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

class BatteryThing: Thing {
    @AppStorage("glassesBattery", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var glassesBattery: Int = 0
    
    var phoneBattery: Int = 0
    
    init(name: String, size: String = "Small") {
        super.init(name: name, type: "Battery", thingSize: size)
        UIDevice.current.isBatteryMonitoringEnabled = true // Enable battery monitoring
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override func update() {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"{
            phoneBattery = 75
        } else {
            if UIDevice.current.isBatteryMonitoringEnabled && UIDevice.current.batteryLevel >= 0.0 {
                phoneBattery = Int(UIDevice.current.batteryLevel * 100)
                data = "\(phoneBattery)%"
                updated = true
            } else {
                phoneBattery = 0
                data = "0%"
                updated = true
            }
        }
    }
    
    func setBatteryLevel(level: Int) {
        phoneBattery = level
        data = "\(phoneBattery)%"
    }
        
    
    override func toString(mirror: Bool = false) -> String {
        if size == "Small" {
            return "Phone - \(phoneBattery)%"
        } else if size == "Medium" {
            return " [ Phone - \(phoneBattery)% | Glasses - \(glassesBattery)% ] "
        } else {
            return "Incorrect size input for phoneBattery thing: \(size), must be Small or Medium"
        }
    }
    func toInt() -> Int {
        return phoneBattery
    }
}

