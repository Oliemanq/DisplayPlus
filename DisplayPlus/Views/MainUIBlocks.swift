//
//  UIElementFunctions.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 7/16/25.
//

import SwiftUI
import Foundation

class MainUIBlocks: ObservableObject {
    var primaryColor: Color { theme.primaryColor }
    var secondaryColor: Color { theme.secondaryColor }
    var darkMode: Bool { theme.darkMode }
    let namespace: Namespace.ID
    
    let theme = ThemeColors()
    
    @AppStorage("currentPage", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var currentPage = "Default"
    @AppStorage("displayOn", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var displayOn = false
    @AppStorage("autoOff", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var autoOff: Bool = false
    @AppStorage("connectionStatus", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var connectionStatus: String = "Disconnected"
    @AppStorage("showingScanPopover", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var showingScanPopover: Bool = false
    @AppStorage("silentMode", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var silentMode: Bool = false
    
    @State private var progressBar: Double = 0.0
    
    let formatter = DateFormatter()
    
    var floatingButtonItems: [FloatingButtonItem] = []
    
    let info: InfoManager
    let ble: G1BLEManager
    let page: PageManager
    let bg: BackgroundTaskManager
    
    //Holding button vars
    @Published var holdingSilentButton: Bool = false
    
    init(namespace: Namespace.ID, infoManager: InfoManager, bleManager: G1BLEManager, pageManager: PageManager, bgManager: BackgroundTaskManager) {
        self.namespace = namespace
        
        self.info = infoManager
        self.ble = bleManager
        self.page = pageManager
        self.bg = bgManager
        
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
    
    //MARK: - Header
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
            .mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
            .padding(.top, 40) //Giving the entire scrollview some extra padding at the top
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
                    .mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                }
                
                Spacer()
                
                if ble.connectionState == .connectedBoth {
                    VStack {
                        VStack{
                            Text("Glasses - \(Int(ble.glassesBatteryAvg))%")
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            
                            Text("Case - \(Int(ble.caseBatteryLevel))%")
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                        }
                        .mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                    }
                    .mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
                    
                    Spacer()
                }
            }
            .mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
            
        }
    }
    
    //MARK: - Song info
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
                .mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
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
                }
                .mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
                
            }
        }
        
    }
    
    //MARK: - Calendar info
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
            }else{
                HStack{
                    VStack{
                        Text("Calendar events (\(info.numOfEvents)): ")
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
            }
            Spacer()
        }.mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
        
    }
    
    //MARK: - Buttons
    func buttons(isPresentingButtons: Binding<Bool>) -> some View {
        let buttonObjects = buttonObjects()
        return VStack {
            HStack{
                Spacer()
                HStack{
                    if self.ble.connectionState != .connectedBoth{
                        buttonObjects[0]
                    }
                    
                    
                    
                    if self.ble.connectionState == .connectedBoth {
                        buttonObjects[1]
                        
                        Button("Device settings"){
                            isPresentingButtons.wrappedValue = true
                        }
                        .frame(width: 160, height: 50)
                        .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                    }
                }
                .popover(isPresented: isPresentingButtons){
                    VStack(spacing: 45){
                        ForEach(buttonObjects.indices.dropFirst(2), id: \ .self) { index in
                            buttonObjects[index]
                        }
                    }
                }
                Spacer()
                
            }.glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
            
        }
        .mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
    }
    
    func buttonObjects(debug: Bool = false) -> [AnyView] {
        var buttons: [AnyView] = []
        
        buttons.append(AnyView(
            Button("Start scan"){
                self.ble.startScan()
                self.showingScanPopover = true
            }
            .frame(width: 100, height: 50)
            .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
        ))
        
        buttons.append(AnyView(
            Button("Disconnect"){
                Task{
                    await self.bg.disconnectProper()
                }
            }
            .frame(width: 120, height: 50)
            .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
        ))
        
        buttons.append(AnyView(
            Button(self.displayOn ? "Turn display off" : "Turn display on"){
                self.displayOn.toggle()
                self.ble.sendBlank()
            }
            .frame(width: 150, height: 50)
            .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
        ))
        buttons.append(AnyView(
            Button ("Auto shut off: \(self.autoOff ? "on" : "off")"){
                self.autoOff.toggle()
            }
            .frame(width: 150, height: 50)
            .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
        ))
        buttons.append(AnyView(
            Button ("Silent mode: \(silentMode ? "on" : "off")"){
                self.ble.setSilentModeState(on: !self.silentMode)
            }
            .frame(width: 150, height: 50)
            .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
        ))
                       
        return buttons
    }
    
    //MARK: - Mirror
    func glassesMirror() -> some View {
        return VStack(alignment: .center){
            if ble.connectionState == .connectedBoth {
                //Glasses mirror on app UI
                Text(bg.textOutput)
                    .lineLimit(
                        currentPage == "Default" ? 1 :
                            currentPage == "Music" ? 3 :
                            currentPage == "Calendar" ? (info.numOfEvents == 1 ? 3 : 4) :
                            3 //Default if currentPage is none of the options
                    )
                    .minimumScaleFactor(0.5)
                    .mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
            }else{
                Text("Waiting for glasses to connect...")
                    .mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                    .font(.caption)
            }
        }
        .mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
    }
    
    //MARK: - Connection display
    func connectionDisplay() -> some View {
        return HStack{
            VStack(alignment: .center){
                Text("Connection status: \(ble.connectionStatus)")
                    .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                    .font(.headline)
            }.mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
        }
        .mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
    }
    
    //MARK: - Floating buttons
    func floatingButtons() -> some View {
        return FloatingButtons(items: floatingButtonItems)
            .environmentObject(theme)
    }
    
    //MARK: - Devices popup
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
    
    //MARK: - Background
    func backgroundGrid() -> some View {
        // State variables to hold the customizable properties of the grid.
        @State var lineColor: Color = darkMode ? primaryColor : secondaryColor
        @State var lineWidth: CGFloat = 1
        @State var spacing: CGFloat = 10
        
        
        return ZStack{
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


extension View {
    func mainUIMods(pri: Color, sec: Color, darkMode: Bool, bg: Bool = false) -> some View {
        self
            .frame(maxWidth: .infinity)
            .foregroundStyle(!darkMode ? pri : sec)
            .padding(2)
            .glassListBG(pri: pri, sec: sec, darkMode: darkMode, bg: bg)
            .padding(.horizontal, 6)
    }
}

private struct PreviewMainUIBlocks: View {
    @Namespace private var namespace
    
    @StateObject private var info: InfoManager
    @StateObject private var ble: G1BLEManager
    @StateObject private var page: PageManager
    @StateObject private var bg: BackgroundTaskManager
    
    @State private var presentingButtons: Bool = false
    
    init() {
        let infoInstance = InfoManager(cal: CalendarManager(), music: AMMonitor(), weather: WeatherManager(), health: HealthInfoGetter())
        let bleInstance = G1BLEManager()
        let fmInstance = PageManager(info: infoInstance)
        let bgmInstance = BackgroundTaskManager(ble: bleInstance, info: infoInstance, page: fmInstance)
        
        
        _info = StateObject(wrappedValue: infoInstance)
        _ble = StateObject(wrappedValue: bleInstance)
        _page = StateObject(wrappedValue: fmInstance)
        _bg = StateObject(wrappedValue: bgmInstance)
    }
    var body: some View {
        let ui = MainUIBlocks(namespace: namespace, infoManager: info, bleManager: ble, pageManager: page, bgManager: bg)
        
        ZStack {
            ui.backgroundGrid()
            VStack {
                ui.headerContent()
                ui.songInfo()
                ui.calendarInfo()
                ui.buttons(isPresentingButtons: $presentingButtons)
                ui.glassesMirror()
                ui.connectionDisplay()
            }
            
        }
    }
}

#Preview {
    PreviewMainUIBlocks()
}
