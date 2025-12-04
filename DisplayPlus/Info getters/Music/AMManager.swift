import Foundation
import MediaPlayer
import SwiftUI

class AMManager: MusicManager {
    static let shared = AMManager(iconIn: Image(systemName: "music.note"), nameIn: "Apple Music")
    
    private let player = MPMusicPlayerController.systemMusicPlayer


    private var isObserving = false

    //MARK: - Music Observation and updating
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
        updateCurSong()
    }
    
    override func updateCurSong() {
        guard let item = player.nowPlayingItem else {
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
        
        // Determine whether the track actually changed (compare normalized metadata).
        // Compare against the current curSong (last known song).
        let songChanged = curSong.title != title || curSong.artist != artist || curSong.album != album
        
        updateCurSong(Song(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            currentTime: currentTime,
            isPaused: isPaused,
            songChanged: songChanged
        ))
    }

    override func getAuthStatus() -> Bool {
        let status = MPMediaLibrary.authorizationStatus()
        
        // If permission hasn't been determined yet, explicitly request it.
        // This triggers the system prompt.
        if status == .notDetermined {
            MPMediaLibrary.requestAuthorization { _ in
                // The next update cycle will pick up the new status
            }
        }

        if status == .authorized {
            startMusicObservation()
            return true
        }
        
        return false
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
