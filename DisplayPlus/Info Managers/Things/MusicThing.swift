import Foundation

class MusicThing: Thing {
    var music: AMMonitor = AMMonitor()
    let rm = RenderingManager()
    
    var artistLine: String = ""
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    init(name: String, size: String = "Small") {
        super.init(name: name, type: "Music", thingSize: size)
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
    
    func buildArtistLine(widthIn: CGFloat = 100.0) -> String {
        var title = music.curSong.title
        var artist = music.curSong.artist
        
        
        if widthIn >= 30 {
            if !rm.doesFitOnScreen(text: "\(title) - \(artist)", maxWidth: widthIn) {
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
        if thingSize == "Small" {
            if music.curSong.isPaused {
                return "♪\\0-0/♪ (Paused)"
            } else {
                return  "\(buildArtistLine(widthIn: 25.0))"
            }
        }
        else if thingSize == "Medium" {
            var output: String = ""
            
            if music.curSong.isPaused {
                return tm.centerText("♪\\0-0/♪ (Paused)")
            } else {
                let temp = buildArtistLine(widthIn: 40)
                output = "♪\\0-0/♪ \(temp)"
                
                return output
            }
        }
        else if thingSize == "Large" {
            var output: String = ""
            
            if music.curSong.isPaused {
                return tm.centerText("♪\\0-0/♪ (Paused)")
            } else {
                let temp = buildArtistLine(widthIn: 50)
                output = "\(temp)"
                
                
                let progBar = tm.progressBar(percentDone: music.curSong.percentagePlayed, value: music.curSong.currentTime, max: music.curSong.duration, displayWidth: 50, mirror: mirror)
                output += progBar
                
                return output
            }
        }
        else if thingSize == "XL" {
            var output: String = ""
            output += buildArtistLine()
            
            output += "\n"
            let duration = String(describing: Duration.seconds(music.curSong.duration).formatted(.time(pattern: .minuteSecond)))
            let currentTime = String(describing: Duration.seconds(music.curSong.currentTime).formatted(.time(pattern: .minuteSecond)))
                        
            let progressBar = tm.progressBar(percentDone: music.curSong.percentagePlayed ,value: music.curSong.currentTime, max: music.curSong.duration)

            output += "\(currentTime) \(progressBar) \(duration)"
            
            return output
        }
        else {
            return "INPUT CORRECT SIZE (Small/Medium/Large/XL)"
        }
    }
}

