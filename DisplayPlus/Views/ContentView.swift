import SwiftUI
import SwiftData
import EventKit
import AppIntents

struct ContentView: View {
    @State var showingCalibration = false
    
    @State private var counter: CGFloat = 0
    @State private var totalCounter: CGFloat = 0
    @State private var displayOnCounter: Int = 0 // Moved from .onAppear to @State
    
    // UserDefaults keys (must match BackgroundTaskManager)
    private let userDefaultsCounterKey = "backgroundTaskCounter"
    private let userDefaultsDisplayOnCounterKey = "backgroundTaskDisplayOnCounter"
    
    //Initializing all info managers here
    @StateObject var info: InfoManager // Removed inline initialization
    @StateObject var bleManager: G1BLEManager // Removed inline initialization
    @StateObject var formattingManager: FormattingManager // Removed inline initialization
    @StateObject var bgManager: BackgroundTaskManager // Removed inline initialization
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase // Added for lifecycle management
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
                UserDefaults.standard.set("Default", forKey: "currentPage")
            }),
            .init(iconSystemName: "music.note.list", extraText: "Music screen", action: {
                UserDefaults.standard.set("Music", forKey: "currentPage")
            }),
            .init(iconSystemName: "calendar", extraText: "Calendar screen", action: {
                UserDefaults.standard.set("Calendar", forKey: "currentPage")
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
                //End background gradient
                
                //Start Main UI
                List {
                    HStack {
                        Spacer()
                        VStack {
                            // Use info.time directly, which should be @Published in InfoManager
                            Text(info.time)
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            
                            HStack {
                                ForEach(daysOfWeek, id: \.self) { day in
                                    if day == info.getTodayDate() {
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
                    
                    // Use info.currentSong directly
                    if info.currentSong.title == "" {
                        Text("No music playing")
                            .font(.headline)
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            .listRowBackground(
                                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                            )
                    }else{
                        // Current playing music plus progress bar
                        VStack(alignment: .leading) {
                            // Use info.currentSong properties
                            Text(info.currentSong.title)
                                .font(.headline)
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            Text("\(info.currentSong.album) - \(info.currentSong.artist)")
                                .font(.subheadline)
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            
                            let formattedCurrentTime = Duration.seconds(info.currentSong.currentTime).formatted(.time(pattern: .minuteSecond))
                            let formattedduration = Duration.seconds(info.currentSong.duration).formatted(.time(pattern: .minuteSecond))
                            
                            Text("\(formattedCurrentTime) \(formattedduration)")
                                .font(.caption)
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                        }
                        .listRowBackground(
                            VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                        )
                    }
                    
                    // Use info.eventsFormatted directly
                    if info.eventsFormatted.isEmpty {
                        Text("No events today")
                            .font(.headline)
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            .listRowBackground(
                                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                            )
                    }else{
                        Text("Calendar events: ")
                            .font(.headline)
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            .listRowBackground(
                                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                            )
                        // Use info.eventsFormatted for ForEach
                        ForEach(info.eventsFormatted) { event in
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
                    
                    VStack{
                        ScrollView(.horizontal) {
                            HStack{
                                
                                Button("Start scan"){
                                    bleManager.startScan()
                                }
                                .padding(2)
                                .frame(width: 100, height: 50)
                                .background((!darkMode ? primaryColor : secondaryColor))
                                .foregroundColor(darkMode ? primaryColor : secondaryColor)
                                .buttonStyle(.borderless)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                /*else{
                                 Button("Disconnect"){
                                 bleManager.disconnect()
                                 }
                                 .padding(2)
                                 .frame(width: 150, height: 50)
                                 .background((!darkMode ? primaryColor : secondaryColor))
                                 .foregroundColor(darkMode ? primaryColor : secondaryColor)
                                 .buttonStyle(.borderless)
                                 .clipShape(RoundedRectangle(cornerRadius: 12))
                                 }*/
                                
                                Button(UserDefaults.standard.bool(forKey: "displayOn") == true ? "Turn display off" : "Turn display on"){
                                    
                                    UserDefaults.standard.set(!UserDefaults.standard.bool(forKey: "displayOn"), forKey: "displayOn")
                                    bleManager.sendBlank()
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
                            Text(bgManager.pageHandler())
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
                
                //Bottom buttons
                FloatingButtons(items: floatingButtonItems, destinationView: { CalibrationView(ble: bleManager) })
                    .environmentObject(theme)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear) // List background is now clear
        .font(Font.custom("Geeza Pro", size: 18, relativeTo: .body))
        .onAppear {
            info.update(updateWeatherBool: true) // Initial update
            bgManager.startTimer() // Start the background task timer
        }
        .onDisappear {
            bgManager.stopTimer() // Stop the timer when view disappears
            displayOn.toggle()
        }
        .onChange(of: displayOn) { oldValue, newValue in //Checking if displayOn changes and acting accordingly, mainly to bypass lag in timer
            if !newValue{
                bleManager.sendBlank()
            }else{
                bleManager.startScan()
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
