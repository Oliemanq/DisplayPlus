//
//  DataItem.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 4/17/25.
//
import Foundation
import SwiftData

@Model
class DataItem: Identifiable {
    
    @Attribute(.unique)var id: String
    var currentPage: String
    var displayOn: Bool
    var currentDisplay: String
    
    init() {
        self.id = UUID().uuidString
        self.currentPage = "Default"
        self.displayOn = true
        self.currentDisplay = ""
    }
}
