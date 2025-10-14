import Foundation

//
//  TimeThing.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

class DateThing: Thing {

    var currentDate: Date = Date()
    
    init(name: String, size: String = "Small") {
        super.init(name: name, type: "Date", thingSize: size)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override func update() {
        let newDate = Date()
        if currentDate != newDate {
            currentDate = newDate
            updated = true
        }
    }
    
    func getDate() -> Int {
        return (Int)(getTodayDateMedium().split(separator: ",")[0]) ?? 1
    }

    private func getTodayDateMedium()-> String{
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
    private func getTodayDateSmall()-> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        let weekDay = dateFormatter.string(from: Date())
        
        let date = Date()
        
        dateFormatter.dateFormat = "M"
        let month = dateFormatter.string(from: date)
        dateFormatter.dateFormat = "d"
        let day = dateFormatter.string(from: date)
        
        return "\(weekDay) \(month)/\(day)"
    }
    
    override func toString(mirror: Bool = false) -> String {
        if thingSize == "Small" {
            return getTodayDateSmall()
        } else if thingSize == "Medium" {
            return getTodayDateMedium()
        } else {
            return "Incorrect size input for Date thing: \(thingSize), must be Small or Medium"
        }
    }
}
