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
    var data: String
    
    var thingSize: String //Small, Medium, Large, XL
    //Small: 1x1, Medium: 2x1, Large: 4x1, XL: 4x2
    
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

extension UTType {
    // exportedAs is declared in reverse domain name notation using a domain that you (or your employer) owns
    // this ensures there is only ever one owner to this kind of data
    static let myCustomObject = UTType(exportedAs: "Oliemanq.DisplayPlus.Thing")
}
