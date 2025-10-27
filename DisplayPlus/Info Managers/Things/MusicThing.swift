import Foundation
import SwiftUI

class MusicThing: Thing {
    var music: AMMonitor = AMMonitor()
    let rm = RenderingManager()
    
    var curSongForPreview: Song
    
    var artistLine: String = ""
    
    init(name: String, size: String = "Small", curSong: Song = Song(title: "No Song", artist: "No Artist", album: "No Album", duration: 0, currentTime: 0, isPaused: true, songChanged: false)) {
        curSongForPreview = curSong
        
        super.init(name: name, type: "Music", thingSize: size)
    }
    
    required init(from decoder: Decoder) throws {
        curSongForPreview = Song(title: "No Song", artist: "No Artist", album: "No Album", duration: 0, currentTime: 0, isPaused: true, songChanged: false)
        try super.init(from: decoder)
    }
    
    override func update() {
        if isNotPhone() {
            music.curSong = Song(title: "Preview Song Title", artist: "Preview Artist Name", album: "Preview Album", duration: 240, currentTime: 120, isPaused: false, songChanged: true)
            updated = true
        }else {
            if getAuthStatus() {
//                print("Updating music info...\n")
                music.updateCurrentSong()
//                print("Music info updated.")
//                print("Title: \(music.curSong.title), Duration: \(music.curSong.duration), Current Time: \(music.curSong.currentTime), Is Paused: \(music.curSong.isPaused), Song Changed: \(music.curSong.songChanged)\n")
                
                if music.curSong.title != music.curSong.title || music.curSong.isPaused != music.curSong.isPaused || music.curSong.currentTime != music.curSong.currentTime {
                    updated = true
                }
            }
        }
    }
    
    func setCurSong(song: Song) {
        music.curSong = song
    }
    
    func getTitle() -> String {
        return music.curSong.title
    }
    func getArtist() -> String {
        return music.curSong.artist
    }
    func getAlbum() -> String {
        return music.curSong.album
    }
    func getCurSong() -> Song {
        return music.curSong
    }
    
    override func getAuthStatus() -> Bool {
        return music.getAuthStatus() // Return the music authorization status
    }
    
    func buildArtistLine(widthIn: CGFloat = 100.0, curSongIn: Song) -> String {
        var doesFitOnScreen = rm.doesFitOnScreen(text: "\(curSongIn.title) - \(curSongIn.artist)", maxWidth: widthIn)
        var title: String = {
            if tm.getWidth(curSongIn.title) > 75 || (tm.getWidth(curSongIn.title) > (widthIn * 0.5) && !doesFitOnScreen) {
                let fullArtist = curSongIn.title
                let output: String = fullArtist.components(separatedBy: " (")[0]
                
                return output
            } else {
                return curSongIn.title
            }
        }()
        var artist: String = {
            if tm.getWidth(curSongIn.artist) > 80 {
                let fullArtist = curSongIn.artist
                let output: String = fullArtist.components(separatedBy: ", ")[0]
                
                return output
            } else {
                return curSongIn.artist
            }
        }()
        
        
        if widthIn >= 30 {
            if !doesFitOnScreen {
                let separator = " - "
                let ellipsis = "..."
                
                // Cache widths used multiple times
                let separatorWidth = rm.getWidth(text: separator)
                let ellipsisWidth = rm.getWidth(text: ellipsis)
                var maxArtistWidth: CGFloat = 0.0
                
                if widthIn == 100.0 {
                    maxArtistWidth = widthIn * 0.7
                } else {
                    maxArtistWidth = widthIn * 0.5
                }
                
                var artistWidth = rm.getWidth(text: artist)
                let titleWidth = rm.getWidth(text: title)
                
                // 1. Shorten artist ONLY if it's longer than 70% of the screen
                if artistWidth > maxArtistWidth {
                    let newArtistLength = tm.findBestFit(artist, availableWidth: maxArtistWidth - ellipsisWidth)
                    if newArtistLength < artist.count { // only mutate if actually shorter
                        artist = String(artist.prefix(newArtistLength)) + ellipsis
                        artistWidth = rm.getWidth(text: artist) // update cached width after mutation
                    }
                }
                
                // 2. Calculate available width for title based on the (potentially shortened) artist
                let availableTitleWidth = widthIn - artistWidth - separatorWidth
                
                // 3. Shorten title if it doesn't fit in the remaining space
                if titleWidth > availableTitleWidth {
                    let newTitleLength = tm.findBestFit(title, availableWidth: availableTitleWidth - ellipsisWidth)
                    if newTitleLength < title.count { // only mutate if actually shorter
                        title = String(title.prefix(newTitleLength)) + ellipsis
                        // titleWidth = rm.getWidth(text: title) // not needed later, so skip recompute
                    }
                }
            }
            artistLine = "\(title)\(artist.isEmpty ? "" : " - ")\(artist)"
            doesFitOnScreen = rm.doesFitOnScreen(text: "\(title) - \(artist)", maxWidth: widthIn)
            music.curSong.songChanged = false // Reset change flag after rebuilding
        } else {
            var titleShortened = false
            while tm.getWidth(title) > widthIn {
                title = String(title.prefix(title.count - 1))
                titleShortened = true
            }
            if titleShortened {
                title += "..."
            }
            artistLine = title
            
        }
        return artistLine
    }
    
    
    override func toString(mirror: Bool = false) -> String {
        let curSongTemp: Song = {
            if isNotPhone() {
                return curSongForPreview
            } else {
                return music.curSong
            }
        }()
        
        if size == "Medium" {
            var output: String = ""
            
            if curSongTemp.isPaused {
                return ("~ l> Paused ~")
            } else {
                let temp = buildArtistLine(widthIn: 40, curSongIn: curSongTemp)
                output = "\(temp)"
                
                return output
            }
        }
        else if size == "Large" {
            var output: String = ""
            
            let temp = buildArtistLine(widthIn: 50, curSongIn: curSongTemp)
            output = "\(temp)  ll  "
            
            output += (String(describing: Duration.seconds(curSongTemp.currentTime).formatted(.time(pattern: .minuteSecond))) + " ")
            
            let outputWidth = tm.getWidth(output)
            
            let totalTime = (" " + String(describing: Duration.seconds(curSongTemp.duration).formatted(.time(pattern: .minuteSecond))))
            let totalTimeWidth = tm.getWidth(" \(totalTime)")
            
            if curSongTemp.isPaused {
                return ("~ l> Paused ~")
            } else {
                let progBar = tm.progressBar(percentDone: curSongTemp.percentagePlayed, value: curSongTemp.currentTime, max: curSongTemp.duration, displayWidth: 100-outputWidth-totalTimeWidth)
                output += progBar
                output += totalTime
            }
            
            return output
            
        }
        else if size == "XL" {
            var output: String = ""
            output += buildArtistLine(curSongIn: curSongTemp)
            
            output += "\n"
            let duration = String(describing: Duration.seconds(curSongTemp.duration).formatted(.time(pattern: .minuteSecond)))
            let currentTime = String(describing: Duration.seconds(curSongTemp.currentTime).formatted(.time(pattern: .minuteSecond)))
                      
            if curSongTemp.isPaused {
                output += ("~ l> Paused ~")
            }else{
                let progressBar = tm.progressBar(percentDone: curSongTemp.percentagePlayed ,value: curSongTemp.currentTime, max: curSongTemp.duration)
                output += "\(currentTime) \(progressBar) \(duration)"
            }

            return output
        }
        else {
            return "Incorrect size input for Music thing: \(size), must be Medium, Large, or XL"
        }
    }
    
    private func settingsPage() -> some View {
        ScrollView(.vertical) {
            HStack {
                Text("No settings available for Music Thing")
            }
            .settingsItem(themeIn: theme)
        }
        .navigationTitle("Music Settings")
    }
    override func getSettingsView() -> AnyView {
        AnyView(
            NavigationStack {
                ZStack {
                    //backgroundGrid(themeIn: theme)
                    (theme.darkMode ? theme.backgroundDark : theme.backgroundLight)
                        .ignoresSafeArea()
                    VStack{
                        HStack {
                            Text("Music Thing Settings")
                            Spacer()
                            Text("|")
                            NavigationLink {
                                settingsPage()
                            } label: {
                                Image(systemName: "arrow.right.square.fill")
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 24)
                            .font(.system(size: 24))
                            .mainButtonStyle(themeIn: theme)
                        }
                        .settingsItem(themeIn: theme)
                    }
                }
            }
        )
    }
}

