//
//  UIElementFunctions.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 7/16/25.
//

import SwiftUI
import Foundation

class MainUIBlocks{
    var darkMode: Bool
    let primaryColor: Color
    let secondaryColor: Color
    let namespace: Namespace.ID
    
    private var theme = ThemeColors()
    
    @AppStorage("currentPage", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var currentPage = "Default"
    @AppStorage("displayOn", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var displayOn = false
    @AppStorage("autoOff", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var autoOff: Bool = false
    @AppStorage("connectionStatus", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var connectionStatus: String = "Disconnected"
    @AppStorage("showingScanPopover", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var showingScanPopover: Bool = false
    
    @State private var progressBar: Double = 0.0
    
    let formatter = DateFormatter()
    
    var floatingButtonItems: [FloatingButtonItem] = []
    
    var info: InfoManager
    var ble: G1BLEManager
    var formatting: FormattingManager
    var bg: BackgroundTaskManager
    
    init(pri: Color, sec: Color, darkMode: Bool, namespace: Namespace.ID) {
        let infoInstance = InfoManager(cal: CalendarManager(), music: AMMonitor(), weather: WeatherManager(), health: HealthInfoGetter())
        let bleInstance = G1BLEManager()
        let fmInstance = FormattingManager(info: infoInstance)
        let bgmInstance = BackgroundTaskManager(ble: bleInstance, info: infoInstance, formatting: fmInstance)

        info = infoInstance
        ble = bleInstance
        formatting = fmInstance
        bg = bgmInstance
        
        self.primaryColor = pri
        self.secondaryColor = sec
        self.darkMode = darkMode
        self.namespace = namespace
        
        self.floatingButtonItems = [
            .init(iconSystemName: "clock", extraText: "Default screen", action: {
                print("Default button pushed")
                self.currentPage = "Default"
            }),
            .init(iconSystemName: "music.note.list", extraText: "Music screen", action: {
                print("Music button pushed")
                self.currentPage = "Music"
            }),
            .init(iconSystemName: "calendar", extraText: "Calendar screen", action: {
                print("Calendar button pushed")
                self.currentPage = "Calendar"
            })
        ] // Floating button init
    }
    
    func headerContent() -> some View {
        if #available(iOS 26, *) {
            return GlassEffectContainer(spacing: 20){
                HStack{ 
                    Spacer()
                    VStack {
                        //Display glasses battery level if it has been updated
                        if ble.glassesBatteryAvg != 0.0 {
                            Text("\(info.time)")
                        }else{
                            Text("\(info.time)")
                        }
                        
                        HStack {
                            Text(info.getTodayDate())
                        }
                    }
                    .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                    .padding(.horizontal, ble.connectionState == .connectedBoth ? 0 : 64)
                    .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                    .glassEffectID("header", in: namespace)
                    
                    
                    Spacer()
                    
                    if ble.connectionState == .connectedBoth {
                        Spacer()
                        
                        VStack{
                            Text("Glasses - \(Int(ble.glassesBatteryAvg))%")
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            
                            Text("Case - \(Int(ble.caseBatteryLevel))%")
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                        }
                        .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                        .glassEffectID("header", in: namespace)
                        
                        Spacer()
                    }
                }
            }
        }else{
            return HStack{
                Spacer()
                VStack {
                    //Display glasses battery level if it has been updated
                    if ble.glassesBatteryAvg != 0.0 {
                        Text("\(info.time)")
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                    }else{
                        Text("\(info.time)")
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                    }
                    
                    HStack {
                        Text(info.getTodayDate())
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                    }
                    .padding(.horizontal, ble.connectionState == .connectedBoth ? 0 : 64)
                    .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                    
                    
                    Spacer()
                    
                    if ble.connectionState == .connectedBoth {
                        Spacer()
                        
                        VStack{
                            Text("Glasses - \(Int(ble.glassesBatteryAvg))%")
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            
                            Text("Case - \(Int(ble.caseBatteryLevel))%")
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                        }
                        .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                        
                        Spacer()
                    }
                }
            }
        }
        
    }
    
    func songInfo() -> some View {
        return VStack{
            if info.currentSong.title == "" {
                HStack{
                    Spacer()
                    Text("No music playing")
                        .font(.headline)
                        .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                        .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                    
                    Spacer()
                }
                .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
            }else{
                // Current playing music
                HStack{
                    Spacer()
                    VStack(alignment: .center) {
                        // Use infoManager.currentSong properties
                        Text(info.currentSong.title)
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            .font(.headline)
                        Text("\(info.currentSong.album) - \(info.currentSong.artist)")
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                        
                        let formattedCurrentTime = Duration.seconds(info.currentSong.currentTime).formatted(.time(pattern: .minuteSecond))
                        let formattedduration = Duration.seconds(info.currentSong.duration).formatted(.time(pattern: .minuteSecond))
                        
                        Text("\(formattedCurrentTime) \(formattedduration)")
                            .font(.caption)
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                    }
                    .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                    Spacer()
                }.glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
            }
        }
                            
    }
    
    func calendarInfo() -> some View {
        return HStack{
            if info.eventsFormatted.isEmpty {
                HStack{
                    Spacer()
                    Text("No events today")
                        .font(.headline)
                        .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                        .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                    Spacer()
                }
                .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
            }else{
                HStack{
                    VStack{
                        Text("Calendar events: ")
                            .font(.headline)
                            .padding(.horizontal, 8)
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                        
                        // Use infoManager.eventsFormatted for ForEach
                        ForEach(info.eventsFormatted) { event in
                            HStack{
                                VStack(alignment: .leading) {
                                    Text(" - \(event.titleLine)")
                                        .font(.caption)
                                    
                                    Text("    \(event.subtitleLine)")
                                        .font(.footnote)
                                    
                                }.padding(.horizontal, 8)
                            }
                            .glassListBG(pri: self.primaryColor, sec: self.secondaryColor, darkMode: self.darkMode)
                        }
                        
                        
                    }
                    Spacer()
                }
                .mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)

            }
            Spacer()
        }
    }
    
    func buttons() -> some View {
        if #available(iOS 26, *){
            return VStack {
                HStack{
                    GlassEffectContainer(spacing: 10.0){
                        ScrollView(.horizontal) {
                            
                            HStack{
                                Spacer()
                                if self.ble.connectionState != .connectedBoth{
                                    Button("Start scan"){
                                        self.ble.startScan()
                                        self.showingScanPopover = true
                                    }
                                    .frame(width: 100, height: 50)
                                    .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                }
                                
                                
                                
                                if self.ble.connectionState == .connectedBoth{
                                    Button("Disconnect"){
                                        Task{
                                            await self.bg.disconnectProper()
                                        }
                                    }
                                    .frame(width: 120, height: 50)
                                    .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                    
                                    
                                    //Display toggle button
                                    Button(self.displayOn ? "Turn display off" : "Turn display on"){
                                        self.displayOn.toggle()
                                        self.ble.sendBlank()
                                    }
                                    .frame(width: 150, height: 50)
                                    .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                    
                                    
                                    //Auto off button
                                    Button ("Auto shut off: \(self.autoOff ? "on" : "off")"){
                                        self.autoOff.toggle()
                                    }
                                    .frame(width: 150, height: 50)
                                    .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                    
                                    /*
                                     Hiding buttons for testflight build
                                     
                                     Button("Low battery disconnect"){
                                         Task{
                                             await bgManager.lowBatteryDisconnect()
                                         }
                                     }
                                     .frame(width: 100, height: 50)
                                     .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                     
                                     Button("Fetch glasses battery level"){
                                        bleManager.fetchGlassesBattery()
                                     }
                                     .frame(width: 250, height: 50)
                                     .background((!darkMode ? primaryColor : secondaryColor))
                                     .foregroundColor(darkMode ? primaryColor : secondaryColor)
                                     .buttonStyle(.borderless)
                                     .clipShape(RoundedRectangle(cornerRadius: 12))
                                     
                                     Button("Fetch silent mode status"){
                                        bleManager.fetchSilentMode()
                                     }
                                     .frame(width: 250, height: 50)
                                     .background((!darkMode ? primaryColor : secondaryColor))
                                     .foregroundColor(darkMode ? primaryColor : secondaryColor)
                                     .buttonStyle(.borderless)
                                     .clipShape(RoundedRectangle(cornerRadius: 12))
                                     */
                                }
                                Spacer()
                                
                            }
                            
                        }
                        .scrollIndicators(.hidden)
                    }
                }.glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)

            }
            .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
        }else{
            return HStack{
                VStack{
                    ScrollView(.horizontal) {
                        HStack{
                            if self.ble.connectionState != .connectedBoth{
                                Button("Start scan"){
                                    self.ble.startScan()
                                    self.showingScanPopover = true
                                }
                                .frame(width: 100, height: 50)
                                .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                            }
                            
                            
                            
                            if self.ble.connectionState == .connectedBoth{
                                Button("Disconnect"){
                                    Task{
                                        await self.bg.disconnectProper()
                                    }
                                }
                                .frame(width: 120, height: 50)
                                .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                
                                
                                //Display toggle button
                                Button(self.displayOn ? "Turn display off" : "Turn display on"){
                                    self.displayOn.toggle()
                                    self.ble.sendBlank()
                                }
                                .frame(width: 150, height: 50)
                                .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                
                                
                                //Auto off button
                                Button ("Auto shut off: \(self.autoOff ? "on" : "off")"){
                                    self.autoOff.toggle()
                                }
                                .frame(width: 150, height: 50)
                                .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                            }
                        }
                    }
                }
                .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
            }
            .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
        }
    }
    
    func glassesMirror() -> some View {
        return VStack{
            if displayOn && ble.connectionState == .connectedBoth {
                //Glasses mirror on app UI
                VStack{
                    Text(bg.textOutput)
                        .font(.system(size: 11))
                    
                }
                .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
            }
        }
    }
    
    func connectionDisplay() -> some View {
        return HStack{
            Spacer()
            Text("Connection status: \(ble.connectionStatus)")
                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                .font(.headline)
                .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)

            Spacer()
        }
        .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
    }
    
    func floatingButtons() -> some View {
        return FloatingButtons(items: floatingButtonItems)
            .environmentObject(theme)
    }
    
    func scanDevicesPopup() -> some View {
        return ZStack {
            (self.darkMode ? self.primaryColor.opacity(0.5) : self.secondaryColor.opacity(0.75))
                .ignoresSafeArea()
            VStack {
                ForEach(Array(ble.discoveredPairs).indices, id: \.self) { index in
                    let pair = Array(self.ble.discoveredPairs.values)[index]
                    VStack{
                        Text("Pair for channel \(pair.channel.map(String.init) ?? "unknown")")
                            .foregroundStyle(!self.darkMode ? self.primaryColor : self.secondaryColor)
                        HStack {
                            if pair.left != nil {
                                HStack{
                                    Image(systemName: "checkmark.circle")
                                        .foregroundStyle(!self.darkMode ? self.primaryColor : self.secondaryColor)
                                    Text("Left found")
                                        .foregroundStyle(!self.darkMode ? self.primaryColor : self.secondaryColor)
                                }
                            } else {
                                HStack {
                                    Image(systemName: "x.circle")
                                        .foregroundStyle(!self.darkMode ? self.primaryColor : self.secondaryColor)
                                    Text("No left")
                                        .foregroundStyle(!self.darkMode ? self.primaryColor : self.secondaryColor)
                                }
                            }
                            if pair.right != nil {
                                HStack{
                                    Image(systemName: "checkmark.circle")
                                        .foregroundStyle(!self.darkMode ? self.primaryColor : self.secondaryColor)
                                    Text("Right found")
                                        .foregroundStyle(!self.darkMode ? self.primaryColor : self.secondaryColor)
                                }
                            } else {
                                HStack {
                                    Image(systemName: "x.circle")
                                        .foregroundStyle(!self.darkMode ? self.primaryColor : self.secondaryColor)
                                    Text("No right")
                                        .foregroundStyle(!self.darkMode ? self.primaryColor : self.secondaryColor)
                                }
                            }
                        }
                        if pair.left != nil && pair.right != nil {
                            withAnimation{
                                Button("Connect to pair"){
                                    self.ble.connectPair(pair: pair)
                                    self.showingScanPopover = false
                                }
                                .frame(width: 150, height: 50)
                                .mainButtonStyle(pri: self.primaryColor, sec: self.secondaryColor, darkMode: self.darkMode)
                            }
                        }
                    }
                    .padding(.horizontal, 50)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                        .fill(!self.darkMode ? Color(self.primaryColor).opacity(0.05) : Color(self.secondaryColor).opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    (!self.darkMode ? self.primaryColor : self.secondaryColor).opacity(0.3),
                                    lineWidth: 0.5
                                )
                        )
                    )
                }
            }
        }
    }
    
    struct backgroundGrid: View {
        // State variables to hold the customizable properties of the grid.
        
        @State var primaryColor: Color
        @State var secondaryColor: Color
        
        @Environment(\.colorScheme) private var colorScheme
        var darkMode: Bool { colorScheme == .dark }
        
        var body: some View {
            @State var lineColor: Color = darkMode ? primaryColor : secondaryColor
            @State var lineWidth: CGFloat = 1
            @State var spacing: CGFloat = 10
            
            ZStack{
                if darkMode {
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: secondaryColor, location: 0.0), // Lighter color at top-left
                            .init(color: primaryColor, location: 0.5),  // Transition to darker
                            .init(color: primaryColor, location: 1.0)   // Darker color for the rest
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: primaryColor, location: 0.0), // Darker color at top-left
                            .init(color: secondaryColor, location: 0.5),  // Transition to lighter
                            .init(color: secondaryColor, location: 1.0)   // Lighter color for the rest
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                
                Grid(spacing: spacing)
                    .stroke(lineColor, lineWidth: lineWidth)
                    .offset(x: -300, y: 25)
                    .rotationEffect(.degrees(45))
                
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: darkMode ? primaryColor.opacity(0.95) : secondaryColor.opacity(0.95), location: 0.05),
                        .init(color: Color.clear, location: 0.1)
                        ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .edgesIgnoringSafeArea(.all)
        }
        
    }
}

extension View {
    func mainUIMods(pri: Color, sec: Color, darkMode: Bool) -> some View {
        self
            .foregroundStyle(!darkMode ? pri : sec)
            .glassListBG(pri: pri, sec: sec, darkMode: darkMode)
    }
}
