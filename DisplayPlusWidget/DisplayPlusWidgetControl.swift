//
//  DisplayPlusWidgetControl.swift
//  DisplayPlusWidget
//
//  Created by Oliver Heisel on 9/10/25.
//

import AppIntents
import SwiftUI
import WidgetKit

// Shared identifier for this control kind (not actor-isolated)
private let DisplayPlusControlKind = "DisplayPlusWidgetControl"

// MARK: - Toggle intent used by the control
@available(iOS 18.0, *)
struct ToggleDisplayIntent: SetValueIntent {
    static var title: LocalizedStringResource = "Toggle Display"

    // The system sets this to the new state for us.
    @Parameter(title: "Display On")
    var value: Bool

    // Shared app group used by the app and widgets.
    static let suiteName = "group.Oliemanq.DisplayPlus"

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: Self.suiteName)
        defaults?.set(value, forKey: "displayOn")
        // Ask the system to refresh controls that depend on this value.
        ControlCenter.shared.reloadControls(ofKind: DisplayPlusControlKind)
        return .result()
    }
}

// MARK: - Value provider for the control's current state
@available(iOS 18.0, *)
struct DisplayPlusControlProvider: ControlValueProvider {
    // Shown in the controls gallery
    var previewValue: Bool { false }

    // Provide the current on/off state from shared storage
    func currentValue() async throws -> Bool {
        let defaults = UserDefaults(suiteName: ToggleDisplayIntent.suiteName)
        return defaults?.bool(forKey: "displayOn") ?? false
    }
}

// MARK: - Control widget definition
@available(iOS 18.0, *)
struct DisplayPlusWidgetControl: ControlWidget {
    static let kind = DisplayPlusControlKind

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: Self.kind,
            provider: DisplayPlusControlProvider()
        ) { isOn in
            ControlWidgetToggle(
                "Toggle display", 
                isOn: isOn,
                action: ToggleDisplayIntent(),
                valueLabel: { isOn in
                    Text(isOn ? "Display on" : "Display off")
                    Image(systemName: isOn ? "eyeglasses" : "eyeglasses.slash")
                }
            )
        }
        .displayName("Display Control")
        .description("Toggle the display on or off")
    }
}
