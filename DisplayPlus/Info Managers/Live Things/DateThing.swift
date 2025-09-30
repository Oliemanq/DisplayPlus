import Foundation

//
//  TimeThing.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

class DateThing: Thing {
    init(name: String) {
        super.init(name: name, type: "Date")
        
        self.data = getTodayDate()
    }
    
    override func update() {
        let newDate = getTodayDate()
        if data != newDate {
            data = newDate
            updated = true
        }
    }

    private func getTodayDate()-> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        let weekDay = dateFormatter.string(from: Date())
        
        let date = Date()
        
        dateFormatter.dateFormat = "MMMM"
        let month = dateFormatter.string(from: date)
        dateFormatter.dateFormat = "d"
        let day = dateFormatter.string(from: date)
        
        return "\(weekDay), \(month) \(day)"
    }
    
    override func toString() -> String {
        return data
    }
}
