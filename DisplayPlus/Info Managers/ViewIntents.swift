//
//  ViewIntents.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 4/17/25.
//

import Foundation
import AppIntents
import WidgetKit
import SwiftUI
import SwiftData

struct ConnectionStatus: AppIntent {
    static let title: LocalizedStringResource = "Check connection status"
    
    @AppStorage("connectionStatus", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var connectionStatus: String = ""
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        if connectionStatus != "" {
            let connected = connectionStatus.contains("Connected")
            print((connected ? "Connected" : "Disconnected"))
            return .result(value: connected)
        }else{
            print("BROKEN")
            return .result(value: false)
        }
    }
}


struct PageIntents{
    struct MusicPage: AppIntent {
        static let title: LocalizedStringResource = "Change page to Music"
        
        func perform() async throws -> some IntentResult & ProvidesDialog {
            UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.set("Music", forKey: "currentPage")
            return .result(dialog: "Changed view to music")
        }
    }
    
    struct CalendarPage: AppIntent {
        static let title: LocalizedStringResource = "Change page to Calendar"
            
        func perform() async throws -> some IntentResult & ProvidesDialog {
            UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.set("Calendar", forKey: "currentPage")
            return .result(dialog: "Changed view to Calendar")
        }
    }
    struct DefaultPage: AppIntent {
        static let title: LocalizedStringResource = "Change page to Default"
        
        func perform() async throws -> some IntentResult & ProvidesDialog {
            UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.set("Default", forKey: "currentPage")
            return .result(dialog: "Changed view to the default")
        }
    }
    struct GetCurrentPage: AppIntent {
        static let title: LocalizedStringResource = "Get current page"
        
        func perform() async throws -> some IntentResult {
            return .result(value: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.string(forKey: "currentPage"))
        }
    }
}

public struct DisplayIntents {
    struct ToggleDisplayOn: AppIntent {
        static let title: LocalizedStringResource = "Turn the display on"
        
        func perform() async throws -> some IntentResult & ProvidesDialog {
            UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.set(true, forKey: "displayOn")
            return .result(dialog: "Turned display on")
        }
    }
    
    struct ToggleDisplayOff: AppIntent {
        static let title: LocalizedStringResource = "Turn the display off"
        
        func perform() async throws -> some IntentResult & ProvidesDialog {
            UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.set(false, forKey: "displayOn")
            return .result(dialog: "Turned display off")
        }
    }
    
    struct ToggleDisplay: AppIntent {
        static let title: LocalizedStringResource = "Toggle current display status (On/Off)"
        
        @AppStorage("displayOn", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var displayOn = false
        
        func perform() async throws -> some IntentResult & ProvidesDialog {
            displayOn.toggle()
            print("Turned display \(displayOn ? "on" : "off")")
            return .result(dialog: "Turned display \(displayOn ? "on" : "off")")
        }
    }
    
    struct GetDisplayOn: AppIntent {
        static let title: LocalizedStringResource = "Get display status (On/Off)"
        
        func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
            return .result(value: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.bool(forKey: "displayOn") ?? false)
        }
    }
    
    struct SetDisplayStateIntent: SetValueIntent {
        static var title: LocalizedStringResource = "Set Display State"

        // This parameter will receive the 'on' or 'off' value from the toggle
        @Parameter(title: "Display On")
        var value: Bool

        func perform() async throws -> some IntentResult {
            // Set the UserDefaults value based on the toggle's state
            @AppStorage("displayOn", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var displayOn = false
            displayOn = value
            print("Display turned \(value ? "on" : "off")")
            return .result()
        }
    }
}
