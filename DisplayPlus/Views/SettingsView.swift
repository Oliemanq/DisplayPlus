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
    @AppStorage("useLocation", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var location: Bool = false

    
    init(bleIn: G1BLEManager, themeIn: ThemeColors){
        _ble = StateObject(wrappedValue: bleIn)
        
        theme = themeIn
    }

    var body: some View {
        NavigationStack {
            ZStack{
                //backgroundGrid(themeIn: theme)
                (theme.darkMode ? theme.pri : theme.sec)
                    .ignoresSafeArea()
                
                ScrollView(.vertical) {
                    Spacer(minLength: 16)
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
                        
                        HStack {
                            Text("Use location for weather updates")
                                .fixedSize(horizontal: true, vertical: false)
                            Spacer()
                            Toggle("", isOn: $location)
                        }
                        .settingsItem(themeIn: theme)
                        //Will be added once I figure out how to pick location manually
//                        HStack{
//                            Text("Fixed location")
//                                .fixedSize(horizontal: true, vertical: false)
//                            Spacer()
//                            
//                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView(bleIn: G1BLEManager(), themeIn: ThemeColors())
}
