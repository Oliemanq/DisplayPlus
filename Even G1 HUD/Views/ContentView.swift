import SwiftUI
import EventKit

struct ContentView: View {
    @State public var displayOn: Bool = true
    
    @StateObject private var displayManager = DisplayManager()
    @State var textOutput: String = ""

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
            .init(iconSystemName: "music.note.list", extraText: "Music screen", action: {
                currentPage = "Music"
                print("Music page")
            }),
            .init(iconSystemName: "arrow.trianglehead.2.clockwise.rotate.90.camera.fill", extraText: "RearView", action: {
                currentPage = "RearView"
                print("RearView screen")
            }),
            .init(iconSystemName: "clock", extraText: "Default screen", action: {
                currentPage = "Default"
                print("Default screen")
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
                        VisualEffectView(effect: UIBlurEffect(style: darkMode ? .systemThinMaterialDark : .systemThinMaterialLight))
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
                                
                            if musicMonitor.curSong.duration != 0 {
                                ProgressView(value: musicMonitor.curSong.currentTime / musicMonitor.curSong.duration, total: 1).tint(!darkMode ? primaryColor : secondaryColor)
                            }
                            
                            Text("\(formattedduration)")
                                .font(.caption)
                                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)

                        }
                    }
                    .listRowBackground(
                        VisualEffectView(effect: UIBlurEffect(style: darkMode ? .systemThinMaterialDark : .systemThinMaterialLight))
                    )
                    
                    
                    Text("Calendar events")
                        .font(.headline)
                        .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                        .listRowBackground(
                            VisualEffectView(effect: UIBlurEffect(style: darkMode ? .systemThinMaterialDark : .systemThinMaterialLight))
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
                                VisualEffectView(effect: UIBlurEffect(style: darkMode ? .systemThinMaterialDark : .systemThinMaterialLight))
                            )
                        }
                    }
                    
                    Text("end calendar")
                        .font(.headline)
                        .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                        .listRowBackground(
                            VisualEffectView(effect: UIBlurEffect(style: darkMode ? .systemThinMaterialDark : .systemThinMaterialLight))
                        )

                    
                    Spacer()
                        .listRowBackground(
                            VisualEffectView(effect: UIBlurEffect(style: darkMode ? .systemThinMaterialDark : .systemThinMaterialLight))
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
                        VisualEffectView(effect: UIBlurEffect(style: darkMode ? .systemThinMaterialDark : .systemThinMaterialLight))
                    )
                    
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
                        
                    }.listRowBackground(
                        VisualEffectView(effect: UIBlurEffect(style: darkMode ? .systemThinMaterialDark : .systemThinMaterialLight))
                    )
                    
                    VStack{
                        Text(textOutput)
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                            .font(.system(size: 11))

                    }.listRowBackground(
                        VisualEffectView(effect: UIBlurEffect(style: darkMode ? .systemThinMaterialDark : .systemThinMaterialLight))
                    )
                    HStack{
                        Spacer()
                        Text("Connection status: \(bleManager.connectionStatus)")
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                    }.listRowBackground(
                        VisualEffectView(effect: UIBlurEffect(style: darkMode ? .systemThinMaterialDark : .systemThinMaterialLight))
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
            displayManager.loadEvents()
            events = displayManager.getEvents()
            
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                // Update time
                time = Date().formatted(date: .omitted, time: .shortened)
                
                if totalCounter.truncatingRemainder(dividingBy: 60) == 0 {
                    displayManager.loadEvents()
                }

                // Update events
                
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

