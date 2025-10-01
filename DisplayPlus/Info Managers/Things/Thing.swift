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
    
    var enabled: Bool = false
    var page: String = ""
    var row: Int = 0
    var placeInRow: Int = 0
    
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
    
    func initForPage(page: String, row: Int = 0, placeInRow: Int = 0){
        self.enabled = true
        self.page = page
        self.row = row
        self.placeInRow = placeInRow
    }
    
    func update() {
        updated = true
    }
    
    func getAuthStatus() -> Bool {
        return false
    }
    
    func toString() -> String {
       return data
    }
}
