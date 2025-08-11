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
    @AppStorage("FTUEFinished", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var FTUEFinished: Bool = false //First Time User Experience checker
    @AppStorage("displayOn", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var displayOn = false
    
    
    @State private var FTUEConnection: Bool = false
    @State private var FTUEPages: Bool = false
    
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
            Tab("Settings", systemImage: "gear") {
                SettingsView(bleIn: ble, themeIn: theme)
            }
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
                                    withAnimation{
                                        FTUEConnection = true
                                    }
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
                                Button("\(Image(systemName: "calendar")) Calendar") {
                                    withAnimation {
                                        FTUEPages = true
                                    }
                                    currentPage = "Calendar"
                                }
                            }
                            if currentPage == "Music"{
                                Text("Music")
                            }else{
                                Button("\(Image(systemName: "music.note.list")) Music") {
                                    withAnimation {
                                        FTUEPages = true
                                    }
                                    currentPage = "Music"
                                }
                            }
                            if currentPage == "Default"{
                                Text("Default")
                            }else{
                                Button("\(Image(systemName: "house.fill")) Default") {
                                    withAnimation {
                                        FTUEPages = true
                                    }
                                    currentPage = "Default"
                                }
                            }
                        }
                        .frame(width: 80)
                        .ToolBarBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                        .glassEffectID("toolbar", in: namespace)
                        
                        Button("Force") {
                            bg.forceUpdateInfo = true
                        }
                        .frame(width: 70)
                        .ToolBarBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                        .glassEffectID("toolbar", in: namespace)
                    }
                    
                    if !FTUEFinished {
                        HStack(spacing: -3){
                            if !FTUEConnection {
                                VStack{
                                    Text("Click the 'Disconnected' button to pair glasses")
                                        .multilineTextAlignment(.center)
                                    Image(systemName: "arrow.down")
                                }
                                .offset(x: -55, y: -55)
                                .frame(width: 200)
                                .foregroundStyle(theme.darkMode ? theme.sec : theme.pri)
                            }
                            if !FTUEPages && ble.connectionState == .connectedBoth {
                                VStack{
                                    Text("Click 'Pages' to change the active screen on the glasses")
                                        .multilineTextAlignment(.center)
                                    Image(systemName: "arrow.down")
                                }
                                .foregroundStyle(theme.darkMode ? theme.sec : theme.pri)
                                .offset(x: 70, y: -55)
                                .frame(width: 225)
                            }
                        }
                    }
                }
                .offset(y: -55)
                
            }else{
                ZStack{
                    HStack(spacing: 10){
//                        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
//                            Button("Toggle FTUEFinished"){
//                                FTUEFinished.toggle()
//                            }
//                            .frame(width: 200)
//                            .ToolBarBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
//                        }
                        
                        Menu("\(ble.connectionStatus)") {
                            if ble.connectionState == .connectedBoth{
                                Button("Disconnect"){
                                    Task{
                                        await bg.disconnectProper()
                                    }
                                }
                            }else{
                                Button("Start Scan"){
                                    withAnimation{
                                        FTUEConnection = true
                                    }
                                    ble.startScan()
                                    isPresentingScanView = true
                                }
                            }
                        }
                        .frame(width: 110)
                        .ToolBarBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                        
                        Menu("Pages \(Image(systemName: "folder.badge.gear"))") {
                            Button("\(Image(systemName: "house.fill")) Default") {
                                withAnimation {
                                    FTUEPages = true
                                }
                                currentPage = "Default"
                            }
                            Button("\(Image(systemName: "music.note.list")) Music") {
                                withAnimation {
                                    FTUEPages = true
                                }
                                currentPage = "Music"
                            }
                            Button("\(Image(systemName: "calendar")) Calendar") {
                                withAnimation {
                                    FTUEPages = true
                                }
                                currentPage = "Calendar"
                            }
                        }
                        .frame(width: 120)
                        .ToolBarBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                    }
                    
                    if !FTUEFinished {
                        HStack(spacing: -3){
                            if !FTUEConnection {
                                VStack{
                                    Text("Click the 'Disconnected' button to pair glasses")
                                        .multilineTextAlignment(.center)
                                    Image(systemName: "arrow.down")
                                }
                                .offset(x: -75, y: -55)
                                .frame(width: 200)
                            }
                            if !FTUEPages && ble.connectionState == .connectedBoth {
                                VStack{
                                    Text("Click 'Pages' to change the active screen on the glasses")
                                        .multilineTextAlignment(.center)
                                    Image(systemName: "arrow.down")
                                }
                                .offset(x: 70, y: -55)
                                .frame(width: 225)
                            }
                        }
                    }
                }
                .offset(y: -50)

            }
        }
        .accentColor(!theme.darkMode ? theme.pri : theme.sec)
        .onAppear(){
            ble.connectionStatus = "Disconnected"
            ble.connectionState = .disconnected
            theme.darkMode = colorScheme == .dark
            
            bg.startTimer() // Start the background task timer
        }
        //Managing dark mode updates
        .onChange(of: colorScheme) { newScheme, _ in
            // Update the theme whenever the color scheme changes
            theme.darkMode = !(newScheme == .dark)
        }
        //Toggling main FTUE flag when completing final page
        .onChange(of: FTUEPages) { newScheme, _ in
            FTUEFinished = true
        }
        
        //Preventing delays from waiting for bg timer when changing pages
        .onChange(of: displayOn) {
            print("display \(displayOn ? "on" : "off")")
            if !displayOn {
                ble.sendBlank()
            } else {
                info.changed = true
            }
        }
    }
}

class ThemeColors: ObservableObject {
//    @Published var pri: Color = Color(red: 10/255, green: 25/255, blue: 10/255)
//    @Published var sec: Color = Color(red: 175/255, green: 220/255, blue: 175/255)
    @Published var pri: Color = Color(red: 15/255, green: 20/255, blue: 15/255)
    @Published var sec: Color = Color(red: 225/255, green: 255/255, blue: 225/255)
    @Published var accent: Color = Color(red: 175/255, green: 255/255, blue: 175/255)
    @Published var darkMode: Bool = false
}

#Preview {
    DefaultView()
}
