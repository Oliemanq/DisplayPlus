//
//  LiveThing.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

import SwiftUI
import UniformTypeIdentifiers

class Thing: NSObject, Encodable, Decodable, ObservableObject {
    var theme: ThemeColors = ThemeColors()
    
    var name: String
    var type: String
    var data: String
    var size: String //Small, Medium, Large, XL
    //Small: 1x1, Medium: 2x1, Large: 4x1, XL: 4x2
    var spacerRight: Bool = false
    var spacerBelow: Bool = false
    var spacersRight: Int = 0
    var spacersBelow: Int = 0
        
    var updated: Bool = false
    
    private enum CodingKeys: String, CodingKey {
        case name
        case type
        case data
        case size
        case spacerRight
        case spacerBelow
        case spacersRight
        case spacersBelow
        case updated
    }
    
    init(name: String, type: String, data: String = "", thingSize: String = "Small"){
        if type == "Empty" {
            print("Created empty thing")
        }
        self.name = name
        self.type = type
        self.data = data
        self.size = thingSize
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
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.type = try container.decode(String.self, forKey: .type)
        self.data = try container.decodeIfPresent(String.self, forKey: .data) ?? ""
        self.size = try container.decodeIfPresent(String.self, forKey: .size) ?? "Small"
        self.spacerRight = try container.decodeIfPresent(Bool.self, forKey: .spacerRight) ?? false
        self.spacerBelow = try container.decodeIfPresent(Bool.self, forKey: .spacerBelow) ?? false
        self.spacersRight = try container.decodeIfPresent(Int.self, forKey: .spacersRight) ?? 0
        self.spacersBelow = try container.decodeIfPresent(Int.self, forKey: .spacersBelow) ?? 0
        self.updated = try container.decodeIfPresent(Bool.self, forKey: .updated) ?? false
        super.init()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(data, forKey: .data)
        try container.encode(size, forKey: .size)
        try container.encode(spacerRight, forKey: .spacerRight)
        try container.encode(spacerBelow, forKey: .spacerBelow)
        try container.encode(spacersRight, forKey: .spacersRight)
        try container.encode(spacersBelow, forKey: .spacersBelow)
        try container.encode(updated, forKey: .updated)
    }
    
    func update() {
        updated = true
    }
    
    func addTheme(themeIn: ThemeColors) {
        self.theme = themeIn
    }
    
    func getAuthStatus() -> Bool {
        return false
    }
    
    func getSettingsView() -> AnyView {
        AnyView(
            ScrollView(.vertical) {
                HStack{
                    Text("Invalid Thing type, no defined settings page")
                }
                .settingsItem(themeIn: theme)
            }
        )
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

