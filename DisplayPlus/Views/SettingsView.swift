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
    @StateObject private var ble: G1BLEManager
    @StateObject private var info: InfoManager
    @EnvironmentObject var theme: ThemeColors
    @StateObject private var la: LiveActivityManager
    @Environment(\.openURL) private var openURL
    
    @AppStorage("autoOff", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var autoOff: Bool = false
    @AppStorage("headsUpEnabled", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var headsUp: Bool = false
    @AppStorage("useLocation", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var location: Bool = false
    @AppStorage("fixedLatitude", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var fixedLatitude: Double = 0.0
    @AppStorage("fixedLongitude", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var fixedLongitude: Double = 0.0
    @State private var showingLocationPicker = false
    @State private var fixedLocation: CLLocationCoordinate2D?
    
    // Add a debounce timer
    @State private var debounceTimer: Timer?
    
    @State private var showingActivity = false
    @State private var showingSupportAlert = false
    
    // Display helper for fixed location city (uses published weather.currentCity)
    private var fixedCityDisplay: String {
        if fixedLatitude == 0 && fixedLongitude == 0 { return "Not set" }
        return info.getCity()
    }
    
    init(bleIn: G1BLEManager, infoIn: InfoManager, liveIn: LiveActivityManager){
        _ble = StateObject(wrappedValue: bleIn)
        _info = StateObject(wrappedValue: infoIn)
        _la = StateObject(wrappedValue: liveIn)
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
                        //toggle display on timer
                        HStack{
                            Text("Display timer")
                            Spacer()
                            Toggle("", isOn: $autoOff)
                                .disabled(headsUp)
                        }
                        .settingsItem(themeIn: theme)
                        
                        //use heads up for display toggle
                        HStack{
                            Text("Use HeadsUp for dashboard")
                                .fixedSize(horizontal: true, vertical: false)
                            Spacer()
                            Toggle("", isOn: $headsUp)
                        }
                        .settingsItem(themeIn: theme)
                        
                        //use user location for weather updates
                        HStack {
                            Text("Use location for weather updates")
                                .fixedSize(horizontal: true, vertical: false)
                            Spacer()
                            Toggle("", isOn: $location)
                        }
                        .settingsItem(themeIn: theme, items: (location ? 1 : 3), itemNum: 1)
                        
                        //fixed location for weather updates
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
                                .padding(6)
                                .mainButtonStyle(themeIn: theme)
                            }
                            .settingsItem(themeIn: theme, items: 3, itemNum: 2)
                            .offset(y: -8)
                            HStack {
                                Text("Current location: \(fixedCityDisplay)") // Use cached/published city
                                    .ContextualBG(themeIn: theme)
                            }
                            .settingsItem(themeIn: theme, items: 3, itemNum: 3)
                            .offset(y: -16)
                        }
                        
                        HStack {
                            Text("Live Activity \(showingActivity ? "" : "not ")running")
                            Spacer()
                            Button("\(Image(systemName: showingActivity ? "stop.circle" : "play.circle"))") {
                                if showingActivity {
                                    showingActivity = false
                                    la.stopActivity()
                                } else {
                                    showingActivity = true
                                    la.startActivity()
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 24)
                            .font(.system(size: 24))
                            .mainButtonStyle(themeIn: theme)
                                
                        }
                        .settingsItem(themeIn: theme)
                        
                    }
                }
            }
            
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            openURL(URL(string: "https://github.com/Oliemanq/DisplayPlus")!)
                        } label: {
                            Label("GitHub Repo", systemImage: "archivebox")
                        }
                        .tint(.primary)
                        Button {
                            openURL(URL(string: "https://discord.gg/AH2MxHSepn")!)
                        } label: {
                            Label("Discord Server", systemImage: "bubble.left.and.bubble.right")
                        }
                        .tint(.primary)
                        Button {
                            showingSupportAlert = true
                        } label: {
                            Label("Support the developer!", systemImage: "heart")
                        }
                        .tint(.primary)
                        Divider()
                        Button {
                            openURL(URL(string: "https://github.com/Oliemanq/DisplayPlus/issues")!)
                        } label: {
                            Label("Report an Issue", systemImage: "exclamationmark.bubble")
                        }
                        .tint(.primary)
                    } label: {
                        HStack{
                            Text("Links")
                            Image(systemName: "link.circle")
                                .symbolRenderingMode(.monochrome)
                        }
                        .foregroundStyle(.primary)
                    }
                    .tint(.primary)
                }
            }
            .alert("Support the developer!", isPresented: $showingSupportAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Thank you for considering supporting my work! If you'd like to contribute, please visit my GitHub page or my Discord for more info.")
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(location: $fixedLocation, theme: theme)
            }
        }
        .tint(.primary)
        .onChange(of: fixedLocation) {
            if let newLocation = fixedLocation {
                fixedLatitude = newLocation.latitude
                fixedLongitude = newLocation.longitude
                info.updateWeather() // This will trigger reverse geocode via WeatherManager
            }
        }
        .task(id: location) {
            info.toggleLocation()
            info.updateWeather()
        }
        .animation(.default, value: location)
    }
}

#Preview {
    SettingsView(bleIn: G1BLEManager(liveIn: LiveActivityManager()), infoIn: InfoManager(things: [
        TimeThing(name: "timeHeader"),
        DateThing(name: "dateHeader"),
        BatteryThing(name: "batteryHeader"),
        WeatherThing(name: "weatherHeader"),
        CalendarThing(name: "calendarHeader"),
        MusicThing(name: "musicHeader")
    ]), liveIn: LiveActivityManager()) //, health: HealthInfoGetter()
        .environmentObject(ThemeColors())

}
