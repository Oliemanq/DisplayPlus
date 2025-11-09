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
    @StateObject private var pm: PageManager
    @StateObject private var la: LiveActivityManager
    @StateObject private var theme: ThemeColors
    
    @Environment(\.openURL) private var openURL
    
    @AppStorage("autoOff", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var autoOff: Bool = false
    @AppStorage("headsUpEnabled", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var headsUp: Bool = false
    @AppStorage("useLocation", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var location: Bool = false
    @AppStorage("fixedLatitude", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var fixedLatitude: Double = 0.0
    @AppStorage("fixedLongitude", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var fixedLongitude: Double = 0.0
    @AppStorage("currentCity", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var currentCity: String = ""
    @State private var showingLocationPicker = false
    @State private var showingHardwareInfo = false
    @State private var fixedLocation: CLLocationCoordinate2D?
    
    // Add a debounce timer
    @State private var debounceTimer: Timer?
    
    @State private var showingActivity = false
    @State private var showingSupportAlert = false
    
    // Display helper for fixed location city (uses published weather.currentCity)
    private var fixedCityDisplay: String {
        if fixedLatitude == 0 && fixedLongitude == 0 { return "Not set" }
        return currentCity
    }
    
    init(bleIn: G1BLEManager, pmIn: PageManager, liveIn: LiveActivityManager) {
        _ble = StateObject(wrappedValue: bleIn)
        _pm = StateObject(wrappedValue: pmIn)
        _la = StateObject(wrappedValue: liveIn)
        _theme = StateObject(wrappedValue: pmIn.theme)
    }
    
    var body: some View {
        GeometryReader { geo in
            NavigationStack {
                ZStack{
                    //backgroundGrid(themeIn: theme)
                    (theme.darkMode ? theme.backgroundDark : theme.backgroundLight)
                        .ignoresSafeArea()
                    ScrollView(.vertical) {
                        VStack(alignment: .leading){
                            Text("Glasses settings")
                                .pageHeaderText(themeIn: theme)
                                .padding(.leading, 1)
                            
                            //toggle display on timer
                            HStack{
                                Text("Display timer")
                                Spacer()
                                Text(autoOff ? "On" : "Off")
                                    .settingsButtonText(themeIn: theme)
                                Button {
                                    withAnimation{
                                        autoOff.toggle()
                                    }
                                } label: {
                                    Image(systemName: "10.arrow.trianglehead.counterclockwise")
                                        .symbolEffect(.rotate.byLayer, options: .speed(10), value: autoOff)
                                        .settingsButton(themeIn: theme)
                                }
                            }
                            .settingsItem(themeIn: theme)
                            
                            //use heads up for display toggle
                            HStack{
                                Text("Use HeadsUp gesture")
                                    .fixedSize(horizontal: true, vertical: false)
                                Spacer()
                                Text(headsUp ? "On" : "Off")
                                    .settingsButtonText(themeIn: theme)
                                Button {
                                    withAnimation{
                                        headsUp.toggle()
                                    }
                                } label: {
                                    Image(systemName:headsUp ? "arrow.up.and.person.rectangle.portrait" : "rectangle.portrait.slash")
                                        .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
                                        .settingsButton(themeIn: theme)
                                }
                                
                            }
                            .settingsItem(themeIn: theme)
                            HStack{
                                Image(systemName: "exclamationmark.square")
                                Text("Uses angle configuration set in the Even app")
                            }
                            .explanationText(themeIn: theme, width: geo.size.width * 0.9)
                            
                            if ble.connectionState == .connectedBoth || isNotPhone(){
                                HStack{
                                    Text("Hardware info")
                                    Spacer()
                                    NavigationLink {
                                        HardwareInfoView(theme: theme, ble: ble)
                                    }label: {
                                        Image(systemName: "info.circle")
                                            .settingsButton(themeIn: theme)
                                    }
                                }
                                .settingsItem(themeIn: theme)
                            }
                            
                            Text("Things settings")
                                .pageHeaderText(themeIn: theme)
                                .padding(.leading, 1)
                            HStack {
                                Text("Thing settings")
                                Spacer()
                                Text("|")
                                NavigationLink {
                                    ThingsSettingsMain(pm: pm)
                                } label: {
                                    Image(systemName: "arrow.up.right.circle")
                                }
                                .font(.system(size: 24))
                                .settingsButton(themeIn: theme)
                            }
                            .settingsItem(themeIn: theme)
                            
                            Text("Live Activity settings")
                                .pageHeaderText(themeIn: theme)
                                .padding(.leading, 1)
                            HStack {
                                Text("Live Activity \(showingActivity ? "" : "not ")running")
                                Spacer()
                                Button {
                                    if showingActivity {
                                        showingActivity = false
                                        la.stopActivity()
                                    } else {
                                        showingActivity = true
                                        la.startActivity()
                                    }
                                } label: {
                                    Image(systemName: showingActivity ? "stop.circle" : "play.square")
                                        .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .speed(5).nonRepeating))
                                        .settingsButton(themeIn: theme)
                                }
                            }
                            .settingsItem(themeIn: theme)
                            
                            
                        }
                    }
                    .padding(.top, -40)
                }
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
                    ToolbarItem(placement: .title) {
                        Text("Settings")
                            .pageHeaderText(themeIn: theme)
                    }
                }
                .alert("Support the developer!", isPresented: $showingSupportAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Thank you for considering supporting my work! If you'd like to contribute, please visit my GitHub page or my Discord for more info.")
                }
            }
            .tint(.primary)
            .onChange(of: fixedLocation) {
                if let newLocation = fixedLocation {
                    fixedLatitude = newLocation.latitude
                    fixedLongitude = newLocation.longitude
                    pm.updateCurrentPage()
                }
            }
            .animation(.default, value: location)
        }
    }
}

#Preview {
    SettingsView(bleIn: G1BLEManager(liveIn: LiveActivityManager()), pmIn: PageManager(currentPageIn: "DefaultAllThings", themeIn: ThemeColors()), liveIn: LiveActivityManager())
}


struct HardwareInfoView: View {
    @StateObject var theme: ThemeColors
    @StateObject var ble: G1BLEManager
    
    var body: some View{
        NavigationStack {
            ZStack{
                (theme.darkMode ? theme.backgroundDark : theme.backgroundLight)
                    .ignoresSafeArea()
                ScrollView(.vertical) {
                    VStack{
                        HStack{
                            Text("Hardware model:")
                            Spacer()
                            Text(ble.model ?? "Unknown model")
                        }
                        .settingsItem(themeIn: theme)
                        
                        HStack{
                            Text("Connection channel")
                            Spacer()
                            Text(ble.channel ?? "Unknown channel")
                        }
                        .settingsItem(themeIn: theme)
                        
                        HStack{
                            Text("Firmware version:")
                            Spacer()
                            Text(ble.firmwareVersion ?? "Unknown version")
                        }
                        .settingsItem(themeIn: theme)
                        
                        
                        HStack{
                            Text("Serial Number")
                            Spacer()
                            Text(ble.serialNumber ?? "Unknown serial")
                        }
                        .settingsItem(themeIn: theme)
                        
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .title) {
                    Text("Hardware Information")
                        .pageHeaderText(themeIn: theme)
                }
            }
        }
    }
}
