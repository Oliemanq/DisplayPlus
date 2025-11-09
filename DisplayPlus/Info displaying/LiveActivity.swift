//  LiveActivity.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/11/25.
//

import Foundation
import ActivityKit
import WidgetKit
import SwiftUI

class LiveActivityManager: ObservableObject {
    @AppStorage("glassesBattery", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var glassesBattery: Int = 0
    @AppStorage("caseBattery", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var caseBattery: Int = 0
    @AppStorage("connectionStatus", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var connectionStatus: String = "Disconnected"
    @AppStorage("glassesInCase", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var glassesInCase = false
    @AppStorage("caseCharging", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var caseCharging: Bool = false
    @AppStorage("displayOn", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var displayOn = false
    
    @Published private var activity: Activity<DisplayPlusWidgetAttributes>? = nil
    
    func startActivity() {
        // Ensure Live Activities are allowed on this device
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            #if DEBUG
            print("Live Activities are not enabled on this device.")
            #endif
            return
        }
        
        let attributes = DisplayPlusWidgetAttributes(name: "Main")
        let state = DisplayPlusWidgetAttributes.ContentState(
            glassesBattery: Float(glassesBattery), caseBattery: Float(caseBattery),
            connectionStatus: connectionStatus,
            glassesCharging: glassesInCase,
            caseCharging: caseCharging,
            displayOn: displayOn
        )
        let content = ActivityContent(state: state, staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date())!)
        
        activity = try? Activity<DisplayPlusWidgetAttributes>.request(attributes: attributes, content: content, pushType: nil)
    }
    
    func updateActivity() {
        let state = DisplayPlusWidgetAttributes.ContentState(
            glassesBattery: Float(glassesBattery),
            caseBattery: Float(caseBattery),
            connectionStatus: connectionStatus,
            glassesCharging: glassesInCase,
            caseCharging: caseCharging,
            displayOn: displayOn
        )
        
        Task{
            let updatedContent = ActivityContent(state: state, staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date())!)
            await activity?.update(updatedContent)
        }

    }
    
    func stopActivity() {
        let state = DisplayPlusWidgetAttributes.ContentState(
            glassesBattery: 0,
            caseBattery: 0,
            connectionStatus: "Disconnected",
            glassesCharging: false,
            caseCharging: false,
            displayOn: false
        )
        
        Task{
            let finalContent = ActivityContent(state: state, staleDate: nil)
            await activity?.end(finalContent, dismissalPolicy: .immediate)
        }
    }
}

