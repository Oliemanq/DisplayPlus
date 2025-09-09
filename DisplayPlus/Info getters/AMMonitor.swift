import Foundation
import MediaPlayer

@MainActor
class AMMonitor: ObservableObject {
    private let player = MPMusicPlayerController.systemMusicPlayer

    @Published var curSong: Song = Song.empty

    private var isObserving = false

    private func startMusicObservation() {
        guard !isObserving else { return }
        isObserving = true

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
            // If no item, reset to an empty/paused Song
            curSong = .empty
            return
        }

        let title = item.title ?? "No Title"
        let artist = item.artist ?? "No Artist"
        let album = item.albumTitle ?? "No Album"

        // Sanitize duration and currentTime. AutoMix / crossfade can return NaN, infinite, or negative values.
        let duration = sanitize(time: item.playbackDuration)
        let currentTime = sanitize(time: player.currentPlaybackTime)

        // Treat anything other than .playing as paused for safety
        let isPaused = (player.playbackState != .playing)

        curSong = Song(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            currentTime: currentTime,
            isPaused: isPaused
        )
    }

    func getAuthStatus() -> Bool {
        startMusicObservation()

        return MPMediaLibrary.authorizationStatus() == .authorized
    }

    deinit {
        if isObserving {
            NotificationCenter.default.removeObserver(self,
                                                      name: .MPMusicPlayerControllerNowPlayingItemDidChange,
                                                      object: player)
            player.endGeneratingPlaybackNotifications()
        }
    }

    // Helper to make time values safe
    private func sanitize(time: TimeInterval) -> TimeInterval {
        guard time.isFinite && time > 0 else { return 0 }
        return time
    }
}

struct Song{
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var currentTime: TimeInterval
    var isPaused: Bool

    static let empty = Song(title: "", artist: "", album: "", duration: 0, currentTime: 0, isPaused: true)

    var percentagePlayed: Double {
        guard duration.isFinite && duration > 0 else { return 0 }
        let clampedCurrent = currentTime.isFinite ? min(max(0, currentTime), duration) : 0
        let eps: TimeInterval = 1e-6
        let safeCurrent = min(clampedCurrent, duration - eps)
        let raw = safeCurrent / duration
        return min(0.999999, max(0.0, raw))
    }
}
