import SwiftUI
import SwiftData
import EventKit
import AppIntents

struct ContentView: View {
    @StateObject private var displayManager = DisplayManager()
    
    @StateObject private var bleManager = G1BLEManager()
    @State private var counter: CGFloat = 0
    @State private var totalCounter: CGFloat = 0
    
    @EnvironmentObject var musicMonitor: MusicMonitor
    
    private var mainLoop = MainLoop()

    @State private var time = Date().formatted(date: .omitted, time: .shortened)
    @State private var timer: Timer?
    
    @Environment(\.colorScheme) private var colorScheme
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

    var body: some View {
        let darkMode: Bool = (colorScheme == .dark)
        
        let primaryColor = theme.primaryColor
        let secondaryColor  = theme.secondaryColor
        
        let floatingButtons: [FloatingButtonItem] = [
            .init(iconSystemName: "clock", extraText: "Default screen", action: {
                UserDefaults.standard.set("Default", forKey: "currentPage")
                print("Default screen")
            }),
            .init(iconSystemName: "music.note.list", extraText: "Music screen", action: {
                UserDefaults.standard.set("Music", forKey: "currentPage")
                print("Music page")
            }),
            .init(iconSystemName: "calendar", extraText: "Calendar screen", action: {
                UserDefaults.standard.set("Calendar", forKey: "currentPage")
                print("Calendar screen")
            }),
            .init(iconSystemName: "arrow.trianglehead.2.clockwise.rotate.90.camera.fill", extraText: "RearView", action: {
                UserDefaults.standard.set("RearView", forKey: "currentPage")
                print("RearView screen")
            })
        ]
        
        NavigationStack {
            ZStack{
                List {
                    HStack {
                        Spacer()
                        VStack {
                            Text(time)
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            
                            HStack {
                                ForEach(daysOfWeek, id: \.self) { day in
                                    if day == displayManager.getTodayWeekDay() {
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
                    
                    
                    Text("Calendar events")
                        .font(.headline)
                        .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                        .listRowBackground(
                            VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                        )
                    
                    if isLoading {
                        ProgressView("Loading events...")
                    } else {
                        ForEach(displayManager.eventsFormatted) { event in
                            
                            VStack(alignment: .leading) {
                                Text(event.titleLine)
                                    .font(.caption)
                                    .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                
                                
                                Text(event.subtitleLine)
                                    .font(.footnote)
                                    .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                                
                            }
                            .listRowBackground(
                                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                            )
                        }
                    }
                
                    
                    Text("end calendar")
                        .font(.headline)
                        .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                        .listRowBackground(
                            VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                        )
                    
                    
                    Spacer()
                        .listRowBackground(
                            VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                        )
                    
                    
                    HStack{
                        Spacer()
                        Button("Start scan"){
                            bleManager.startScan()
                        }
                        .padding(2)
                        .frame(width: 100, height: 30)
                        .background((!darkMode ? primaryColor : secondaryColor))
                        .foregroundColor(darkMode ? primaryColor : secondaryColor)
                        .buttonStyle(.borderless)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                    }.listRowBackground(
                        VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                    )
                    
                    HStack{
                        Spacer()
                        Button(UserDefaults.standard.bool(forKey: "displayOn") == true ? "Turn display off" : "Turn display on"){
                            
                            UserDefaults.standard.set(!UserDefaults.standard.bool(forKey: "displayOn"), forKey: "displayOn")
                            sendTextCommand()
                        }
                        .padding(2)
                        .frame(width: 150, height: 30)
                        .background((!darkMode ? primaryColor : secondaryColor))
                        .foregroundColor(darkMode ? primaryColor : secondaryColor)
                        .buttonStyle(.borderless)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                    }.listRowBackground(
                        VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                    )
                    HStack{
                        Spacer()
                        Button ("Auto shut off: \(UserDefaults.standard.bool(forKey: "autoOff") ? "on" : "off")"){
                            UserDefaults.standard.set(!UserDefaults.standard.bool(forKey: "autoOff"), forKey: "autoOff")
                        }
                        .padding(2)
                        .frame(width: 150, height: 30)
                        .background((!darkMode ? primaryColor : secondaryColor))
                        .foregroundColor(darkMode ? primaryColor : secondaryColor)
                        .buttonStyle(.borderless)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .listRowBackground(
                        VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                    )
                    
                    VStack{
                        Text(mainLoop.textOutput)
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            .font(.system(size: 11))
                        
                    }.listRowBackground(
                        VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                    )
                    HStack{
                        Spacer()
                        Text("Connection status: \(bleManager.connectionStatus)")
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                    }.listRowBackground(
                        VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                    )
                    
                }
                
                .scrollContentBackground(.hidden)
                .background(darkMode ? primaryColor : secondaryColor)
                .edgesIgnoringSafeArea(.bottom)
                .frame(width: 400)
                
                FloatingButton(items: floatingButtons)
                    .environmentObject(theme)
            }
        }
        .onAppear {
            if displayDetailsList.isEmpty {
                let newItem = DataItem()
                context.insert(newItem)
                try? context.save()
            }
            
            var displayOnCounter: Int = 0
            UIDevice.current.isBatteryMonitoringEnabled = true
            mainLoop.update()
            
            timer = Timer.scheduledTimer(withTimeInterval: 1/2, repeats: true) { _ in
                if UserDefaults.standard.bool(forKey: "autoOff") {
                    if UserDefaults.standard.bool(forKey: "displayOn") {
                        displayOnCounter += 1
                    }
                    if displayOnCounter >= 5*2 {
                        displayOnCounter = 0
                        UserDefaults.standard.set(false, forKey: "displayOn")
                    }
                }
                
                // Update the mainLoop with the current counter value
                mainLoop.update()
                if UserDefaults.standard.bool(forKey: "displayOn") {
                    mainLoop.HandleText()
                    sendTextCommand(text: mainLoop.textOutput)
                }
                
                // Update events
                counter += 1
                totalCounter += 1
                if UInt8(counter) >= 255 {
                    counter = 0
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            @AppStorage("connectionStatus") var connectionStatus: String = "Disconnected"
            bleManager.disconnect()
            
        }.onChange(of: displayOn) { oldValue, newValue in
            if !newValue{
                sendTextCommand()
            }
        }
        
    }
    
    func sendTextCommand(text: String = ""){
        bleManager.sendTextCommand(seq: UInt8(self.counter), text: text)
        
    }
}

class ThemeColors: ObservableObject {
    @Published var primaryColor: Color = Color(red: 10/255, green: 25/255, blue: 10/255)
    @Published var secondaryColor: Color = Color(red: 175/255, green: 220/255, blue: 175/255)
}

#Preview {
    ContentView()
}
