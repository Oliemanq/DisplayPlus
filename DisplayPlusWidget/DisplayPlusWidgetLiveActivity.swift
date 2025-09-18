//  DisplayPlusWidgetLiveActivity.swift
//  DisplayPlusWidget
//
//  Created by Oliver Heisel on 9/10/25.
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

struct LiveActivityView: View {
    let context: ActivityViewContext<DisplayPlusWidgetAttributes>
    @Environment(\.colorScheme) var colorScheme
    var darkMode: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
        // Lock screen/banner UI goes here
        VStack(spacing: 15) {
            if context.state.connectionStatus != "Connected" {
                HStack{
                    Text("Glasses \(context.state.connectionStatus)")
                        .padding(10)
                        .foregroundStyle(Color.green)
                        .background(
                            Capsule(style: .circular)
                                .foregroundStyle(Color.green.opacity(darkMode ? 0.3 : 0.1))
                        )
                }
            }
            if context.state.connectionStatus == "Connected" {
                HStack {
                    Image(systemName: "eyeglasses")
                        .frame(width: 30)
                    if context.state.glassesCharging {
                        Image(systemName: "bolt.fill")
                    }
                    ProgressView(value: context.state.glassesBattery / 100.0)
                    Text("\(Int(context.state.glassesBattery))%")
                        .frame(width: 60)
                }
                .accentColor(context.state.glassesBattery > 20 ? Color.green : Color.red)
                HStack {
                    Image(systemName: "earbuds.case")
                        .frame(width: 30)
                    if context.state.caseCharging {
                        Image(systemName: "bolt.fill")
                    }
                    ProgressView(value: context.state.caseBattery / 100.0)
                    Text("\(Int(context.state.caseBattery))%")
                        .frame(width: 60)
                }
                .accentColor(context.state.caseBattery > 20 ? Color.green : Color.red)
                HStack{
                    Text("Glasses \(context.state.connectionStatus)")
                        .padding(10)
                        .foregroundStyle(Color.green)
                        .background(
                            Capsule(style: .circular)
                                .foregroundStyle(Color.green.opacity(darkMode ? 0.3 : 0.1))
                        )
                    Spacer()
                    Button(intent: PageIntents.NextPage()) {
                        Image(systemName: "book.pages")
                    }
                    .accentColor(Color.green)
                    Button(intent: DisplayIntents.ToggleDisplay()) {
                        Image(systemName: context.state.displayOn ? "lightswitch.on" : "lightswitch.off")
                    }
                    .accentColor(Color.green)
                }

            }
        }
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
                DynamicIslandExpandedRegion(.leading) {
                    if context.state.connectionStatus == "Connected" {
                        Image(systemName: "eyeglasses")
                            .frame(width: 60, height: 30)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.connectionStatus == "Connected" {
                        Text("\(Int(context.state.glassesBattery))%")
                            .frame(width: 60, height: 30)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack{
                        if context.state.glassesCharging {
                            Image(systemName: "bolt.fill")
                        }
                        if context.state.connectionStatus == "Connected" {
                            ProgressView(value: Float(Int(context.state.glassesBattery)) / 100.0)
                                .accentColor(context.state.glassesBattery > 20 ? Color.green : Color.red)
                                .frame(width: 300)
                        } else {
                            Text("Glasses \(context.state.connectionStatus)")
                        }
                    }
                    .frame(height: 25)
                }
            } compactLeading: {
                Image(systemName: "eyeglasses")
                    .frame(width: 40)
            } compactTrailing: {
                Text("\(Int(context.state.glassesBattery))%")
                    .frame(width: 40)
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
    DisplayPlusWidgetAttributes.ContentState(glassesBattery: 75, caseBattery: 50, connectionStatus: "Connected", glassesCharging: true, caseCharging: false, displayOn: true)
    DisplayPlusWidgetAttributes.ContentState(glassesBattery: 75, caseBattery: 50, connectionStatus: "Disconnected", glassesCharging: false, caseCharging: false, displayOn: false)
    DisplayPlusWidgetAttributes.ContentState(glassesBattery: 100, caseBattery: 100, connectionStatus: "Connected", glassesCharging: false, caseCharging: true, displayOn: true)
    DisplayPlusWidgetAttributes.ContentState(glassesBattery: 0, caseBattery: 0, connectionStatus: "Connected", glassesCharging: true, caseCharging: true, displayOn: false)
    DisplayPlusWidgetAttributes.ContentState(glassesBattery: 15, caseBattery: 20, connectionStatus: "Connected", glassesCharging: false, caseCharging: true, displayOn: true)
}
