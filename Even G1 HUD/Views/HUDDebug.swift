import SwiftUI
import Combine
import MediaPlayer

struct HUDDebug: View {
    @State var time = Date().formatted(date: .omitted, time: .shortened)
    let musicMonitor = MusicMonitor()
    @State private var curSong = MusicMonitor.init().curSong
    @State private var timer: Timer? = nil
    @State private var progressBar: CGFloat = 0.0
    
    var body: some View {
        NavigationStack{
            VStack {
                List {
                    Text(time)
                    
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
                }
            }
        }
        .navigationTitle("Debug screen")
        .onAppear {
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
}
