//
//  DisplayPlusWidgetLiveActivity.swift
//  DisplayPlusWidget
//
//  Created by Oliver Heisel on 9/10/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct DisplayPlusWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var glassesBattery: Float
        var caseBattery: Float
        var connectionStatus: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct DisplayPlusWidgetLiveActivity: Widget {
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DisplayPlusWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack(spacing: 15) {
                HStack{
                    Text("Glasses \(context.state.connectionStatus)")
                }
                if context.state.connectionStatus == "Connected" {
                    HStack {
                        Image(systemName: "eyeglasses")
                            .frame(width: 30)
                        ProgressView(value: context.state.glassesBattery / 100.0)
                        Text("\(Int(context.state.glassesBattery))%")
                            .frame(width: 60)
                        
                    }
                    HStack {
                        Image(systemName: "earbuds.case")
                            .frame(width: 30)
                        ProgressView(value: context.state.caseBattery / 100.0)
                        Text("\(Int(context.state.caseBattery))%")
                            .frame(width: 60)
                    }
                }
            }
            .accentColor(Color.green)
            .padding(15)
            .activityBackgroundTint(Color.green)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "eyeglasses")
                        .frame(width: 30)
                        .padding(.top, 5)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(Int(context.state.glassesBattery))%")
                        .frame(width: 60)
                        .padding(.top, 5)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: Float(Int(context.state.glassesBattery)) / 100.0)
                        .accentColor(Color.green)
                        .padding(.top, 2)
                    // more content
                }
            } compactLeading: {
                Image(systemName: "eyeglasses")
            } compactTrailing: {
                Text("\(Int(context.state.glassesBattery))%")
            } minimal: {
                Text("\(Int(context.state.glassesBattery))%")
            }
            .keylineTint(Color.green)
        }
    }
}

extension DisplayPlusWidgetAttributes {
    fileprivate static var preview: DisplayPlusWidgetAttributes {
        DisplayPlusWidgetAttributes(name: "World")
    }
}

#Preview("Notification", as: .content, using: DisplayPlusWidgetAttributes.preview) {
   DisplayPlusWidgetLiveActivity()
} contentStates: {
    DisplayPlusWidgetAttributes.ContentState(glassesBattery: 75, caseBattery: 50, connectionStatus: "Connected")
    DisplayPlusWidgetAttributes.ContentState(glassesBattery: 75, caseBattery: 50, connectionStatus: "Disconnected")
    DisplayPlusWidgetAttributes.ContentState(glassesBattery: 100, caseBattery: 100, connectionStatus: "Connected")
    DisplayPlusWidgetAttributes.ContentState(glassesBattery: 0, caseBattery: 0, connectionStatus: "Connected")
}

