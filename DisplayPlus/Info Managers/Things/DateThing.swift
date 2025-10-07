import Foundation

//
//  TimeThing.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

class DateThing: Thing {
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    init(name: String, size: String = "Small") {
        super.init(name: name, type: "Date", thingSize: size)
        
        self.data = getTodayDate()
    }
    
    override func update() {
        let newDate = getTodayDate()
        if data != newDate {
            data = newDate
            updated = true
        }
    }
    
    func getDate() -> Int {
        return (Int)(data.split(separator: ",")[0]) ?? 1
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
}

