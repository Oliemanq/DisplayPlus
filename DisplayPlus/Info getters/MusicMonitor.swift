import Foundation
import Combine
import MediaPlayer

class MusicMonitor: ObservableObject {
    private let player = MPMusicPlayerController.systemMusicPlayer
    
    @Published var curSong: Song = Song(title: "", artist: "", album: "", duration: 0, currentTime: 0, isPaused: true)
    @Published var currentTime: Double = 0.0  // New separately published property
    
    private var timer: AnyCancellable?

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(nowPlayingItemChanged),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: player
        )
        
        player.beginGeneratingPlaybackNotifications()
        updateCurrentSong()

        // Timer to periodically update the current time
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.currentTime = self.player.currentPlaybackTime
            }
    }

    @objc private func nowPlayingItemChanged() {
        updateCurrentSong()
    }

    public func updateCurrentSong() {
        guard let item = player.nowPlayingItem else { return }
        
        let title = item.title ?? "No Title"
        let artist = item.artist ?? "No Artist"
        let album = item.albumTitle ?? "No Album"
        let duration = item.playbackDuration
        let currentTime = player.currentPlaybackTime
        let isPaused = player.playbackState == .paused

        curSong = Song(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            currentTime: currentTime,
            isPaused: isPaused
        )

        self.currentTime = currentTime  // Also update separately published property
    }

    deinit {
        player.endGeneratingPlaybackNotifications()
        timer?.cancel()
    }
}


struct Song{
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var currentTime: TimeInterval
    var isPaused: Bool
    
    var percentagePlayed: Double {
        return currentTime / duration
    }
}
