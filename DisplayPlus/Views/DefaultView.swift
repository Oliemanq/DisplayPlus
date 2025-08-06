//
//  DefaultView.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 8/6/25.
//

import SwiftUI

struct DefaultView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @State var theme = ThemeColors()
    
    @StateObject private var info: InfoManager
    @StateObject private var ble: G1BLEManager
    @StateObject private var page: PageManager
    @StateObject private var bg: BackgroundTaskManager
    
    @AppStorage("currentPage", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var currentPage = "Default"
    @AppStorage("isPresentingScanView", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var isPresentingScanView: Bool = false
    
    @Namespace private var namespace
    
    init(){
        let infoInstance = InfoManager(cal: CalendarManager(), music: AMMonitor(), weather: WeatherManager(), health: HealthInfoGetter())
        let bleInstance = G1BLEManager()
        let pageInstance = PageManager(info: infoInstance)
        let bgInstance = BackgroundTaskManager(ble: bleInstance, info: infoInstance, page: pageInstance)
        
        _info = StateObject(wrappedValue: infoInstance)
        _ble = StateObject(wrappedValue: bleInstance)
        _page = StateObject(wrappedValue: pageInstance)
        _bg = StateObject(wrappedValue: bgInstance)
    }
    var body: some View {
        TabView {
            Tab("Home", systemImage: "eyeglasses") {
                ContentView(infoInstance: info, bleInstance: ble, bgInstance: bg, themeIn: theme)
            }
            Tab("Info", systemImage: "info.square") {
                InfoView(infoIn: info, bleIn: ble, themeIn: theme)
            }
            // Will re-add later, not really being used but will add more settings in the future
//            Tab("Settings", systemImage: "gear") {
//                SettingsView(bleIn: ble, themeIn: theme)
//            }
        }
        .safeAreaInset(edge: .bottom) {
            if #available (iOS 26, *){
                GlassEffectContainer(spacing: 10){
                    HStack(){
                        Menu("\(ble.connectionStatus)") {
                            if ble.connectionState == .connectedBoth{
                                Button("Disconnect"){
                                    Task{
                                        await bg.disconnectProper()
                                    }
                                }
                            }else{
                                Button("Start Scan"){
                                    ble.startScan()
                                    isPresentingScanView = true
                                }
                            }
                        }
                            .frame(width: 110)
                            .ToolBarBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                            .glassEffectID("toolbar", in: namespace)
                        
                        Menu("Pages \(Image(systemName: "folder.badge.gear"))") {
                            if currentPage == "Calendar"{
                                Text("Calendar")
                            }else{
                                Button("Calendar") {currentPage = "Calendar"}
                            }
                            if currentPage == "Music"{
                                Text("Music")
                            }else{
                                Button("Music") {currentPage = "Music"}
                            }
                            if currentPage == "Default"{
                                Text("Default")
                            }else{
                                Button("Default") {currentPage = "Default"}
                            }
                        }
                        .frame(width: 80)
                        .ToolBarBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                        .glassEffectID("toolbar", in: namespace)
                    }
                }
                .offset(y: -55)
                
            }else{
                HStack(spacing: 10){
                    Text("\(ble.connectionStatus)")
                        .frame(width: 200)
                        .ToolBarBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                    Menu("Pages \(Image(systemName: "folder.badge.gear"))") {
                        Button("\(Image(systemName: "house.fill")) Default") {currentPage = "Default"}
                        Button("\(Image(systemName: "music.note.list")) Music") {currentPage = "Music"}
                        Button("\(Image(systemName: "calendar")) Calendar") {currentPage = "Calendar"}
                    }
                    .frame(width: 120)
                    .ToolBarBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                }
                .offset(y: -50)
            }
        }
        .accentColor(!theme.darkMode ? theme.pri : theme.sec)
        .onAppear(){
            ble.connectionStatus = "Disconnected"
            ble.connectionState = .disconnected
            theme.darkMode = colorScheme == .dark
            
            info.update(updateWeatherBool: true) // Initial update
            bg.startTimer() // Start the background task timer
        }
        .onChange(of: colorScheme) { newScheme, _ in
            // Update the theme whenever the color scheme changes
            theme.darkMode = !(newScheme == .dark)
        } //Managing dark mode updates
    }
}

#Preview {
    DefaultView()
}
