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
    
    let formatter = DateFormatter()
    
    var body: some View {
        
        
        NavigationStack{
            VStack {
                List {
                    //Time
                    Text(time)
                    
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
        
        print("Starting to load events...")
        
        cal.fetchEventsForNextDay { result in
            DispatchQueue.main.async {
                isLoading = false
                updateAuthorizationStatus()
                
                switch result {
                case .success(let fetchedEvents):
                    print("Successfully fetched \(fetchedEvents.count) events")
                    events = fetchedEvents
                case .failure(let error):
                    print("Error fetching events: \(error)")
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
