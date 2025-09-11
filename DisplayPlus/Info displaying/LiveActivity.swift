////  LiveActivity.swift
////  DisplayPlus
////
////  Created by Oliver Heisel on 9/11/25.
////
//
//import Foundation
//import ActivityKit
//import WidgetKit
//import SwiftUI
//
//class LiveActivityManager {
//    @AppStorage("glassesBattery", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var glassesBattery: Int = 0
//    @AppStorage("caseBattery", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var caseBattery: Int = 0
//    @AppStorage("connectionStatus", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var connectionStatus: String = "Disconnected"
//    
//    
//    func startActivity() {
//        // Ensure Live Activities are allowed on this device
//        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
//            #if DEBUG
//            print("Live Activities are not enabled on this device.")
//            #endif
//            return
//        }
//        
//        // Fixed attributes for the activity
//        let attributes = DisplayPlusWidgetAttributes(name: "DisplayPlus")
//        
//        // Dynamic state for the activity (convert Int -> Float as expected by ContentState)
//        let contentState = DisplayPlusWidgetAttributes.ContentState(
//            glassesBattery: Float(glassesBattery),
//            caseBattery: Float(caseBattery),
//            connectionStatus: connectionStatus
//        )
//        
//        let content = ActivityContent(state: contentState, staleDate: nil)
//        
//        do {
//            _ = try Activity<DisplayPlusWidgetAttributes>.request(
//                attributes: attributes,
//                content: content
//            )
//            #if DEBUG
//            print("Live Activity started")
//            #endif
//        } catch {
//            #if DEBUG
//            print("Failed to start Live Activity: \(error)")
//            #endif
//        }
//    }
//    
//    func updateActivity(){
//        if let activity = Activity<DisplayPlusWidgetAttributes>.activities.first {
//            let updatedState = DisplayPlusWidgetAttributes.ContentState(
//                glassesBattery: Float(glassesBattery),
//                caseBattery: Float(caseBattery),
//                connectionStatus: connectionStatus
//            )
//            let content = ActivityContent(state: updatedState, staleDate: nil)
//            await activity.update(content)
//        }
//    }
//}
