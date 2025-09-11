import ActivityKit
import SwiftUI

struct DisplayPlusWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
    }

    // Fixed properties about your activity go here!
    var name: String
}
