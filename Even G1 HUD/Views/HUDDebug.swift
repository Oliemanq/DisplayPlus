import SwiftUI
import EventKit
import Combine
import MediaPlayer

struct HUDDebug: View {
    @State var time = Date().formatted(date: .omitted, time: .shortened)
    @State private var curSong = MusicMonitor.init().curSong
    @State private var timer: Timer? = nil
    @State private var progressBar: CGFloat = 0.0
    
    let musicMonitor = MusicMonitor()
    
    @State private var events: [EKEvent] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var authorizationStatus: String = "Checking..."

    
    private let cal = CalendarManager()
    private let daysOfWeek: [String] = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    let formatter = DateFormatter()
    
    var body: some View {
        
        
        NavigationStack{
            VStack {
                List {
                    //Time
                    VStack{
                        Text(time)
                        HStack{
                            ForEach(daysOfWeek, id: \.self) { day in
                                if day == getTodayWeekDay() {
                                    Text(day).bold().padding(0).frame(width: 30, height: 20).overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(Color.black, lineWidth: 1))
                                }else{
                                    Text(day).padding(-1)
                                }
                            }
                        }
                    }
                    //Current playing music plus progress bar
                    VStack(alignment: .leading){
                        Text(curSong.title).font(.headline)
                        HStack{
                            Text(curSong.album).font(.subheadline)
                            Text(curSong.artist).font(.subheadline)
                        }
                        HStack{
                            ProgressView(value: progressBar)
                            Text(String(describing: curSong.duration.formatted(.time(pattern: .minuteSecond)))).font(.caption)
                        }
                    }
                    Text("Calendar events").font(.headline)
                    if isLoading {
                        ProgressView("Loading events...")
                    } else {
                        // Use ForEach with proper event data handling
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
                }
            }
        }
        .navigationTitle("Debug screen")
        .onAppear {
            self.formatter.timeStyle = .short
            loadEvents()
            
            // Create and store the timer
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                self.time = Date().formatted(date: .omitted, time: .shortened)
                self.musicMonitor.updateCurrentSong()
                self.curSong = self.musicMonitor.curSong
                self.progressBar = CGFloat(self.curSong.currentTime / self.curSong.duration)
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    private func updateAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized: authorizationStatus = "Authorized"
        case .denied: authorizationStatus = "Denied"
        case .notDetermined: authorizationStatus = "Not Determined"
        case .restricted: authorizationStatus = "Restricted"
        case .fullAccess: authorizationStatus = "Full Access"
        case .writeOnly: authorizationStatus = "Write Only"
        @unknown default: authorizationStatus = "Unknown"
        }
    }
    
    
    private func loadEvents() {
        isLoading = true
        errorMessage = nil
                
        cal.fetchEventsForNextDay { result in
            DispatchQueue.main.async {
                isLoading = false
                updateAuthorizationStatus()
                
                switch result {
                case .success(let fetchedEvents):
                    events = fetchedEvents
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    func getTodayWeekDay()-> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        let weekDay = dateFormatter.string(from: Date())
        return weekDay
    }
}
