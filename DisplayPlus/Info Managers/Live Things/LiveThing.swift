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
    
    var updated: Bool = false
    
    init(name: String, type: String, data: String = ""){
        self.name = name
        self.type = type
        self.data = data
    }
    init(name: String, type: String){
        self.name = name
        self.type = type
        self.data = ""
    }
    
    func update() {
        updated = true
    }
    
    func toString() -> String {
       return ("Thing: \(name), Type: \(type)")
    }
}
