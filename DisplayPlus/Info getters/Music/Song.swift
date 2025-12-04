import Foundation
import SwiftUI

// CHANGE: Inherit from NSObject
class MusicManager: NSObject, ObservableObject {
    var curSong: Song = .empty
    var prevSong: Song = .empty

    func updateCurSong() {
        print("Updating curSong with no input")
        print("TO BE IMPLEMENTED BY SUBCLASS")
    }
    
    func updateCurSong(_ songIn: Song) {
        // Optional: Add logging if needed
        // print("Updating curSong")
        prevSong = curSong
        curSong = songIn
    }
    
    func getCurSong() -> Song {
        curSong.songChanged = false
        return curSong
    }
    
    func getAuthStatus() -> Bool {
        print("AuthStatus called incorrectly from general class MusicGetter")
        return false
    }
}

struct Song {
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var currentTime: TimeInterval
    var isPaused: Bool
    var songChanged: Bool

    static let empty = Song(title: "", artist: "", album: "", duration: 0, currentTime: 0, isPaused: true, songChanged: false)

    var percentagePlayed: Double {
        guard duration.isFinite && duration > 0 else { return 0 }
        let clampedCurrent = currentTime.isFinite ? min(max(0, currentTime), duration) : 0
        let eps: TimeInterval = 1e-6
        let safeCurrent = min(clampedCurrent, duration - eps)
        let raw = safeCurrent / duration
        return min(0.999999, max(0.0, raw))
    }
}
