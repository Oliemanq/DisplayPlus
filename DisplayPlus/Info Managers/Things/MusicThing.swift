import Foundation

class MusicThing: Thing {
    var music: AMMonitor = AMMonitor()
    let rm = RenderingManager()
    
    var artistLine: String = ""
    
    init(name: String, size: String = "Small") {
        super.init(name: name, type: "Music", thingSize: size)
    }
    
    required init(from decoder: Decoder) throws {
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
    
    func buildArtistLine(widthIn: CGFloat = 100.0) -> String {
        var doesFitOnScreen = rm.doesFitOnScreen(text: "\(self.music.curSong.title) - \(self.music.curSong.artist)", maxWidth: widthIn)
        var title: String = {
            if tm.getWidth(self.music.curSong.title) > 75 || (tm.getWidth(self.music.curSong.title) > (widthIn * 0.5) && !doesFitOnScreen) {
                let fullArtist = self.music.curSong.title
                let output: String = fullArtist.components(separatedBy: " (")[0]
                
                return output
            } else {
                return self.music.curSong.title
            }
        }()
        var artist: String = {
            if tm.getWidth(self.music.curSong.artist) > 80 {
                let fullArtist = self.music.curSong.artist
                let output: String = fullArtist.components(separatedBy: ", ")[0]
                
                return output
            } else {
                return self.music.curSong.artist
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
        if size == "Medium" {
            var output: String = ""
            
            if music.curSong.isPaused {
                return tm.centerText("~ l> Paused ~")
            } else {
                let temp = buildArtistLine(widthIn: 40)
                output = "\(temp)"
                
                return output
            }
        }
        else if size == "Large" {
            var output: String = ""
            
            
            let temp = buildArtistLine(widthIn: 50)
            output = "\(temp)  ll  "
            
            output += (String(describing: Duration.seconds(music.curSong.currentTime).formatted(.time(pattern: .minuteSecond))) + " ")
            
            let outputWidth = tm.getWidth(output)
            
            let totalTime = (" " + String(describing: Duration.seconds(music.curSong.duration).formatted(.time(pattern: .minuteSecond))))
            let totalTimeWidth = tm.getWidth(" \(totalTime)")
            
            if music.curSong.isPaused {
                return "~ l> Paused ~"
            } else {
                let progBar = tm.progressBar(percentDone: music.curSong.percentagePlayed, value: music.curSong.currentTime, max: music.curSong.duration, displayWidth: 100-outputWidth-totalTimeWidth, mirror: mirror)
                output += progBar
                output += totalTime
            }
            
            return output
            
        }
        else if size == "XL" {
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
            return "Incorrect size input for Music thing: \(size), must be Medium, Large, or XL"
        }
    }
}

