import Foundation
import SwiftUI

class SpotifyManager: MusicManager, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate {
    
    // Singleton instance to ensure one connection manager exists
    static let shared = SpotifyManager(iconIn: Image("SpotifyIcon"), nameIn: "Spotify")
    
    let spotifyClientID = "658f4243df2e439a86c8cf57074d853d"
    let spotifyRedirectURL = URL(string: "spotify-ios-quick-start://spotify-login-callback")!
    
    lazy var configuration = SPTConfiguration(
        clientID: spotifyClientID,
        redirectURL: spotifyRedirectURL
    )
    
    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: self.configuration, logLevel: .debug)
        appRemote.connectionParameters.accessToken = self.accessToken
        appRemote.delegate = self
        return appRemote
    }()
    
    private var accessToken: String?
    
    // MARK: - Auth & Connection
    
    func authorize() {
        if appRemote.isConnected {
            appRemote.disconnect()
        }
        // This initiates the app switch to Spotify to authorize
        appRemote.authorizeAndPlayURI("")
    }
    
    func handleOpenURL(_ url: URL) {
        let parameters = appRemote.authorizationParameters(from: url)
        
        if let access_token = parameters?[SPTAppRemoteAccessTokenKey] {
            appRemote.connectionParameters.accessToken = access_token
            self.accessToken = access_token
            appRemote.connect()
        } else if let error_description = parameters?[SPTAppRemoteErrorDescriptionKey] {
            print("Spotify Auth Error: \(error_description)")
        }
    }
    
    override func getAuthStatus() -> Bool {
        return appRemote.isConnected
    }

    // MARK: - SPTAppRemoteDelegate
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("Spotify Connected")
        
        // Subscribe to player state updates
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { (result, error) in
            if let error = error {
                print("Error subscribing to player state: \(error)")
            }
        })
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("Spotify Connection Failed: \(String(describing: error))")
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("Spotify Disconnected")
    }
    
    // MARK: - SPTAppRemotePlayerStateDelegate
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        let track = playerState.track
        
        let isMixing = playerState.playbackSpeed != 1.0
        
        let title = track.name
        let artist = track.artist.name
        let album = track.album.name
        let duration = Double(track.duration) / 1000.0 // Spotify uses ms
        let currentTime = Double(playerState.playbackPosition) / 1000.0
        let isPaused = playerState.isPaused
        
        // Determine if song changed
        let songChanged = (curSong.title != title || curSong.artist != artist)
        
        // Update the @Published curSong in the base class
        updateCurSong(Song(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            currentTime: currentTime,
            isPaused: isPaused,
            isMixing: isMixing,
            songChanged: songChanged
        ))
    }
    
    override func updateCurSong() {
        appRemote.playerAPI?.getPlayerState { [weak self] (result, error) in
            if let error = error {
                print("Error getting player state: \(error)")
                return
            }
            
            if let playerState = result as? SPTAppRemotePlayerState {
                self?.playerStateDidChange(playerState)
            }
        }
    }
}
