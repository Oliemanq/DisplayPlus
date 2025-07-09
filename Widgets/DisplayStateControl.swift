//
//  DisplayStateControl.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 7/9/25.
//
import WidgetKit
import SwiftUI
import Foundation


struct DisplayControlWidget: ControlWidget {
    static let kind: String = "Oliemanq.DisplayPlus.Widgets"

    // Use @AppStorage to get the current display state for the toggle
    @AppStorage("displayOn", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var displayOn: Bool = false

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            // This toggle links the UI to your new SetValueIntent
            ControlWidgetToggle(
                "Toggle display",
                isOn: displayOn, // The initial state of the toggle
                action: DisplayIntents.SetDisplayStateIntent() // The intent to perform
            ) { state in
                // This closure is called when the state changes.
                // You can change the icon based on the 'state' (isOn)
                Label("Toggle heads-up display", systemImage: state ? "eyeglasses" : "eyeglasses.slash")
            }
        }
        .displayName("Toggle Display")
        .description("Turn the heads-up display on or off.")
    }
}
