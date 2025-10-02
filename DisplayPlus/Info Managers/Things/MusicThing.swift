import Foundation

class MusicThing: Thing {
    var music: AMMonitor = AMMonitor()
    let rm = RenderingManager()
    
    var artistLine: String = ""
    
    init(name: String, size: String = "Small") {
        super.init(name: name, type: "Music", thingSize: size)
    }
    
    override func update() {
        if isNotPhone() {
            music.curSong = Song(title: "Preview Song Title", artist: "Preview Artist Name", album: "Preview Album", duration: 240, currentTime: 120, isPaused: false, songChanged: true)
            updated = true
        }else {
            if getAuthStatus() {
                music.updateCurrentSong()
                
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
    
    func buildArtistLine(widthIn: CGFloat = 100.0) -> String {
        var title = music.curSong.title
        var artist = music.curSong.artist
        let displayWidth: CGFloat = widthIn
                
        if music.curSong.songChanged {
            print("Song changed, rebuilding artist line\n")
            if displayWidth >= 30 {
                if rm.doesFitOnScreen(text: "\(title) - \(artist)") {
                    let separator = " - "
                    let ellipsis = "..."
                    
                    // Cache widths used multiple times
                    let separatorWidth = rm.getWidth(text: separator)
                    let ellipsisWidth = rm.getWidth(text: ellipsis)
                    let maxArtistWidth = displayWidth * 0.7
                    
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
                    let availableTitleWidth = displayWidth - artistWidth - separatorWidth
                    
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
            } else {
                var titleShortened = false
                while tm.getWidth(title) > displayWidth {
                    title = String(title.prefix(title.count - 1))
                    titleShortened = true
                }
                if titleShortened {
                    title += "..."
                }
                artistLine = title
            }
        }
        return artistLine
    }
    
    
    override func toString() -> String {
        if thingSize == "Small" {
            if music.curSong.isPaused {
                return "♪\\0-0/♪ (Paused)"
            } else {
                return  "♪\\0-0/♪ \(buildArtistLine(widthIn: 20.0))"
            }
        } else if thingSize == "Medium" {
            var tempTitle = music.curSong.title
            var titleChanged: Bool = false
            var tempArtist = music.curSong.artist
            var artistChanged: Bool = false
            
            var output: String = ""
            
            if music.curSong.isPaused {
                return tm.centerText("♪\\0-0/♪ (Paused)")
            } else {
                while tm.getWidth(tempTitle) > 30 {
                    tempTitle = String(tempTitle.prefix(tempTitle.count - 1))
                    titleChanged = true
                }
                while tm.getWidth(tempArtist) > 30 {
                    tempArtist = String(tempArtist.prefix(tempArtist.count - 1))
                    artistChanged = true
                }
                if titleChanged {
                    tempTitle += "..."
                }
                if artistChanged {
                    tempArtist += "..."
                }
                output = "♪\\0-0/♪ \(tempTitle) - \(tempArtist)"
                
                
                let progBar = tm.progressBar(percentDone: music.curSong.percentagePlayed, value: music.curSong.currentTime, max: music.curSong.duration, displayWidth: 100.0-tm.getWidth(output))
                output += progBar
                
                return output
            }
        } else if thingSize == "Big" {
            var output: String = ""
            output += tm.centerText(buildArtistLine())
            output += "\n"
            output += tm.centerText("\(tm.progressBar(percentDone: music.curSong.percentagePlayed, value: music.curSong.currentTime, max: music.curSong.duration, displayWidth: 100.0))")
            
            return output
        } else {
            return "INPUT CORRECT SIZE (Small/Medium/Big)"
        }
    }
}
