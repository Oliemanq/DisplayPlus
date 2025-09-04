import Foundation
import Combine
import MediaPlayer
import CoreGraphics

class AMMonitor: ObservableObject {
    private let player = MPMusicPlayerController.systemMusicPlayer
    
    @Published var curSong: Song = Song(title: "", artist: "", album: "", duration: 0, currentTime: 0, isPaused: true, isMixing: false)
    
    private var timer: AnyCancellable?

    private func startMusicObservation() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(nowPlayingItemChanged),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: player
        )
        
        player.beginGeneratingPlaybackNotifications()
    }
    
    @objc private func nowPlayingItemChanged() {
        updateCurrentSong()
    }

    public func updateCurrentSong() {
        guard let item = player.nowPlayingItem else {
            // If no item, reset to an empty/paused Song on main thread
            DispatchQueue.main.async {
                self.curSong = Song(title: "", artist: "", album: "", duration: 0, currentTime: 0, isPaused: true, isMixing: false)
            }
            return
        }
        
        let title = item.title ?? "No Title"
        let artist = item.artist ?? "No Artist"
        let album = item.albumTitle ?? "No Album"
        
        // Sanitize duration and currentTime. AutoMix / crossfade can return NaN, infinite, or negative values.
        var duration = item.playbackDuration
        if !duration.isFinite || duration <= 0 {
            duration = 0.0001
        }
        
        var currentTime = player.currentPlaybackTime
        if !currentTime.isFinite || currentTime <= 0 {
            currentTime = 0.0001
        }
        
        // Treat anything other than .playing as paused for safety
        let isPaused = (player.playbackState == .paused)
        
        var isMixing: Bool
        if player.currentPlaybackRate != 1.0 || player.playbackState == .seekingForward || player.playbackState == .seekingBackward {
            isMixing = true
            print("MIXING ------- \(player.currentPlaybackRate)")
        } else {
            isMixing = false
        }

        // Ensure we publish on the main thread
        DispatchQueue.main.async {
            self.curSong = Song(
                title: title,
                artist: artist,
                album: album,
                duration: duration,
                currentTime: currentTime,
                isPaused: isPaused,
                isMixing: isMixing
            )
        }
    }
    
    func getAuthStatus() -> Bool {
        startMusicObservation()
        
        return MPMediaLibrary.authorizationStatus() == .authorized
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
    var isMixing: Bool
    
    var percentagePlayed: Double {
        // Make percentage calculation robust against invalid durations/currentTime
        let safeDuration = (duration.isFinite && duration > 0) ? duration : 0
        guard safeDuration > 0 else { return 0 }
        // Force safeCurrent strictly less than safeDuration to avoid exact-1.0 results
        let epsSmall: TimeInterval = 1e-6
        let safeCurrentRaw = currentTime.isFinite ? max(0, min(currentTime, safeDuration)) : 0
        let safeCurrent = min(safeCurrentRaw, safeDuration - epsSmall)
        let raw = safeCurrent / safeDuration
        // Clamp to [0, ~1) — avoid returning exact 1.0 which some consumers mishandle
        return min(0.999999, max(0.0, raw))
    }
}
