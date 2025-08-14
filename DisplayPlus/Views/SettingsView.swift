//
//  SettingsView.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 8/5/25.
//
import SwiftUI
import CoreLocation

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

struct SettingsView: View {
    let theme: ThemeColors
    
    @StateObject private var ble: G1BLEManager
    @StateObject private var info: InfoManager
    
    @AppStorage("autoOff", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var autoOff: Bool = false
    @AppStorage("headsUpEnabled", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var headsUp: Bool = false
    @AppStorage("useLocation", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var location: Bool = false
    @State private var showingLocationPicker = false
    @State private var fixedLocation: CLLocationCoordinate2D?
    
    // Add a debounce timer
    @State private var debounceTimer: Timer?
    
    init(bleIn: G1BLEManager, infoIn: InfoManager, themeIn: ThemeColors){
        _ble = StateObject(wrappedValue: bleIn)
        _info = StateObject(wrappedValue: infoIn)
        
        theme = themeIn
    }

    var body: some View {
        NavigationStack {
            ZStack{
                //backgroundGrid(themeIn: theme)
                (theme.darkMode ? theme.backgroundDark : theme.backgroundLight)
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
                        .settingsItem(themeIn: theme, items: (location ? 1 : 2), itemNum: 1)
                        
                        if !location {
                            HStack{
                                Text("Pick set location")
                                    .fixedSize(horizontal: true, vertical: false)
                                Spacer()
                                Button(action: {
                                    showingLocationPicker = true
                                }) {
                                    Text("Select")
                                }
                                .padding(4)
                                .mainButtonStyle(themeIn: theme)
                            }
                            .settingsItem(themeIn: theme, items: 2, itemNum: 2)
                            .offset(y: -8)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(location: $fixedLocation, theme: theme)
            }
        }
        .onChange(of: fixedLocation) {
            if let newLocation = fixedLocation {
                UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.set(newLocation.latitude, forKey: "fixedLatitude")
                UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.set(newLocation.longitude, forKey: "fixedLongitude")
                Task {
                    await info.updateWeather()
                }
            }
        }
        .task(id: location) {
            info.weather.toggleLocationUsage(on: location)
            await info.updateWeather()
        }
        .animation(.default, value: location)
    }
}

#Preview {
    SettingsView(bleIn: G1BLEManager(), infoIn: InfoManager(cal: CalendarManager(), music: AMMonitor(), weather: WeatherManager(), health: HealthInfoGetter()), themeIn: ThemeColors())
}
