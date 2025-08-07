import SwiftUI
import EventKit
import AppIntents

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

struct ContentView: View {
    @State var showingDeviceSelectionPopup: Bool = false
    
    @StateObject private var info: InfoManager
    @StateObject private var ble: G1BLEManager
    @StateObject private var bg: BackgroundTaskManager
    var theme: ThemeColors
    
    @AppStorage("currentPage", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var currentPage = "Default"
    @AppStorage("displayOn", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var displayOn = false
    @AppStorage("autoOff", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var autoOff: Bool = false
    @AppStorage("connectionStatus", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var connectionStatus: String = "Disconnected"
    @AppStorage("silentMode", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var silentMode: Bool = false
    
    @Namespace private var namespace
    
    @AppStorage("isPresentingScanView", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var isPresentingScanView: Bool = false
    
    @State var brightnessSlider: Double = 0.01
    @State private var isSliderDragging = false
    @State private var brightnessUpdateTimer: Timer?
    
    init(infoInstance: InfoManager, bleInstance: G1BLEManager, bgInstance: BackgroundTaskManager, themeIn: ThemeColors) {
        _info = StateObject(wrappedValue: infoInstance)
        _ble = StateObject(wrappedValue: bleInstance)
        _bg = StateObject(wrappedValue: bgInstance)
        
        theme = themeIn
    }
    
    var body: some View {
        let buttonPadding = 12.0
        let buttonWidth = 200.0
        
        NavigationStack {
            ZStack(alignment: .bottom){
                //MARK: - Background
                backgroundGrid(themeIn: theme)
                
                ScrollView(.vertical) {
                    VStack {
                        if ble.connectionState == .connectedBoth || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                            //MARK: - Glasses mirror
                            VStack{
                                if displayOn {
                                    ZStack{
                                        VStack(alignment: .center){
                                            Text(bg.textOutput)
                                                .lineLimit(
                                                    currentPage == "Default" ? 1 :
                                                        currentPage == "Music" ? 3 :
                                                        currentPage == "Calendar" ? (info.numOfEvents == 1 ? 3 : 4) :
                                                        3 //Default if currentPage is none of the options
                                                )
                                                .minimumScaleFactor(0.5)
                                                .mainUIMods(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                                        }
                                        VStack{
                                            HStack{
                                                Image(systemName: "eyeglasses")
                                                    .foregroundStyle(Color.black)
                                                Spacer()
                                            }
                                            Spacer()
                                        }
                                        .padding(.top, 10)
                                        .padding(.horizontal, 12)
                                    }
                                    .mainUIMods(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode, bg: true)
                                }
                            }.animation(.bouncy, value: displayOn)
                            
                        
                            //MARK: - buttons
                            HStack (spacing: 10){
                                VStack(alignment: .center){
                                    //Silent mode button
                                    Button {
                                        withAnimation{
                                            ble.setSilentModeState(on: !silentMode)
                                        }
                                    } label: {
                                        HStack(alignment: .center){
                                            Text("Silent mode")
                                            Spacer()
                                            Text("\(Image(systemName: silentMode ? "checkmark.circle" : "x.circle"))")
                                        }.padding(.horizontal, buttonPadding)
                                    }
                                    .frame(width: buttonWidth, height: (silentMode ? 90 : 35))
                                    .mainButtonStyle(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                                    
                                    //Display on button
                                    if !silentMode {
                                        Button {
                                            withAnimation{
                                                displayOn.toggle()
                                            }
                                        } label: {
                                            HStack(alignment: .center){
                                                Text("Display")
                                                Spacer()
                                                Text("\(Image(systemName: displayOn ? "checkmark.circle" : "x.circle"))")
                                            }.padding(.horizontal, buttonPadding)
                                        }
                                        .frame(width: buttonWidth, height: 50)
                                        .mainButtonStyle(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                                    }
                                }
                                .ContextualBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                                
                                
                                //ADD BATTERY HERE
                                //ADD BATTERY HERE
                                //ADD BATTERY HERE
                                //ADD BATTERY HERE
                                //ADD BATTERY HERE
                                //ADD BATTERY HERE

                                
                            }
                            .mainUIMods(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode, bg: true)
                            
                            

                            HStack{
                                //MARK: - brightnessControl
                                VStack(alignment: .center){
                                    VStack{
                                        if #available (iOS 26, *) {
                                            GlassEffectContainer(spacing: 15) {
                                                HStack(spacing: 1){
                                                    Text("Brightness")
                                                        .frame(width: 120, height: 30)
                                                        .mainButtonStyle(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                                                        .glassEffectID("BrightnessDisplay", in: namespace)
                                                        .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.1), value: brightnessSlider)
                                                    if !ble.autoBrightnessEnabled{
                                                        Text("\(Int(ceil(brightnessSlider/6)))")
                                                            .font(.system(size: 12 + CGFloat(brightnessSlider/6)*1.25))
                                                            .frame(width: CGFloat(brightnessSlider/6*15 + 30), height: 30)
                                                            .mainButtonStyle(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                                                            .glassEffectID("BrightnessDisplay", in: namespace)
                                                            .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.1), value: brightnessSlider)
                                                    }
                                                }
                                            }
                                        }else{
                                            HStack{
                                                Text("Brightness")
                                                    .frame(width: 120, height: 30)
                                                    .mainButtonStyle(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                                                
                                                Text("\(Int(ceil(brightnessSlider/6)))")
                                                    .font(.system(size: 12 + CGFloat(brightnessSlider/6)*1.25))
                                                    .frame(width: CGFloat(brightnessSlider/6*15 + 30), height: 30)
                                                    .mainButtonStyle(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                                            }
                                        }
                                        
                                        VStack{
                                            if !ble.autoBrightnessEnabled{
                                                Slider(
                                                    value: $brightnessSlider,
                                                    in: 0.01...42,
                                                    step: 6
                                                ) { editing in
                                                    isSliderDragging = editing
                                                    if !editing {
                                                        // USER HAS FINISHED DRAGGING.
                                                        print("set brightness with auto \(ble.autoBrightnessEnabled ? "on" : "off")")
                                                        ble.setBrightness(value: brightnessSlider)
                                                        
                                                    }
                                                }
                                                .accentColor(theme.darkMode ? theme.sec : theme.pri)
                                            }
                                            if #available(iOS 26, *){
                                                Button("\(Image(systemName: ble.autoBrightnessEnabled ? "environments.fill" : "environments.slash")) Auto"){
                                                    withAnimation{
                                                        ble.autoBrightnessEnabled.toggle()
                                                        // Also send an update when auto-brightness is toggled
                                                        print("set brightness with auto \(ble.autoBrightnessEnabled ? "on" : "off")")
                                                        ble.setBrightness(value: brightnessSlider)
                                                    }
                                                }
                                                .frame(width: 100,height: 30)
                                                .mainButtonStyle(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                                            }else{
                                                Button("\(Image(systemName: ble.autoBrightnessEnabled ? "sun.max.fill" : "sun.min")) Auto"){
                                                    withAnimation(.easeInOut){
                                                        ble.autoBrightnessEnabled.toggle()
                                                        // Also send an update when auto-brightness is toggled
                                                        print("set brightness with auto \(ble.autoBrightnessEnabled ? "on" : "off")")
                                                        ble.setBrightness(value: brightnessSlider)
                                                    }
                                                }
                                                .frame(width: 100,height: 30)
                                                .mainButtonStyle(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                                                .animation(.easeInOut, value: ble.autoBrightnessEnabled)
                                            }
                                        }
                                    }
                                }.ContextualBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                            }
                            .padding(.horizontal, 12)
                            .mainUIMods(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode, bg: true)
                        }
                    }
                    .padding(.top, 50)
                }
                .padding(.horizontal, 16)
            }
            //MARK: - Connection status
            
            
            .onAppear() {
                self.brightnessSlider = Double(ble.brightnessRaw)
            }
            
            //MARK: - onChange
            .onChange(of: displayOn) {
                print("display \(displayOn ? "on" : "off")")
                if !displayOn {
                    ble.sendBlank()
                } else {
                    info.changed = true
                }
            } //Preventing delays from waiting for bg timer when changing pages
            .onChange(of: currentPage) {
                info.changed = true
                ble.sendText(text: bg.pageHandler(), counter: 0)
            } //^^^
            .onChange(of: silentMode) {
                Task{
                    print("silent mode changed")
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    if !silentMode {
                        print("silent mode turned off, turning on display")
                        withAnimation{
                            displayOn = true
                        }
                    }else{
                        print("silent mode turned on, turning off display")
                        withAnimation{
                            displayOn = false
                        }
                    }
                }
            } //Turning display on and off with silent mode
            .onReceive(ble.$brightnessRaw) { newBrightness in
                // Only update the slider's visual position if the user is NOT dragging it.
                // This prevents the slider from jumping back to its old value during a drag.
                if !isSliderDragging {
                    brightnessSlider = Double(newBrightness)
                }
            } //Preventing weird updates with brightness slider
            //MARK: - popovers
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
                                    .foregroundStyle(!theme.darkMode ? theme.pri : theme.sec)
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
                                        .mainButtonStyle(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                                    }
                                }
                            }
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
        }
    }
}

class ThemeColors: ObservableObject {
    @Published var pri: Color = Color(red: 10/255, green: 25/255, blue: 10/255)
    @Published var sec: Color = Color(red: 175/255, green: 220/255, blue: 175/255)
    @Published var darkMode: Bool = false
}



#Preview {
    let infoInstance = InfoManager(cal: CalendarManager(), music: AMMonitor(), weather: WeatherManager(), health: HealthInfoGetter())
    let bleInstance = G1BLEManager()
    let pageInstance = PageManager(info: infoInstance)
    let bgInstance = BackgroundTaskManager(ble: bleInstance, info: infoInstance, page: pageInstance)
    
    ContentView(infoInstance: infoInstance, bleInstance: bleInstance, bgInstance: bgInstance, themeIn: ThemeColors())
}

