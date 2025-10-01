import Foundation

class MusicThing: Thing {
    var music: AMMonitor = AMMonitor()
    let rm = RenderingManager()
    
    init(name: String) {        
        super.init(name: name, type: "Music")
    }
    
    override func update() {
        if getAuthStatus() {
            music.updateCurrentSong()
            
            if music.curSong.title != music.curSong.title || music.curSong.isPaused != music.curSong.isPaused || music.curSong.currentTime != music.curSong.currentTime {
                updated = true
            }
        }
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
    
    func buildArtistLine() -> String {
        var title = music.curSong.title
        var artist = music.curSong.artist
        let displayWidth: CGFloat = 100.0
                
        print("Song changed, rebuilding artist line\n")
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
        return "\(title)\(artist.isEmpty ? "" : " - ")\(artist)"
    }
    
    
    override func toString() -> String {
        var output: String = ""
        output += buildArtistLine()
        output += "\n"
        output += tm.centerText(tm.progressBar(percentDone: music.curSong.percentagePlayed, value: music.curSong.currentTime, total: music.curSong.duration))
        
        return output
    }
}
