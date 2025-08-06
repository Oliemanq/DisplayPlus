import SwiftUI
import EventKit
import AppIntents

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let theme = ThemeColors()
    var primaryColor: Color { theme.primaryColor }
    var secondaryColor: Color { theme.secondaryColor }
    var darkMode: Bool { theme.darkMode }
    
    @State var showingDeviceSelectionPopup: Bool = false
    
    @StateObject private var info: InfoManager
    @StateObject private var ble: G1BLEManager
    @StateObject private var page: PageManager
    @StateObject private var bg: BackgroundTaskManager

    var floatingButtonItems: [FloatingButtonItem] {
        [
            .init(iconSystemName: "clock", extraText: "Default screen", action: {
                print("Default button pushed")
                currentPage = "Default"
            }),
            .init(iconSystemName: "music.note.list", extraText: "Music screen", action: {
                print("Music button pushed")
                currentPage = "Music"
            }),
            .init(iconSystemName: "calendar", extraText: "Calendar screen", action: {
                print("Calendar button pushed")
                currentPage = "Calendar"
            })
        ]
    }
    
    @AppStorage("currentPage", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var currentPage = "Default"
    @AppStorage("displayOn", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var displayOn = false
    @AppStorage("autoOff", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var autoOff: Bool = false
    @AppStorage("connectionStatus", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var connectionStatus: String = "Disconnected"
    @AppStorage("silentMode", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var silentMode: Bool = false
    
    @Namespace private var namespace
    
    @State private var isPresentingButtons: Bool = false
    @State private var isPresentingScanView: Bool = false
    
    @State var brightnessSlider: Double = 0.0
    @State private var isSliderDragging = false
    @State private var brightnessUpdateTimer: Timer?
    
    init() {
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
        NavigationStack {
            
            ZStack(alignment: .top){
                //MARK: - Background
                backgroundGrid()
                VStack {
                    //MARK: - headerContent
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
                        
                        .ContextualBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                        
                        Spacer()
                        
                        if ble.connectionState == .connectedBoth {
                            Spacer()
                            
                            VStack{
                                Text("Glasses - \(Int(ble.glassesBatteryAvg))%")
                                
                                Text("Case - \(Int(ble.caseBatteryLevel))%")
                            }
                            .ContextualBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                            
                            Spacer()
                        }
                    }
                    .mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
                    .padding(.top, 40) //Giving the entire scrollview some extra padding at the top
                    
                    //MARK: - songInfo
                    
                    if info.currentSong.title == "" {
                        HStack{
                            Spacer()
                            Text("No music playing")
                                .font(.headline)
                                .ContextualBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                            
                            Spacer()
                        }
                        .mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
                    }else{
                        // Current playing music
                        HStack{
                            Spacer()
                            VStack(alignment: .center) {
                                // Use infoManager.currentSong properties
                                Text("\(info.currentSong.title)")
                                
                                    .font(.headline)
                                Text("\(info.currentSong.album) - \(info.currentSong.artist)")
                                
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                
                                let formattedCurrentTime = Duration.seconds(info.currentSong.currentTime).formatted(.time(pattern: .minuteSecond))
                                let formattedduration = Duration.seconds(info.currentSong.duration).formatted(.time(pattern: .minuteSecond))
                                
                                Text("\(formattedCurrentTime) - \(formattedduration)")
                                    .font(.caption)
                                
                            }
                            .ContextualBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                            Spacer()
                        }
                        .mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
                        
                    }
                    
                    //MARK: - calendarInfo
                    HStack{
                        if info.eventsFormatted.isEmpty {
                            HStack{
                                Spacer()
                                Text("No events today")
                                    .font(.headline)
                                
                                    .ContextualBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                Spacer()
                            }
                        }else{
                            HStack{
                                VStack{
                                    Text("Calendar events (\(info.numOfEvents)): ")
                                        .font(.headline)
                                        .padding(.horizontal, 8)
                                    
                                        .ContextualBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                    
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
                                        .ContextualBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                    }
                                    
                                    
                                }
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                    .mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
                    
                    
                    //MARK: - buttons
                    HStack (spacing: 10){
                        VStack(alignment: .center){
                            VStack{
                                if ble.connectionState == .connectedBoth {
                                    Button("Disconnect"){
                                        Task{
                                            await bg.disconnectProper()
                                        }
                                    }
                                    .frame(width: 120, height: 50)
                                    .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                }else{
                                    Button("Start scan"){
                                        ble.startScan()
                                        isPresentingScanView = true
                                    }
                                    .frame(width: 100, height: 50)
                                    .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                }
                            }
                            .ContextualBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                            
                        }
                        
                        if ble.connectionState == .connectedBoth || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                            //MARK: - brightnessControl
                            VStack(alignment: .center){
                                VStack{
                                    Text("Brightness")

                                    VStack{
                                        if !ble.autoBrightnessEnabled{
                                            Slider(
                                                value: $brightnessSlider,
                                                in: 0...42,
                                                step: 6
                                            ) { editing in
                                                // This closure tells us when the user starts or stops dragging.
                                                isSliderDragging = editing
                                                if !editing {
                                                    // USER HAS FINISHED DRAGGING.
                                                    // Send the final brightness value to the glasses ONLY now.
                                                    print("set brightness with auto \(ble.autoBrightnessEnabled ? "on" : "off")")
                                                    ble.setBrightness(value: brightnessSlider)
                                                }
                                            }
                                            .accentColor(primaryColor)
                                        }
                                        
                                        Button("\(Image(systemName: ble.autoBrightnessEnabled ? "sun.max.fill" : "sun.min")) Auto"){
                                            withAnimation{
                                                ble.autoBrightnessEnabled.toggle()
                                                // Also send an update when auto-brightness is toggled
                                                print("set brightness with auto \(ble.autoBrightnessEnabled ? "on" : "off")")
                                                ble.setBrightness(value: brightnessSlider)
                                            }
                                        }
                                        .frame(width: 100,height: 30)
                                        .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                    }
                                }.ContextualBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                            }
                            
                        }
                    }.mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
                    
                    
                    //MARK: - When connected
                    if ble.connectionState == .connectedBoth {
                        //MARK: - Glasses mirror
                        VStack(alignment: .center){
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
                    
                    //MARK: - Connection status
                    VStack(alignment: .center){
                        Text("Connection status: \(ble.connectionStatus)")
                            .font(.headline)
                            .ContextualBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                    }
                    .mainUIMods(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
                }
                .padding(.horizontal, 16)
                
                //MARK: - Floating buttons
//                FloatingButtons(items: floatingButtonItems)
//                    .environmentObject(theme)
            }
            
        }
        .toolbar(content: {
            ToolbarItem(placement: .bottomBar) {
                NavigationLink(destination: SettingsView(bleIn: ble)) {
                    Image(systemName: "gearshape")
                }
            }
        })
        
        //MARK: - appear/disappear
        .onAppear {
            info.update(updateWeatherBool: true) // Initial update
            bg.startTimer() // Start the background task timer
            
            self.brightnessSlider = Double(ble.brightnessRaw)
        }
        .onDisappear {
            bg.stopTimer() // Stop the timer when view disappears
            ble.disconnect()
            displayOn.toggle()
        }
        
        //MARK: - onChange
        .onChange(of: displayOn) { newValue, _ in
            if !newValue {
                ble.sendBlank()
            } else {
                ble.sendText(text: bg.pageHandler(), counter: 0)
            }
        }
        .onChange(of: currentPage) { newValue, _ in
            // Just send update if page changes
            info.changed = true
            ble.sendText(text: bg.pageHandler(), counter: 0)
        }
        .onReceive(ble.$brightnessRaw) { newBrightness in
            // Only update the slider's visual position if the user is NOT dragging it.
            // This prevents the slider from jumping back to its old value during a drag.
            if !isSliderDragging {
                brightnessSlider = Double(newBrightness)
            }
        }
        //MARK: - popovers
        .popover(isPresented: $isPresentingScanView) {
            
            ZStack {
                darkMode ? primaryColor.opacity(0.5).ignoresSafeArea() : secondaryColor.opacity(0.75).ignoresSafeArea()

                VStack {
                    let pairs = Array(ble.discoveredPairs.values)
                    ForEach(pairs, id: \.channel) { pair in
                        let hasLeft = (pair.left != nil)
                        let hasRight = (pair.right != nil)
                        
                        VStack{
                            Text("Pair for channel \(pair.channel.map(String.init) ?? "unknown")")
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
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
                                withAnimation{
                                    Button("Connect to pair"){
                                        ble.connectPair(pair: pair)
                                        isPresentingScanView = false
                                    }
                                    .frame(width: 150, height: 50)
                                    .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                }
                            }
                        }
                        .padding(.horizontal, 50)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(!darkMode ? Color(primaryColor).opacity(0.05) : Color(secondaryColor).opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(
                                            (!darkMode ? primaryColor : secondaryColor).opacity(0.3),
                                            lineWidth: 0.5
                                        )
                                )
                        )
                    }
                }
            }
        }
    }
}

class ThemeColors: ObservableObject {
    @Published var primaryColor: Color = Color(red: 10/255, green: 25/255, blue: 10/255)
    @Published var secondaryColor: Color = Color(red: 175/255, green: 220/255, blue: 175/255)
    @Published var darkMode: Bool = (({ UITraitCollection.current.userInterfaceStyle == .dark })() == true)
}



#Preview {
    ContentView()
}

