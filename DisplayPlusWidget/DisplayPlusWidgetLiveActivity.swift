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
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct DisplayPlusWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DisplayPlusWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension DisplayPlusWidgetAttributes {
    fileprivate static var preview: DisplayPlusWidgetAttributes {
        DisplayPlusWidgetAttributes(name: "World")
    }
}

extension DisplayPlusWidgetAttributes.ContentState {
    fileprivate static var smiley: DisplayPlusWidgetAttributes.ContentState {
        DisplayPlusWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: DisplayPlusWidgetAttributes.ContentState {
         DisplayPlusWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: DisplayPlusWidgetAttributes.preview) {
   DisplayPlusWidgetLiveActivity()
} contentStates: {
    DisplayPlusWidgetAttributes.ContentState.smiley
    DisplayPlusWidgetAttributes.ContentState.starEyes
}
