//
//  LiveThing.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

class Thing {
    var name: String
    var type: String
    var data: String
    
    var thingSize: String
    
    var updated: Bool = false
    
    init(name: String, type: String, data: String = "", thingSize: String = "Small"){
        self.name = name
        self.type = type
        self.data = data
        self.thingSize = thingSize
    }
    
    func update() {
        updated = true
    }
    
    func getAuthStatus() -> Bool {
        return false
    }
    
    func toString(mirror: Bool = false) -> String {
       return data
    }
}
