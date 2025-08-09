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
    
    @AppStorage("autoOff", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var autoOff: Bool = false
    @AppStorage("headsUpEnabled", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var headsUp: Bool = false

    
    init(bleIn: G1BLEManager, themeIn: ThemeColors){
        _ble = StateObject(wrappedValue: bleIn)
        
        theme = themeIn
    }

    var body: some View {
        NavigationStack {
            ZStack{
                backgroundGrid(themeIn: theme)
                ScrollView(.vertical) {
                    Spacer(minLength: 60)
                    VStack{
                        HStack{
                            Text("Display timer")
                            Spacer()
                            Toggle("", isOn: $autoOff)
                                .disabled(headsUp)
                        }
                        .settingsItem(themeIn: theme)
                        
                        HStack{
                            Text("Use HeadsUp for dashboard")
                                .fixedSize(horizontal: true, vertical: false)
                            Spacer()
                            Toggle("", isOn: $headsUp)
                        }
                        .settingsItem(themeIn: theme)
                    }
                }
            }
        }
        
    }
}

#Preview {
    SettingsView(bleIn: G1BLEManager(), themeIn: ThemeColors())
}
