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
    @Published var curSong: Song = Song(title: "", artist: "", album: "", bpm: 0, duration: .zero, currentTime: .zero)
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
        
        curSong = Song(title: nowPlayingItem?.title ?? "No Title",
                       artist: nowPlayingItem?.artist ?? "No Artist",
                       album: nowPlayingItem?.albumTitle ?? "No Album",
                       bpm: nowPlayingItem?.beatsPerMinute ?? 0,
                       duration: tempDuration,
                       currentTime: tempCurrentTime)
                    
        
    }
    deinit {
        player.endGeneratingPlaybackNotifications()
    }
}


struct Song{
    var title: String
    var artist: String
    var album: String
    var bpm: Int
    var duration: Duration
    var currentTime: Duration
}
