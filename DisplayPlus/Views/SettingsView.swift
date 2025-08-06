//
//  SettingsView.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 8/5/25.
//
import SwiftUI

struct SettingsView: View {
    let theme: ThemeColors
    
    @StateObject private var ble: G1BLEManager
    
    @AppStorage("currentPage", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var currentPage = "Default"
    @AppStorage("displayOn", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var displayOn = false
    @AppStorage("autoOff", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var autoOff: Bool = false
    @AppStorage("connectionStatus", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var connectionStatus: String = "Disconnected"
    @AppStorage("silentMode", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var silentMode: Bool = false
    
    init(bleIn: G1BLEManager, themeIn: ThemeColors){
        _ble = StateObject(wrappedValue: bleIn)
        
        theme = themeIn
    }
    func buttonObjects() -> [AnyView] {
        return [
            AnyView(Button ("Auto shut off: \(autoOff ? "on" : "off")"){
                self.autoOff.toggle()
            }
            .frame(width: 150, height: 50)
            .mainButtonStyle(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode))
        ]
    }

    var body: some View {
        let buttons: [AnyView] = buttonObjects()

        NavigationStack {
            VStack {
                ForEach(buttons.indices, id: \.self) { index in
                    buttons[index]
                }
            }
            
        }
    }
}

#Preview {
    SettingsView(bleIn: G1BLEManager(), themeIn: ThemeColors())
}
