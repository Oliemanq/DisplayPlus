//
//  DisplayPlusLiveActivityAttributes.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/11/25.
//

import ActivityKit
import SwiftUI


struct DisplayPlusWidgetAttributes: ActivityAttributes {
    public typealias BatteryActivityStatus = ContentState
    
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var glassesBattery: Float
        var caseBattery: Float
        var connectionStatus: String
        var glassesCharging: Bool
        var caseCharging: Bool
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}
