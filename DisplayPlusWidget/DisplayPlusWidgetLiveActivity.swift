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
    
    let bodyFont: Font = .custom("TrebuchetMS",size: 16) //, weight: .light, design: .monospaced
    
    var body: some View {
        // Lock screen/banner UI goes here
        VStack(spacing: 15) {
            if context.state.connectionStatus != "Connected" {
                HStack{
                    Text("Glasses \(context.state.connectionStatus)")
                        .font(bodyFont)
                        .padding(10)
                        .foregroundStyle(Color.green)
                        .background(
                            Capsule(style: .circular)
                                .foregroundStyle(Color.green.opacity(0.3))
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
                        .font(bodyFont)
                        .frame(width: 60)
                        .contentTransition(.numericText(value: Double(context.state.glassesBattery)))
                }
                .accentColor(context.state.glassesBattery > 20 ? Color.green : Color.red)
                
                HStack{
                    Text("Glasses \(context.state.connectionStatus)")
                        .font(bodyFont)
                        .padding(10)
                        .foregroundStyle(Color.green)
                        .background(
                            Capsule(style: .circular)
                                .foregroundStyle(Color.green.opacity(0.2))
                        )
                    Spacer()
                    Button(intent: PageIntents.NextPage()) {
                        Image(systemName: "book.pages")
                            .symbolEffect(.bounce.down.byLayer, options: .nonRepeating)
                    }
                    .accentColor(Color.clear)
                    .padding(5)
                    .foregroundStyle(Color.green)
                    .background(
                        Capsule(style: .circular)
                            .foregroundStyle(Color.green.opacity(0.2))
                    )
                    
                    Button(intent: DisplayIntents.ToggleDisplay()) {
                        Image(systemName: context.state.displayOn ? "lightswitch.on" : "lightswitch.off.fill")
                            .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
                    }
                    .accentColor(Color.clear)
                    .padding(5)
                    .foregroundStyle(Color.green)
                    .background(
                        Capsule(style: .circular)
                            .foregroundStyle(Color.green.opacity(0.2))
                    )
                }
                
            }
        }
        .padding(15)
    }
}

struct DisplayPlusWidgetLiveActivity: Widget {
    let kind = "DisplayPlusWidgetLiveActivity"
    
    let bodyFont: Font = .custom("TrebuchetMS",size: 14) //, weight: .light, design: .monospaced
    
    @Environment(\.colorScheme) var colorScheme
    var darkMode: Bool {
        colorScheme == .dark
    }
    
    let frameWidth: CGFloat = 40
    let frameHeight: CGFloat = 30
    let padding: CGFloat = 5
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DisplayPlusWidgetAttributes.self) { context in
            LiveActivityView(context: context)
                .activitySystemActionForegroundColor(Color.green)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    if context.state.connectionStatus == "Connected" {
                        Image(systemName: "eyeglasses")
                            .font(.system(size: 20))
                            .frame(width: frameWidth*1.5, height: frameHeight)
                            .padding(padding)
                            .foregroundStyle(context.state.glassesBattery > 20 ? Color.green : Color.red)
                            .background(
                                Capsule(style: .circular)
                                    .foregroundStyle(context.state.glassesBattery > 20 ? Color.green : Color.red).opacity(0.2)
                            )
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.connectionStatus == "Connected" {
                        Text("\(Int(context.state.glassesBattery))%")
                            .font(.custom("TrebuchetMS", size: 18))
                            .frame(width: frameWidth*1.5, height: frameHeight)
                            .padding(padding)
                            .foregroundStyle(context.state.glassesBattery > 20 ? Color.green : Color.red)
                            .background(
                                Capsule(style: .circular)
                                    .foregroundStyle(context.state.glassesBattery > 20 ? Color.green : Color.red).opacity(0.2)
                            )
                            .padding(.bottom, 2)
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
                                .font(bodyFont)
                        }
                    }
                    .frame(height: 25)
                }
            } compactLeading: {
                Image(systemName: context.state.connectionStatus == "Connected" ? "eyeglasses" : "nosign")
                    .frame(width: frameWidth, height: frameHeight/2)
                    .padding(padding)
                    .foregroundStyle(context.state.glassesBattery > 20 ? Color.green : Color.red)
                    .background(
                        Capsule(style: .circular)
                            .foregroundStyle(context.state.glassesBattery > 20 ? Color.green : Color.red).opacity(0.2)
                    )

            } compactTrailing: {
                Text("\(context.state.connectionStatus == "Connected" ? String(Int(context.state.glassesBattery)) : "--")%")
                    .font(bodyFont)
                    .frame(width: frameWidth, height: frameHeight/2)
                    .padding(padding)
                    .foregroundStyle(context.state.glassesBattery > 20 ? Color.green : Color.red)
                    .background(
                        Capsule(style: .circular)
                            .foregroundStyle(context.state.glassesBattery > 20 ? Color.green : Color.red).opacity(0.2)
                    )

            } minimal: {
                if context.state.connectionStatus == "Connected" {
                    Text("\(Int(context.state.glassesBattery))%")
                        .font(.custom("TrebuchetMS", size: context.state.glassesBattery == 100 ? 11 : 14))
                        .frame(width: frameWidth, height: frameHeight)
                        .padding(padding*100)
                        .foregroundStyle(context.state.glassesBattery > 20 ? Color.green : Color.red)
                        .background(
                            Capsule(style: .circular)
                                .foregroundStyle(context.state.glassesBattery > 20 ? Color.green : Color.red).opacity(0.2)
                        )

                } else {
                    Image(systemName: "nosign")
                        .frame(width: frameWidth, height: frameHeight)
                        .padding(padding*10)
                        .foregroundStyle(Color.green)
                        .background(
                            Capsule(style: .circular)
                                .foregroundStyle(Color.green.opacity(0.2))
                        )
                }
            }
            .keylineTint(context.state.glassesBattery > 20 ? Color.green : Color.red)
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
    DisplayPlusWidgetAttributes.ContentState(glassesBattery: 85, caseBattery: 50, connectionStatus: "Connected", glassesCharging: true, caseCharging: false, displayOn: true)
    DisplayPlusWidgetAttributes.ContentState(glassesBattery: 75, caseBattery: 50, connectionStatus: "Disconnected", glassesCharging: false, caseCharging: false, displayOn: false)
    DisplayPlusWidgetAttributes.ContentState(glassesBattery: 100, caseBattery: 100, connectionStatus: "Connected", glassesCharging: false, caseCharging: true, displayOn: true)
    DisplayPlusWidgetAttributes.ContentState(glassesBattery: 0, caseBattery: 0, connectionStatus: "Connected", glassesCharging: true, caseCharging: true, displayOn: false)
    DisplayPlusWidgetAttributes.ContentState(glassesBattery: 15, caseBattery: 20, connectionStatus: "Connected", glassesCharging: false, caseCharging: true, displayOn: true)
    DisplayPlusWidgetAttributes.ContentState(glassesBattery: 20, caseBattery: 100, connectionStatus: "Connected", glassesCharging: true, caseCharging: true, displayOn: true)
}

