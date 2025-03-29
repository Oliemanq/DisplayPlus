//
//  MusicMonitor.swift
//  RhythmGameTest
//
//  Created by Oliver Heisel on 2/3/25.
//
import MediaPlayer
import SwiftUI
import Foundation
import SwiftData
import Combine

class MusicMonitor: ObservableObject {
    private let player = MPMusicPlayerController.systemMusicPlayer
    @Published var curSong: Song = Song(
            title: "No Song Playing",
            artist: "",
            album: "",
            duration: Duration.seconds(0),
            currentTime: Duration.seconds(0)
        )
    private var songMatch: Bool = false
    
    
    init() {// Rest of your init code
        NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: player,
            queue: OperationQueue.main) { [weak self] (note) in
                self?.updateCurrentSong()
            }
        
        player.beginGeneratingPlaybackNotifications()
        updateCurrentSong()
    }
    
    
    public func updateCurrentSong() {
        let nowPlayingItem = player.nowPlayingItem
        let tempDuration = Duration(
            secondsComponent: Int64(nowPlayingItem?.playbackDuration ?? .zero),
            attosecondsComponent: 0
        )
        let tempCurrentTime = Duration(
            secondsComponent: Int64(player.currentPlaybackTime),
            attosecondsComponent: 0
        )
        let safeCurrentTime = min(tempCurrentTime, tempDuration)
        
        curSong = Song(title: nowPlayingItem?.title ?? "No Title",
                       artist: nowPlayingItem?.artist ?? "No Artist",
                       album: nowPlayingItem?.albumTitle ?? "No Album",
                       duration: tempDuration,
                       currentTime: safeCurrentTime)
    }
    
    func updateCurrentSong(_ newSong: Song) {
            curSong = newSong
    }
    
    deinit {
        player.endGeneratingPlaybackNotifications()
    }
}


struct Song{
    var title: String
    var artist: String
    var album: String
    var duration: Duration
    var currentTime: Duration
    
    var progress: Double {
        guard duration.components.seconds > 0 else { return 0.0 }
            return max(0.0, min(1.0, currentTime / duration))
        }
}
