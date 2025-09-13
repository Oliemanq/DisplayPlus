//  DisplayPlusWidgetLiveActivity.swift
//  DisplayPlusWidget
//
//  Created by Oliver Heisel on 9/10/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LiveActivityView: View {
    let context: ActivityViewContext<DisplayPlusWidgetAttributes>
    
    var body: some View {
        // Lock screen/banner UI goes here
        VStack(spacing: 15) {
            if context.state.connectionStatus != "Connected" {
                HStack{
                    Text("Glasses \(context.state.connectionStatus)")
                }
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
    }
}

struct DisplayPlusWidgetLiveActivity: Widget {
    let kind = "DisplayPlusWidgetLiveActivity"
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DisplayPlusWidgetAttributes.self) { context in
            LiveActivityView(context: context)
                .activitySystemActionForegroundColor(Color.green)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    if context.state.connectionStatus == "Connected" {
                        Image(systemName: "eyeglasses")
                            .frame(width: 30)
                            .padding(.top, 5)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.connectionStatus == "Connected" {
                        Text("\(Int(context.state.glassesBattery))%")
                            .frame(width: 60)
                            .padding(.top, 5)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.connectionStatus == "Connected" {
                        ProgressView(value: Float(Int(context.state.glassesBattery)) / 100.0)
                            .accentColor(Color.green)
                            .padding(.top, 2)
                    } else {
                        Text("Glasses \(context.state.connectionStatus)")
                    }
                    // more content
                }
            } compactLeading: {
                Image(systemName: "eyeglasses")
            } compactTrailing: {
                Text("\(Int(context.state.glassesBattery))%")
            } minimal: {
                if context.state.connectionStatus == "Connected" {
                    Text("\(Int(context.state.glassesBattery))%")
                        .font(.system(size: context.state.glassesBattery==100 ? 11 : 14))
                } else {
                    Image(systemName: "nosign")
                }
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

