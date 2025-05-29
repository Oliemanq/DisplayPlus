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
    
    @State var events: [event] = []
    @State var curSong: Song = Song(title: "", artist: "", album: "", duration: 0, currentTime: 0, isPaused: true)
    
    
    //Initializing all info managers here
    var bleManager = G1BLEManager()
    // formattingManager and bgManager will be initialized in init() using the info instance.
    var info: InfoManager
    var formattingManager: FormattingManager
    var bgManager: BackgroundTaskManager
    
    @State private var timer: Timer?
    
    @State private var time = Date().formatted(date: .omitted, time: .shortened)
    
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
        // Initialize formattingManager and bgManager using the info instance.
        // @StateObject info is already initialized by this point.
        info = InfoManager(cal: CalendarManager(), music: MusicMonitor(), weather: WeatherManager())
        formattingManager = FormattingManager(info: info)
        self.bgManager = BackgroundTaskManager(ble: self.bleManager, info: self.info, formatting: self.formattingManager)
    }
    
    var body: some View {
        let darkMode: Bool = (colorScheme == .dark) //Dark mode variable
        
        let primaryColor = theme.primaryColor //Color themes being split for easier access
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
                
                List {
                    HStack {
                        Spacer()
                        VStack {
                            Text(time)
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            
                            HStack {
                                ForEach(daysOfWeek, id: \.self) { day in
                                    // Use info.getTodayDate() which now comes from an @ObservedObject
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
                    
                    if curSong.title == "" {
                        Text("No music playing")
                            .font(.headline)
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            .listRowBackground(
                                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                            )
                    }else{
                        // Current playing music plus progress bar
                        VStack(alignment: .leading) {
                            Text(curSong.title)
                                .font(.headline)
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            Text("\(curSong.album) - \(curSong.artist)")
                                .font(.subheadline)
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            
                            let formattedCurrentTime = Duration.seconds(curSong.currentTime).formatted(.time(pattern: .minuteSecond))
                            let formattedduration = Duration.seconds(curSong.duration).formatted(.time(pattern: .minuteSecond))
                            
                            Text("\(formattedCurrentTime) \(formattedduration)")
                                .font(.caption)
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                        }
                        .listRowBackground(
                            VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                        )
                    }
                    
                    // Use info.getEvents() which now comes from an @ObservedObject
                    if events.isEmpty {
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
                        // Use info.getEvents() for ForEach
                        ForEach(events) { event in
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
                            // bgManager.pageHandler() indirectly uses infoManager via formattingManager
                            // Ensure formattingManager is correctly using the @ObservedObject info
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
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear) // List background is now clear
        .font(Font.custom("Geeza Pro", size: 18, relativeTo: .body))
        .onAppear {
            info.update(updateWeatherBool: true)
            bgManager.startTimer() // Start the background task timer

            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.time = info.getTime()
                events = info.getEvents()
                curSong = info.getCurSong()
            }
                
            // info.update is called, and since info is @StateObject, UI should react to its @Published changes
        }
        .onDisappear {
            bgManager.stopTimer() // Stop the timer when view disappears
        }
        .onChange(of: displayOn) { oldValue, newValue in
            if !newValue{
                bleManager.sendBlank()
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
