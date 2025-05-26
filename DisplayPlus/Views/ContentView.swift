import SwiftUI
import SwiftData
import EventKit
import AppIntents

struct ContentView: View {
    @State var showingCalibration = false
    
    @ObservedObject var weather: weatherManager
    
    @StateObject var displayManager: DisplayManager
    @StateObject var mainLoop: MainLoop

    
    @StateObject private var bleManager = G1BLEManager()
    @State private var counter: CGFloat = 0
    @State private var totalCounter: CGFloat = 0
    @State private var displayOnCounter: Int = 0 // Moved from .onAppear to @State

    // UserDefaults keys (must match BackgroundTaskManager)
    private let userDefaultsCounterKey = "backgroundTaskCounter"
    private let userDefaultsDisplayOnCounterKey = "backgroundTaskDisplayOnCounter"

    @EnvironmentObject var musicMonitor: MusicMonitor
    
    @State private var timer: Timer? // Already a @State, which is good

    @State private var time = Date().formatted(date: .omitted, time: .shortened)
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase // Added for lifecycle management
    @Environment(\.modelContext) private var context
    @Query() private var displayDetailsList: [DataItem]
    
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
    
    init(weather: weatherManager){
        _weather = ObservedObject(wrappedValue: weather)
        
        let initialDisplayManager = DisplayManager(weather: weather)
        _displayManager = StateObject(wrappedValue: initialDisplayManager)
        _mainLoop = StateObject(wrappedValue: MainLoop(displayManager: initialDisplayManager))
    }

    var body: some View {
        let darkMode: Bool = (colorScheme == .dark)
        
        let primaryColor = theme.primaryColor
        let secondaryColor  = theme.secondaryColor
        
        let floatingButtons: [FloatingButtonItem] = [
            .init(iconSystemName: "clock", extraText: "Default screen", action: {
                UserDefaults.standard.set("Default", forKey: "currentPage")
            }),
            .init(iconSystemName: "music.note.list", extraText: "Music screen", action: {
                UserDefaults.standard.set("Music", forKey: "currentPage")
            }),
            .init(iconSystemName: "calendar", extraText: "Calendar screen", action: {
                UserDefaults.standard.set("Calendar", forKey: "currentPage")
            })
        ]
        
        NavigationStack {
            ZStack{
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

                List {
                    HStack {
                        Spacer()
                        VStack {
                            Text(time)
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            
                            HStack {
                                ForEach(daysOfWeek, id: \.self) { day in
                                    if day == displayManager.getTodayDate() {
                                        Text(day).bold()
                                            .padding(0)
                                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                        
                                    } else {
                                        Text(day)
                                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                            .padding(-1)
                                    }
                                }
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(
                        VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                    )
                    
                    if musicMonitor.curSong.title == "" {
                        Text("No music playing")
                            .font(.headline)
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            .listRowBackground(
                                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                            )
                    }else{
                        // Current playing music plus progress bar
                        VStack(alignment: .leading) {
                            Text(musicMonitor.curSong.title)
                                .font(.headline)
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            HStack {
                                Text(musicMonitor.curSong.album)
                                    .font(.subheadline)
                                    .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                
                                Text(musicMonitor.curSong.artist)
                                    .font(.subheadline)
                                    .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                
                            }
                            HStack {
                                let formattedCurrentTime = Duration.seconds(musicMonitor.currentTime).formatted(.time(pattern: .minuteSecond))
                                let formattedduration = Duration.seconds(musicMonitor.curSong.duration).formatted(.time(pattern: .minuteSecond))
                                
                                Text("\(formattedCurrentTime)")
                                    .font(.caption)
                                    .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                
                                
                                Text("\(formattedduration)")
                                    .font(.caption)
                                    .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                
                            }
                        }
                        .listRowBackground(
                            VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                        )
                    }
                    
                    if displayManager.eventsFormatted.isEmpty {
                        Text("No events today")
                            .font(.headline)
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            .listRowBackground(
                                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                            )
                    }else{
                        Text("Calendar events:")
                            .font(.headline)
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            .listRowBackground(
                                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                            )
                        
                        if isLoading {
                            ProgressView("Loading events...")
                        } else {
                            ForEach(displayManager.eventsFormatted) { event in
                                HStack{
                                    Spacer()
                                    VStack(alignment: .leading) {
                                        Text(event.titleLine)
                                            .font(.caption)
                                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                        
                                        
                                        Text(event.subtitleLine)
                                            .font(.footnote)
                                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                    }
                                    Spacer()
                                    Spacer()
                                    Spacer()
                                    Spacer()
                                }
                                .listRowBackground(
                                    VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                                )
                            }
                        }
                    }
                    
                    VStack{
                        HStack{
                            Spacer()
                            
                            
                            
                        }.listRowBackground(
                            VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                        )
                        
                        ScrollView(.horizontal) {
                            HStack{
                                if !bleManager.connectionStatus.contains("Connected"){
                                    Button("Start scan"){
                                        bleManager.startScan()
                                    }
                                    .padding(2)
                                    .frame(width: 100, height: 50)
                                    .background((!darkMode ? primaryColor : secondaryColor))
                                    .foregroundColor(darkMode ? primaryColor : secondaryColor)
                                    .buttonStyle(.borderless)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }else{
                                    Button("Disconnect"){
                                        bleManager.disconnect()
                                    }
                                    .padding(2)
                                    .frame(width: 150, height: 50)
                                    .background((!darkMode ? primaryColor : secondaryColor))
                                    .foregroundColor(darkMode ? primaryColor : secondaryColor)
                                    .buttonStyle(.borderless)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                
                                Button(UserDefaults.standard.bool(forKey: "displayOn") == true ? "Turn display off" : "Turn display on"){
                                    
                                    UserDefaults.standard.set(!UserDefaults.standard.bool(forKey: "displayOn"), forKey: "displayOn")
                                    sendTextCommand()
                                }
                                .padding(2)
                                .frame(width: 150, height: 50)
                                .background((!darkMode ? primaryColor : secondaryColor))
                                .foregroundColor(darkMode ? primaryColor : secondaryColor)
                                .buttonStyle(.borderless)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                Button ("Auto shut off: \(UserDefaults.standard.bool(forKey: "autoOff") ? "on" : "off")"){
                                    UserDefaults.standard.set(!UserDefaults.standard.bool(forKey: "autoOff"), forKey: "autoOff")
                                }
                                .padding(2)
                                .frame(width: 150, height: 50)
                                .background((!darkMode ? primaryColor : secondaryColor))
                                .foregroundColor(darkMode ? primaryColor : secondaryColor)
                                .buttonStyle(.borderless)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .listRowBackground(
                        VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                    )
                    if displayOn {
                        VStack{
                            Text(mainLoop.textOutput)
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                .font(.system(size: 11))
                        }
                        .listRowBackground(
                            VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                        )
                        
                    }
                    HStack{
                        Text("Connection status: \(bleManager.connectionStatus)")
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            .font(.headline)
                    }.listRowBackground(
                        VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                    )
                    
                }
                
                .scrollContentBackground(.hidden)
                .background(Color.clear) // List background is now clear
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        NavigationLink(destination: CalibrationView(ble: bleManager)){
                            Text("Calibrate screen")
                        }
                        .simultaneousGesture(TapGesture().onEnded {showingCalibration = true})
                        .font(.system(size: 12))
                        .fontWeight(.semibold)
                        .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                        .padding(10) // Inner padding for the button's text
                        .contentShape(.rect(cornerRadius: 8))
                        .background(.ultraThinMaterial, in: .rect(cornerRadius: 8))
                        .padding(.trailing, 30) // Padding from the right edge
                        .padding(.bottom, 10) // Padding from the bottom edge
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure VStack fills the space
                
                FloatingButton(items: floatingButtons)
                    .environmentObject(theme)
            }
            .font(Font.custom("Geeza Pro", size: 18, relativeTo: .body))
        }
        .onAppear {
            // Initial setup
            bleManager.startScan()
            
            UIDevice.current.isBatteryMonitoringEnabled = true
            mainLoop.update() // Initial update
            Task {
                try await weather.fetchWeatherData()
            }

            // Start timer only if scene is already active.
            // Otherwise, .onChange(of: scenePhase) will handle it.
            if scenePhase == .active {
                loadStateFromUserDefaults()
                startTimer()
            }
        }
        .onDisappear {
            stopTimer()
            // No need to save state here as scenePhase change will handle it before this.
            UserDefaults.standard.set("Disconnected", forKey: "connectionStatus")
            bleManager.disconnect()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                loadStateFromUserDefaults() // Load state when becoming active
                startTimer()
            case .inactive, .background:
                saveStateToUserDefaults() // Save state when going to background/inactive
                stopTimer()
            @unknown default:
                saveStateToUserDefaults() // Be safe
                stopTimer()
            }
        }
        .onChange(of: displayOn) { oldValue, newValue in
            if !newValue{
                sendTextCommand()
            }
        }
        
    }
    
    func sendTextCommand(text: String = ""){
        // Ensure counter is treated as an integer for sequence number
        bleManager.sendTextCommand(seq: UInt8(Int(self.counter) % 256), text: text)
        
    }

    // Helper functions for timer management
    func startTimer() {
        timer?.invalidate()
        // Ensure displayOnCounter is reset appropriately if display is turned on manually
        if UserDefaults.standard.bool(forKey: "displayOn") && !UserDefaults.standard.bool(forKey: "autoOff") {
            displayOnCounter = 0
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1/2, repeats: true) { _ in
            if !showingCalibration {
                if UserDefaults.standard.bool(forKey: "autoOff") {
                    if UserDefaults.standard.bool(forKey: "displayOn") {
                        displayOnCounter += 1
                    }
                    if displayOnCounter >= 10 { // Adjusted to 10 ticks of 0.5s = 5 seconds
                        displayOnCounter = 0
                        UserDefaults.standard.set(false, forKey: "displayOn")
                    }
                }
                
                mainLoop.update()
                if UserDefaults.standard.bool(forKey: "displayOn") {
                    mainLoop.HandleText()
                    sendTextCommand(text: mainLoop.textOutput)
                }
                
                counter = CGFloat((Int(counter) + 1) % 256) // Ensure counter wraps and stays integer-like for seq
                totalCounter += 1
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // Helper functions for state persistence
    func loadStateFromUserDefaults() {
        self.counter = CGFloat(UserDefaults.standard.integer(forKey: userDefaultsCounterKey))
        self.displayOnCounter = UserDefaults.standard.integer(forKey: userDefaultsDisplayOnCounterKey)
        print("ContentView: Loaded state - counter: \(self.counter), displayOnCounter: \(self.displayOnCounter)")
    }

    func saveStateToUserDefaults() {
        UserDefaults.standard.set(Int(self.counter), forKey: userDefaultsCounterKey)
        UserDefaults.standard.set(self.displayOnCounter, forKey: userDefaultsDisplayOnCounterKey)
        print("ContentView: Saved state - counter: \(self.counter), displayOnCounter: \(self.displayOnCounter)")
    }
}

class ThemeColors: ObservableObject {
    @Published var primaryColor: Color = Color(red: 10/255, green: 25/255, blue: 10/255)
    @Published var secondaryColor: Color = Color(red: 175/255, green: 220/255, blue: 175/255)
}

#Preview {
    ContentView(weather: weatherManager())
        .environmentObject(MusicMonitor()) // Add MusicMonitor to the environment
}
