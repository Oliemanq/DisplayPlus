//
//  ViewIntents.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 4/17/25.
//

import Foundation
import AppIntents
import SwiftUI
import SwiftData

struct ConnectionStatus: AppIntent {
    static let title: LocalizedStringResource = "Check connection status"
    
    var connectionStatus: String = UserDefaults.standard.string(forKey: "connectionStatus") ?? ""
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        if connectionStatus != "" {
            let connected = connectionStatus.contains("Connected")
            print((connected ? "Connected" : "Disconnected"))
            return .result(value: connected)
        }else{
            print("BROKEN ----------------------------------------")
            return .result(value: false)
        }
    }
}


struct PageIntents{
    @AppStorage("currentPage") static private var currentPage = "Default"

    struct MusicPage: AppIntent {
        static let title: LocalizedStringResource = "Change view to music"
        
        func perform() async throws -> some IntentResult & ProvidesDialog {
            PageIntents.currentPage = "Music"
            return .result(dialog: "Changed view to music")
        }
    }
    
    struct CalendarPage: AppIntent {
        static let title: LocalizedStringResource = "Change view to calendar"
            
        func perform() async throws -> some IntentResult & ProvidesDialog {
            PageIntents.currentPage = "Calendar"
            return .result(dialog: "Changed view to Calendar")
        }
    }
    struct DefaultPage: AppIntent {
        static let title: LocalizedStringResource = "Change view to the default"
        
        func perform() async throws -> some IntentResult & ProvidesDialog {
            PageIntents.currentPage = "Default"
            return .result(dialog: "Changed view to the default")
        }
    }
    struct GetCurrentPage: AppIntent {
        static let title: LocalizedStringResource = "Get current view"
        
        func perform() async throws -> some IntentResult {
            return .result(value: PageIntents.currentPage)
        }
    }
}

struct DisplayIntents {
    @AppStorage("displayOn") static private var displayOn = true
    
    struct ToggleDisplayOn: AppIntent {
        static let title: LocalizedStringResource = "Turn the display on"
        
        func perform() async throws -> some IntentResult & ProvidesDialog {
            DisplayIntents.displayOn = true
            return .result(dialog: "Turned display on")
        }
    }
    
    struct ToggleDisplayOff: AppIntent {
        static let title: LocalizedStringResource = "Turn the display off"
        
        func perform() async throws -> some IntentResult & ProvidesDialog {
            DisplayIntents.displayOn = false
            return .result(dialog: "Turned display off")
        }
    }
    
    struct GetDisplayOn: AppIntent {
        static let title: LocalizedStringResource = "Get display status"
        
        func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
            return .result(value: DisplayIntents.displayOn)
        }
    }
}
