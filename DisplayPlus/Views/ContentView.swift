import SwiftUI
import SwiftData
import EventKit
import AppIntents

struct ContentView: View {
    @AppStorage("showingCalibration") var showingCalibration: Bool = false
    @State var showingDeviceSelectionPopup: Bool = false
        
    @State private var counter: CGFloat = 0
    @State private var totalCounter: CGFloat = 0
    @State private var displayOnCounter: Int = 0
    
    // UserDefaults keys (must match BackgroundTaskManager)
    private let userDefaultsCounterKey = "backgroundTaskCounter"
    private let userDefaultsDisplayOnCounterKey = "backgroundTaskDisplayOnCounter"
    
    //Initializing all info managers here
    @StateObject var info: InfoManager // Removed inline initialization
    @StateObject var bleManager: G1BLEManager // Removed inline initialization
    @StateObject var formattingManager: FormattingManager // Removed inline initialization
    @StateObject var bgManager: BackgroundTaskManager // Removed inline initialization
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var context
    
    @AppStorage("currentPage") private var currentPage = "Default"
    @AppStorage("displayOn") private var displayOn = true
    @AppStorage("autoOff") private var autoOff: Bool = false
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var authorizationStatus: String = "Checking..."
    
    @State private var progressBar: Double = 0.0
    
    private let daysOfWeek: [String] = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    let formatter = DateFormatter()
    
    @StateObject var theme = ThemeColors()
    
    init() {
        // Create local instances of all managers first.
        // These instances will be used to initialize the @StateObject properties.
        let infoInstance = InfoManager(cal: CalendarManager(), music: MusicMonitor(), weather: WeatherManager(), health: HealthInfoGetter())
        let bleInstance = G1BLEManager()
        // FormattingManager depends on the InfoManager instance.
        let fmInstance = FormattingManager(info: infoInstance)
        // BackgroundTaskManager depends on the instances of G1BLEManager, InfoManager, and FormattingManager.
        let bgmInstance = BackgroundTaskManager(ble: bleInstance, info: infoInstance, formatting: fmInstance)

        // Now, initialize all @StateObject properties using these local instances.
        // This order ensures that dependencies are available.
        _info = StateObject(wrappedValue: infoInstance)
        _bleManager = StateObject(wrappedValue: bleInstance)
        _formattingManager = StateObject(wrappedValue: fmInstance)
        _bgManager = StateObject(wrappedValue: bgmInstance)
    }
    
    var body: some View {
        let darkMode: Bool = (colorScheme == .dark) //Dark mode variable
        
        let primaryColor = theme.primaryColor //Color themes being split for easier access
        let secondaryColor  = theme.secondaryColor
        
        let floatingButtonItems: [FloatingButtonItem] = [
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
        ] //Floating button init
        
        NavigationStack {
            ZStack{
                // Background gradient
                Group {
                    if darkMode {
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: secondaryColor, location: 0.0), // Lighter color at top-left
                                .init(color: primaryColor, location: 0.25),  // Transition to darker
                                .init(color: primaryColor, location: 1.0)   // Darker color for the rest
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: primaryColor, location: 0.0), // Darker color at top-left
                                .init(color: secondaryColor, location: 0.35),  // Transition to lighter
                                .init(color: secondaryColor, location: 1.0)   // Lighter color for the rest
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .edgesIgnoringSafeArea(.all)
                
                //Start Main UI
                List {
                    //Time, Date, and DoW
                    HStack {
                        Spacer()
                        VStack {
                            //Display glasses battery level if it has been updated
                            if bleManager.glassesBatteryAvg != 0.0 {
                                Text("\(info.time)  |  Glasses battery: \(Int(bleManager.glassesBatteryAvg))%")
                                    .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            }else{
                                Text("\(info.time)")
                                    .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            }
                            
                            HStack {
                                Text(info.getTodayDate())
                                    .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            }
                        }
                        Spacer()
                    }
                    .listRowInsets(EdgeInsets(top: 20, leading: 50, bottom: 20, trailing: 50))
                    .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)

                    //Song info
                    if info.currentSong.title == "" {
                        HStack{
                            Spacer()
                            Text("No music playing")
                                .font(.headline)
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)

                            Spacer()
                        }
                        .listRowInsets(EdgeInsets(top: 20, leading: 100, bottom: 20, trailing: 100))
                        .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                    }else{
                        // Current playing music plus progress bar
                        HStack{
                            Spacer()
                            VStack(alignment: .center) {
                                // Use info.currentSong properties
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
                            Spacer()
                        }.glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                    }
                    
                    //Calendar events
                    if info.eventsFormatted.isEmpty {
                        HStack{
                            Spacer()
                            Text("No events today")
                                .font(.headline)
                            Spacer()
                        }
                        .listRowInsets(EdgeInsets(top: 20, leading: 100, bottom: 20, trailing: 100))
                        .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                    }else{
                        Text("Calendar events: ")
                            .font(.headline)
                            .padding(.horizontal, 8)
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                        
                        // Use info.eventsFormatted for ForEach
                        if #available(iOS 26, *) {
                            GlassEffectContainer(spacing: 10.0){
                                ForEach(info.eventsFormatted) { event in
                                    HStack{
                                        VStack(alignment: .leading) {
                                            Text(" - \(event.titleLine)")
                                                .font(.caption)
                                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                            
                                            
                                            Text("    \(event.subtitleLine)")
                                                .font(.footnote)
                                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                        }.padding(.horizontal, 8)
                                        
                                    }
                                    .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                }
                            }
                        }else{
                            ForEach(info.eventsFormatted) { event in
                                HStack{
                                    VStack(alignment: .leading) {
                                        Text(" - \(event.titleLine)")
                                            .font(.caption)
                                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                        
                                        
                                        Text("    \(event.subtitleLine)")
                                            .font(.footnote)
                                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                    }
                                    
                                }
                                .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                
                                
                            }
                        }
                    }
                    //Buttons ___________________________________________________________________________________________________________________
                    if #available(iOS 26, *){
                        VStack{
                            HStack{
                                GlassEffectContainer(spacing: 10.0){
                                    ScrollView(.horizontal) {
                                        
                                        HStack{
                                            Spacer()
                                            if bleManager.connectionState != .connectedBoth{
                                                Button("Start scan"){
                                                    bleManager.startScan()
                                                    showingDeviceSelectionPopup = true
                                                }
                                                .frame(width: 100, height: 50)
                                                .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                            }
                                            
                                            
                                            
                                            if bleManager.connectionState == .connectedBoth{
                                                Button("Disconnect"){
                                                    bleManager.disconnect()
                                                }
                                                .frame(width: 120, height: 50)
                                                .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                                
                                                
                                                //Display toggle button
                                                Button(displayOn ? "Turn display off" : "Turn display on"){
                                                    displayOn.toggle()
                                                    bleManager.sendBlank()
                                                }
                                                .frame(width: 150, height: 50)
                                                .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                                
                                                
                                                //Auto off button
                                                Button ("Auto shut off: \(autoOff ? "on" : "off")"){
                                                    autoOff.toggle()
                                                }
                                                .frame(width: 150, height: 50)
                                                .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                                
                                                
                                                /*
                                                 Hiding buttons for testflight build
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
                            }
                        }
                            .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                        

                    }else{
                        VStack{
                            ScrollView(.horizontal) {
                                HStack{
                                    if bleManager.connectionState != .connectedBoth{
                                        Button("Start scan"){
                                            bleManager.startScan()
                                            showingDeviceSelectionPopup = true
                                        }
                                        .frame(width: 100, height: 50)
                                        .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                    }
                                    
                                    
                                    
                                    if bleManager.connectionState == .connectedBoth{
                                        Button("Disconnect"){
                                            bleManager.disconnect()
                                        }
                                        .frame(width: 120, height: 50)
                                        .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                        
                                        
                                        //Display toggle button
                                        Button(displayOn ? "Turn display off" : "Turn display on"){
                                            displayOn.toggle()
                                            bleManager.sendBlank()
                                        }
                                        .frame(width: 150, height: 50)
                                        .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                        
                                        
                                        //Auto off button
                                        Button ("Auto shut off: \(autoOff ? "on" : "off")"){
                                            autoOff.toggle()
                                        }
                                        .frame(width: 150, height: 50)
                                        .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                                        
                                        
                                        /*
                                         Hiding buttons for testflight build
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
                                }
                            }
                        }
                        .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)

                    }
                    
                    //Glasses mirror on app UI
                    if displayOn {
                        HStack{
                            Spacer()
                            VStack{
                                Text(bgManager.pageHandler())
                                    .font(.system(size: 11))
                            }
                            Spacer()
                        }.glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                    }
                    
                    //Connection status display
                    HStack{
                        Spacer()
                        Text("Connection status: \(bleManager.connectionStatus)")
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            .font(.headline)
                        Spacer()
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 30, bottom: 10, trailing: 30))
                    .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)

                    
                }
                
                //Bottom buttons
                FloatingButtons(items: floatingButtonItems, destinationView: { CalibrationView(ble: bleManager) })
                    .environmentObject(theme)
            }
            
            .popover(isPresented: $showingDeviceSelectionPopup) {
                VStack {
                    ForEach(Array(bleManager.discoveredPairs).indices, id: \.self) { index in
                        let pair = Array(bleManager.discoveredPairs.values)[index]
                        VStack{
                            Text("Pair for channel \(pair.channel.map(String.init) ?? "unknown")")
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            HStack {
                                if pair.left != nil {
                                    HStack{
                                        Image(systemName: "checkmark.circle")
                                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                        Text("Left found")
                                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                    }
                                } else {
                                    HStack {
                                        Image(systemName: "x.circle")
                                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                        Text("No left")
                                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                    }
                                }
                                if pair.right != nil {
                                    HStack{
                                        Image(systemName: "checkmark.circle")
                                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                        Text("Right found")
                                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                    }
                                } else {
                                    HStack {
                                        Image(systemName: "x.circle")
                                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                        Text("No right")
                                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                    }
                                }
                            }
                            if pair.left != nil && pair.right != nil {
                                Button("Connect to pair"){
                                    bleManager.connectPair(pair: pair)
                                    showingDeviceSelectionPopup = false
                                }
                                .frame(width: 150, height: 50)
                                .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                            }
                        }
                    }
                }
            }
             
        }
        
        .scrollContentBackground(.hidden)
        .background(Color.clear) // List background is now clear
        .onAppear {
            bleManager.fetchGlassesBattery()
            info.update(updateWeatherBool: true) // Initial update
            bgManager.startTimer() // Start the background task timer
        }
        .onDisappear {
            bgManager.stopTimer() // Stop the timer when view disappears
            bleManager.disconnect()
            displayOn.toggle()
        }
        
        //Checking if displayOn changes and acting accordingly, mainly to bypass lag in timer
        .onChange(of: displayOn) { oldValue, newValue in
            if !newValue{
                bleManager.sendBlank()
            }else{
                bleManager.sendText(text: bgManager.pageHandler(), counter: 0)
            }
        }
        .onChange(of: currentPage) { oldValue, newValue in
            if oldValue != newValue{
                info.changed = true
                bleManager.sendText(text: bgManager.pageHandler(), counter: 0)
            }
        }
    }
}

class ThemeColors: ObservableObject {
    @Published var primaryColor: Color = Color(red: 10/255, green: 25/255, blue: 10/255)
    @Published var secondaryColor: Color = Color(red: 175/255, green: 220/255, blue: 175/255)
}

#Preview {
    ContentView()
}

