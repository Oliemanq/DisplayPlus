import Foundation

//
//  TimeThing.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

class TimeThing: Thing {
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
}
