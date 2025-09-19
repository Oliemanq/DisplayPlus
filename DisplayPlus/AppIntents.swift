//
//  AppIntents.swift
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
    static let title: LocalizedStringResource = "Get device connection status"
        
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let connectionStatus: String = UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.value(forKey: "connectionStatus") as! String

        if connectionStatus != "" {
            let connected: Bool = connectionStatus.contains("Connected")
            print((connected ? "Connected" : "Disconnected"))
            return .result(value: connected)
        }else{
            print("BROKEN")
            return .result(value: false)
        }
    }
}


struct PageIntents{
    // Combined page selector intent using an AppEnum so the intent shows a dropdown with the three options
    enum PageOption: String, AppEnum, CaseDisplayRepresentable {
        case music = "Music"
        case calendar = "Calendar"
        case `default` = "Default"

        static var typeDisplayRepresentation: TypeDisplayRepresentation = "Page"
        
        static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
            .default: "Default",
            .music: "Music",
            .calendar: "Calendar"
        ]
    }

    struct ChangePage: AppIntent {
        static let title: LocalizedStringResource = "Change page"

        @Parameter(title: "Page")
        var page: PageOption

        func perform() async throws -> some IntentResult & ProvidesDialog {
            UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.set(page.rawValue, forKey: "currentPage")
            return .result(dialog: "Changed view to \(page.rawValue)")
        }
    }
    
    struct NextPage: AppIntent {
        static let title: LocalizedStringResource = "Next page"
        
        let currentPage: String = UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.string(forKey: "currentPage") ?? "Default"

        func perform() async throws -> some IntentResult & ProvidesDialog {
            if currentPage == "Default" {
                UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.set("Music", forKey: "currentPage")
                return .result(dialog: "Changed page to Music")
            } else if currentPage == "Music" {
                UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.set("Calendar", forKey: "currentPage")
                return .result(dialog: "Changed page to Calendar")
            } else {
                UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.set("Default", forKey: "currentPage")
                return .result(dialog: "Changed page to Default")
            }
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
        let connectionStatus: String = UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.string(forKey: "connectionStatus") ?? "Disconnected"

        func perform() async throws -> some IntentResult & ProvidesDialog {
            if connectionStatus != "Connected" {
                UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.set(true, forKey: "displayOn")
                return .result(dialog: "Turned display on")
            } else {
                return .result(dialog: "Cannot turn display on while connected to the glasses.")
            }
        }
    }
    
    struct ToggleDisplayOff: AppIntent {
        static let title: LocalizedStringResource = "Turn the display off"
        let connectionStatus: String = UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.string(forKey: "connectionStatus") ?? "Disconnected"
        
        func perform() async throws -> some IntentResult & ProvidesDialog {
            if connectionStatus == "Connected" {
                UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.set(false, forKey: "displayOn")
                return .result(dialog: "Turned display off")
            } else {
                return .result(dialog: "Cannot turn display off while disconnected from the glasses.")
            }
        }
    }
    
    struct ToggleDisplay: AppIntent {
        static let title: LocalizedStringResource = "Toggle current display status (On/Off)"
        let connectionStatus: String = UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.string(forKey: "connectionStatus") ?? "Disconnected"
                
        func perform() async throws -> some IntentResult & ProvidesDialog {
            if connectionStatus == "Connected" {

                let defaults = UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")
                let current = defaults?.bool(forKey: "displayOn") ?? false
                let toggled = !current
                
                defaults?.set(toggled, forKey: "displayOn")
                
                return .result(dialog: "Turned display \(toggled ? "on" : "off")")
            } else {
                return .result(dialog: "Cannot toggle display while disconnected from the glasses.")
            }
        }
    }
    
    struct GetDisplayState: AppIntent {
        static let title: LocalizedStringResource = "Get display status (On/Off)"
        
        func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
            return .result(value: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.bool(forKey: "displayOn") ?? false)
        }
    }
}

