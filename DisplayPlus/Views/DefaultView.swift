//
//  DefaultView.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 8/6/25.
//

import SwiftUI
import WidgetKit

struct DefaultView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var theme = ThemeColors()
    
    @StateObject private var ble: G1BLEManager
    @StateObject private var pm: PageManager
    @StateObject private var bg: BackgroundTaskManager
    @StateObject private var la: LiveActivityManager
        
    @AppStorage("currentPage", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var currentPage = "Default"
    @AppStorage("pages", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var pagesString: String = "Default,Music"
    @AppStorage("connectionStatus", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var connectionStatus: String = "Disconnected"
    @AppStorage("isPresentingScanView", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var isPresentingScanView: Bool = false
    @AppStorage("FTUEFinished", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var FTUEFinished: Bool = false //First Time User Experience checker
    @AppStorage("displayOn", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var displayOn = false
    @AppStorage("glassesBattery", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var glassesBattery: Int = 0
    @AppStorage("glassesCharging", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var glassesCharging: Bool = false

    @State private var FTUEConnection: Bool = false
    
    @Namespace private var namespace
    
    init(){
        let laInstance = LiveActivityManager()
        _la = StateObject(wrappedValue: laInstance)

        let bleInstance = G1BLEManager(liveIn: laInstance)
        _ble = StateObject(wrappedValue: bleInstance)
        
        let pageInstance = PageManager(currentPageIn: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.string(forKey: "currentPage") ?? "Default")
        _pm = StateObject(wrappedValue: pageInstance)

        let bgInstance = BackgroundTaskManager(ble: bleInstance, pmIn: pageInstance)
        _bg = StateObject(wrappedValue: bgInstance)
    }
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "eyeglasses") {
                ContentView(pmIn: pm, bleIn: ble, bgIn: bg)
            }
            Tab("Page Editor", systemImage: "pencil.tip") {
                PageEditorView(pmIn: pm, themeIn: theme)
            }
            Tab("Settings", systemImage: "gear") {
                SettingsView(bleIn: ble, pmIn: pm, liveIn: la)
            }
        }
        .onAppear() {
            pm.resetPages()
        }
        .font(theme.bodyFont)
        .environmentObject(theme)
        .tint(theme.darkMode ? theme.accentLight : theme.accentDark)
        //Custon toolbar
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
                            ForEach(pagesString.split(separator: ",").map(String.init), id: \.self) { page in
                                Button(page) {
                                    withAnimation {
                                        FTUEFinished = true
                                    }
                                    currentPage = page
                                }
                                .disabled(currentPage == page)
                            }
                            
                        }
                        .frame(width: 80)
                        .ToolBarBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                        .glassEffectID("toolbar", in: namespace)
                        
//                        Button("Force") {
//                            bg.forceUpdateInfo = true
//                        }
//                        .frame(width: 70)
//                        .ToolBarBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
//                        .glassEffectID("toolbar", in: namespace)
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
                            if ble.connectionState == .connectedBoth {
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
                .font(theme.bodyFont)
                .offset(y: -55)
                
            }else{
                ZStack{
                    HStack(spacing: 10){
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
                                    FTUEFinished = true
                                }
                                currentPage = "Default"
                            }
                            .disabled(currentPage == "Default")

                            Button("\(Image(systemName: "music.note.list")) Music") {
                                withAnimation {
                                    FTUEFinished = true
                                }
                                currentPage = "Music"
                            }
                            .disabled(currentPage == "Music")

                            Button("\(Image(systemName: "calendar")) Calendar") {
                                withAnimation {
                                    FTUEFinished = true
                                }
                                currentPage = "Calendar"
                            }
                            .disabled(currentPage == "Calendar")

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
                            if ble.connectionState == .connectedBoth {
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
                .font(theme.bodyFont)
                .offset(y: -50)

            }
        }
        
        //Popover for devices page
        .popover(isPresented: $isPresentingScanView) {
            ZStack {
                theme.darkMode ? theme.pri.opacity(0.5).ignoresSafeArea() : theme.sec.opacity(0.75).ignoresSafeArea()
                
                VStack {
                    let pairs = Array(ble.discoveredPairs.values)
                    ForEach(pairs, id: \.channel) { pair in
                        let hasLeft = (pair.left != nil)
                        let hasRight = (pair.right != nil)
                        
                        VStack{
                            Text("Pair for channel \(pair.channel.map(String.init) ?? "unknown")")
                            HStack {
                                HStack{
                                    Image(systemName: hasLeft ? "checkmark.circle" : "x.circle")
                                    Text(hasLeft ? "Left found" : "No left")
                                }
                                HStack{
                                    Image(systemName: hasRight ? "checkmark.circle" : "x.circle")
                                    Text(hasRight ? "Right found" : "No right")
                                }
                            }
                            
                            if hasRight && hasLeft {
                                Button("Connect to pair") {
                                    ble.connectPair(pair: pair)
                                    withAnimation {
                                        isPresentingScanView = false
                                    }
                                }
                                .frame(width: 150, height: 50)
                                .mainButtonStyle(themeIn: theme)
                            }
                        }
                        .foregroundStyle(!theme.darkMode ? theme.pri : theme.sec)
                        .padding(.horizontal, 50)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(!theme.darkMode ? Color(theme.pri).opacity(0.05) : Color(theme.sec).opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(
                                            (!theme.darkMode ? theme.pri : theme.sec).opacity(0.3),
                                            lineWidth: 0.5
                                        )
                                )
                        )
                    }
                }
            }
        }
        
        //onAppear actions for entire app
        .onAppear(){
            ble.connectionStatus = "Disconnected"
            ble.connectionState = .disconnected
            theme.darkMode = colorScheme == .dark
                        
            ble.handlePairedDevices()
            
            bg.startTimer() // Start the background task timer
        }
        //Managing dark mode updates
        .onChange(of: colorScheme) { _, newScheme in
            // Update the theme whenever the color scheme changes (use newScheme, second param)
            theme.darkMode = (newScheme == .dark)
        }
        //Preventing delays from waiting for bg timer when changing pages
        .onChange(of: displayOn) {
            updateWidgets()
            
            if !displayOn {
                ble.sendBlank()
            }
        }
        .onChange(of: currentPage) {
            pm.updateCurrentPageValue(currentPage)
        }
        
        .onChange(of: ble.connectionState) { _, newValue in
            updateWidgets()
            
            if newValue == .connectedBoth {
                ble.fetchBrightness()
                ble.fetchSilentMode()
                ble.fetchGlassesBattery()
            }
        }
    }
    
    func updateWidgets(){
        WidgetCenter.shared.reloadAllTimelines()
        la.updateActivity()
    }
}

class ThemeColors: ObservableObject {
//    @Published var pri: Color = Color(red: 10/255, green: 25/255, blue: 10/255)
//    @Published var sec: Color = Color(red: 175/255, green: 220/255, blue: 175/255)
    @Published var pri: Color = Color(hue: 120/360, saturation: 0.03, brightness: 0.08) //Dark main
    @Published var sec: Color = Color(hue: 120/360, saturation: 0.03, brightness: 0.925) //Light main

    @Published var priLightAlt: Color = Color(hue: 120/360, saturation: 0.01, brightness: 0.125)
    @Published var secDarkAlt: Color = Color(hue: 120/360, saturation: 0.01, brightness: 0.95)

    @Published var accentLight: Color = Color(hue: 120/360, saturation: 0.6, brightness: 0.74) //Green accent light
    @Published var accentDark: Color = Color(hue: 120/360, saturation: 0.6, brightness: 0.75) //Green accent dark

    @Published var backgroundLight: Color = Color(hue: 120/360, saturation: 0.02, brightness: 0.98)
    @Published var backgroundDark: Color = Color(hue: 120/360, saturation: 0.0, brightness: 0.12)
    
    @Published var darkMode: Bool = false
    
    @Published var bodyFont: Font = .custom("TrebuchetMS",size: 16) //, weight: .light, design: .monospaced
    @Published var headerFont: Font = .system(size: 20, weight: .black, design: .monospaced)
}

#Preview {
    DefaultView()
}

func isSimulator() -> Bool {
    #if targetEnvironment(simulator)
    return true
    #else
    return false
    #endif
}
func isPreview() -> Bool {
    return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}
func isNotPhone() -> Bool {
    return isSimulator() || isPreview()
}

