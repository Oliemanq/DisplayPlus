import Foundation
import ActivityKit

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
