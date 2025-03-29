import SwiftUI
import EventKit

struct ContentView: View {
    @State private var displayOn: Bool = true
    
    @StateObject private var displayManager = DisplayManager()
    @State private var currentPage = "Default"
    @StateObject private var bleManager = G1BLEManager()
    @State private var counter: CGFloat = 0
    @State private var totalCounter: CGFloat = 0
    
    @StateObject private var musicMonitor = MusicMonitor()
    
    @State private var time = Date().formatted(date: .omitted, time: .shortened)
    @State private var timer: Timer?
    
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var authorizationStatus: String = "Checking..."
    
    @State private var curSong: Song = Song(title: "", artist: "", album: "", duration: .zero, currentTime: .zero)
    @State private var progressBar: Double = 0.0
    @State private var events: [EKEvent] = []
    
    @State private var primaryColor: Color = Color(red: 10/255, green: 25/255, blue: 10/255)
    @State private var secondaryColor: Color = Color(red: 150/255, green: 255/255, blue: 150/255)
    
    private let daysOfWeek: [String] = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    let formatter = DateFormatter()
    
    var body: some View {
        let darkMode: Bool = (colorScheme == .dark)
        
        NavigationStack {
            List {
                HStack {
                    Spacer()
                    VStack {
                        Text(time)
                        HStack {
                            ForEach(daysOfWeek, id: \.self) { day in
                                if day == displayManager.getTodayWeekDay() {
                                    Text(day).bold().padding(0)
                                } else {
                                    Text(day).padding(-1)
                                }
                            }
                        }
                    }
                    Spacer()
                }
                
                // Current playing music plus progress bar
                VStack(alignment: .leading) {
                    Text(curSong.title).font(.headline)
                    HStack {
                        Text(curSong.album).font(.subheadline)
                        Text(curSong.artist).font(.subheadline)
                    }
                    HStack {
                        ProgressView(value: max(0.0, min(1.0, progressBar)))
                                    .onReceive(musicMonitor.$curSong) { song in
                                        // Update progress bar when song changes
                                        progressBar = song.progress
                                    }
                        Text("\(curSong.duration.formatted(.time(pattern: .minuteSecond)))").font(.caption)
                    }
                }
                
                Text("Calendar events").font(.headline)
                if isLoading {
                    ProgressView("Loading events...")
                } else {
                    ForEach(events, id: \.eventIdentifier) { event in
                        VStack(alignment: .leading) {
                            Text(event.title)
                                .font(.caption)
                            
                            HStack {
                                Text(formatter.string(from: event.startDate)).font(.caption2)
                                Text("-")
                                Text(formatter.string(from: event.endDate)).font(.caption2)
                            }
                            .font(.caption)
                        }
                    }
                }
                
                Text("end calendar").font(.headline)
                
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
                }
            }
            .scrollContentBackground(.hidden)
            .background(LinearGradient(colors: darkMode ? [primaryColor, Color(red: 28/255, green: 28/255, blue: 30/255)] : [secondaryColor, .white], startPoint: .bottom, endPoint: .top))
            .edgesIgnoringSafeArea(.bottom)
            .frame(width: 400)
        }
        .onAppear {
            displayManager.loadEvents()
            setupTimer()
        }
        .onDisappear {
            timer?.invalidate()
            bleManager.disconnect()
        }
    }
    
    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1/20, repeats: true) { _ in
            updateTimerData()
        }
    }
    
    private func updateTimerData() {
        // Update time
        time = Date().formatted(date: .omitted, time: .shortened)
        
        // Update music info
        curSong = musicMonitor.curSong
        progressBar = musicMonitor.curSong.progress
        
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
    
    func mainDisplayLoop() -> String{
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


#Preview {
    ContentView()
}

