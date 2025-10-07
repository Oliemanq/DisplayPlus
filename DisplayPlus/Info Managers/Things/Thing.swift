//
//  LiveThing.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

import SwiftUI
import UniformTypeIdentifiers

class Thing: Transferable, Codable{
    static var transferRepresentation: some TransferRepresentation {
            // This allows to drag and drop our entire custom object
            // We are using this method for transfer because our object conforms to Codable,
            // which allows our object to be represented a JSON and this method along with exporting our object,
            // lets other apps know about our custom object and what its structure is
            CodableRepresentation(contentType: .myCustomObject)
            
            // This allows us to export a single value from our custom object.
            // For example, it allows us to paste only the title if we have copied the whole object
            ProxyRepresentation(exporting: \.name)
        }
    
    var name: String
    
    var type: String
    // Time - S/L
    // Date - S/L
    // Battery - S/L
    // Calendar - S/L
    // Weather - S/M
    // Music - M/L/XL
    
    var data: String
    
    var thingSize: String //Small, Medium, Large, XL
    //Small: 1x1, Medium: 2x1, Large: 4x1, XL: 4x2
    var spacerRight: Bool = false
    var spacerBelow: Bool = false
    var spacersRight: Int = 0
    var spacersBelow: Int = 0
    
    var updated: Bool = false
    
    init(name: String, type: String, data: String = "", thingSize: String = "Small"){
        self.name = name
        self.type = type
        self.data = data
        self.thingSize = thingSize
        switch thingSize {
        case "Small":
            spacersRight = 0
            spacerRight = false
        case "Medium":
            spacersRight = 1
            spacerRight = true
        case "Large":
            spacersRight = 3
            spacerRight = true
        case "XL":
            spacersRight = 3
            spacerRight = true
            spacersBelow = 1
            spacerBelow = true
        default:
            print("Invalid size for thing: \(thingSize), defaulting to Small")
        }
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

extension UTType {
    // exportedAs is declared in reverse domain name notation using a domain that you (or your employer) owns
    // this ensures there is only ever one owner to this kind of data
    static let myCustomObject = UTType(exportedAs: "Oliemanq.DisplayPlus.Thing")
}
