import SwiftUI
import EventKit

struct ContentView: View {
    @State public var displayOn: Bool = false
    
    @StateObject private var displayManager = DisplayManager()
    @State private var currentPage = "Default"
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
            .init(iconSystemName: "music.note.list", extraText: "Music screen", action: {}),
            .init(iconSystemName: "arrow.trianglehead.2.clockwise.rotate.90.camera.fill", extraText: "RearView", action: {}),
            .init(iconSystemName: "clock", extraText: "Default screen", action: {})
            
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

                            ProgressView(value: musicMonitor.curSong.currentTime / musicMonitor.curSong.duration, total: 1).tint(!darkMode ? primaryColor : secondaryColor)
                            
                            Text("\(formattedduration)")
                                .font(.caption)
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)

                        }
                    }
                    
                    
                    Text("Calendar events")
                        .font(.headline)
                        .foregroundStyle(!darkMode ? primaryColor : secondaryColor)

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
                        }
                    }
                    
                    Text("end calendar")
                        .font(.headline)
                        .foregroundStyle(!darkMode ? primaryColor : secondaryColor)

                    
                    Spacer()
                    
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
                        
                    }
                    
                    HStack{
                        Spacer()
                        Button(displayOn ? "Turn display off" : "Turn display on"){
                            displayOn.toggle()
                            print(String(displayOn))
                            sendTextCommand()
                        }
                        .padding(2)
                        .frame(width: 150, height: 30)
                        .background((!darkMode ? primaryColor : secondaryColor))
                        .foregroundColor(darkMode ? primaryColor : secondaryColor)
                        .buttonStyle(.borderless)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                    }
                    
                    HStack{
                        Spacer()
                        Button("Cycle through pages\nCurrent page: \(currentPage)"){
                            if currentPage == "Default"{
                                currentPage = "Music"
                                displayManager.currentPage = "Music"
                                
                                let currentDisplay = mainDisplayLoop()
                                sendTextCommand(text: currentDisplay)
                            }else if currentPage == "Music"{
                                currentPage = "Default"
                                displayManager.currentPage = "Default"
                                
                                let currentDisplay = mainDisplayLoop()
                                sendTextCommand(text: currentDisplay)
                            }
                        }
                        .padding(2)
                        .frame(width: 200, height: 60)
                        .background((!darkMode ? primaryColor : secondaryColor))
                        .foregroundColor(darkMode ? primaryColor : secondaryColor)
                        .buttonStyle(.borderless)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    HStack{
                        Spacer()
                        Text("Connection status: \(bleManager.connectionStatus)")
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                    }
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
            displayManager.loadEvents()
            timer = Timer.scheduledTimer(withTimeInterval: 1/20, repeats: true) { _ in
                // Update time
                time = Date().formatted(date: .omitted, time: .shortened)
                
                
                
                // Update events
                events = displayManager.getEvents()
                
                counter += 1
                totalCounter += 1
                
                displayManager.updateHUDInfo()
                
                if displayOn {
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
        print("mainDisplayLoop() ran")
        var textOutput: String = ""
        
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
        }else{
            return "No page selected"
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

