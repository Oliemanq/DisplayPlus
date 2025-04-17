import SwiftUI
import EventKit

struct ContentView: View {
    @StateObject private var displayManager = DisplayManager()
    @State var textOutput: String = ""
    @State var autoOff: Bool = false

    @State public var currentPage: String = "Default"
    @StateObject private var bleManager = G1BLEManager()
    @State private var counter: CGFloat = 0
    @State private var totalCounter: CGFloat = 0
    
    @EnvironmentObject var musicMonitor: MusicMonitor

    @State private var time = Date().formatted(date: .omitted, time: .shortened)
    @State private var timer: Timer?
    
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var authorizationStatus: String = "Checking..."
    
    @State private var progressBar: Double = 0.0
    @State private var events: [EKEvent] = []
    
    private let daysOfWeek: [String] = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    let formatter = DateFormatter()
    
    @StateObject var theme = ThemeColors()

    
    var body: some View {
        let darkMode: Bool = (colorScheme == .dark)
        
        let primaryColor = theme.primaryColor
        let secondaryColor  = theme.secondaryColor
        
        let floatingButtons: [FloatingButtonItem] = [
            .init(iconSystemName: "clock", extraText: "Default screen", action: {
                currentPage = "Default"
                print("Default screen")
            }),
            .init(iconSystemName: "music.note.list", extraText: "Music screen", action: {
                currentPage = "Music"
                print("Music page")
            }),
            .init(iconSystemName: "calendar", extraText: "Calendar screen", action: {
                currentPage = "Calendar"
                print("Calendar screen")
            }),
            .init(iconSystemName: "arrow.trianglehead.2.clockwise.rotate.90.camera.fill", extraText: "RearView", action: {
                currentPage = "RearView"
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
                                
                            if !(musicMonitor.curSong.duration < musicMonitor.currentTime) {
                                ProgressView(value: musicMonitor.curSong.percentagePlayed).tint(!darkMode ? primaryColor : secondaryColor)
                            }
                            
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
                        ForEach(events, id: \.eventIdentifier) { event in
                            VStack(alignment: .leading) {
                                Text(event.title)
                                    .font(.caption)
                                    .foregroundStyle(!darkMode ? primaryColor : secondaryColor)

                                
                                HStack {
                                    Text(formatter.string(from: event.startDate))
                                        .font(.caption2)
                                        .foregroundStyle(!darkMode ? primaryColor : secondaryColor)

                                    Text("-")
                                        .font(.caption2)
                                        .foregroundStyle(!darkMode ? primaryColor : secondaryColor)

                                    
                                    Text(formatter.string(from: event.endDate))
                                        .font(.caption2)
                                        .foregroundStyle(!darkMode ? primaryColor : secondaryColor)

                                }
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
                        Button(bleManager.displayOn ? "Turn display off" : "Turn display on"){
                            bleManager.displayOn.toggle()
                            print(String(bleManager.displayOn))
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
                        Button ("Auto shut off: \(autoOff ? "on" : "off")"){
                            autoOff.toggle()
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
                        Text(textOutput)
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
            events = displayManager.getEvents()
            var displayOnCounter: Int = 0
            UIDevice.current.isBatteryMonitoringEnabled = true
            
            timer = Timer.scheduledTimer(withTimeInterval: 1/2, repeats: true) { _ in
                
                // Update time
                time = Date().formatted(date: .omitted, time: .shortened)
                
                displayManager.loadEvents()
                if autoOff{
                    if bleManager.displayOn {
                        displayOnCounter += 1
                    }
                    if displayOnCounter == 10*2{
                        displayOnCounter = 0
                        bleManager.displayOn.toggle()
                    }
                }
                

                // Update events
                
                counter += 1
                totalCounter += 1
                
                displayManager.updateHUDInfo()
                
                if bleManager.displayOn {
                    let currentDisplay = mainDisplayLoop()
                    sendTextCommand(text: currentDisplay)
                } else {
                    sendTextCommand()
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            bleManager.disconnect()
        }
    }
    
    func mainDisplayLoop() -> String{
        textOutput = ""
        
        if currentPage == "Default"{ // DEFAULT PAGE HANDLER
            let displayLines = displayManager.defaultDisplay()
            if displayLines.isEmpty{
                textOutput = "broken"
            }else{
                for line in displayLines {
                    textOutput += line + "\n"
                }
            }
        }else if currentPage == "Music"{ //MUSIC PAGE HANDLER
            for line in displayManager.musicDisplay() {
                textOutput += line + "\n"
            }
        }else if currentPage == "RearView"{
            
            textOutput = "To be implemented later, getting UI in place"
            
        }else if currentPage == "Calendar"{ //CALENDAR PAGE HANDLER
            for line in displayManager.calendarDisplay() {
                textOutput += line + "\n"
            }
        }else{
            textOutput = "No page selected"
        }
        return textOutput
    }
    
    func sendTextCommand(text: String = ""){
        if UInt8(self.counter) >= 255{
            self.counter = 0
        }
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

