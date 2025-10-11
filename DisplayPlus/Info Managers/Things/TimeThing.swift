import Foundation

//
//  TimeThing.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

class TimeThing: Thing {
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    init(name: String, size: String = "Small") {
        super.init(name: name, type: "Time", data: Date().formatted(date: .omitted, time: .shortened), thingSize: size)
    }
    
    override func update() {
        let newTime = Date().formatted(date: .omitted, time: .shortened)
        if data != newTime {
            data = newTime
            updated = true
        }
    }
    
    override func toString(mirror: Bool = false) -> String {
        if thingSize == "Small" {
            return data
        } else {
            return "Incorrect size input for Time thing: \(thingSize), must be Small"
        }
    }
}

