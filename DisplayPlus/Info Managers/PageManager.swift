//
//  DisplayManager.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/13/25.
//

import Foundation
import SwiftUI
import Combine
import EventKit
import CoreLocation
import MapKit
import OpenMeteoSdk


class PageManager: ObservableObject {
    var timer: Timer?
    
    var rm = RenderingManager() //Has all measurements from calibration
    let displayWidth: CGFloat = 100.0
    
    //Info manager
    var info: InfoManager
    
    var songProgAsBars: String = ""
    
    public var mirror: Bool = false
    
    @AppStorage("currentPage", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var currentPage = "Default"
    
    var currentDisplayLines: [String] = []
    
    init(info: InfoManager){
        self.info = info
    }
    
    func header(mirror: Bool = false) -> String {
        currentDisplayLines.removeAll()
        currentDisplayLines.append("")

        return centerText(text: ("\(info.getTime()) | \(info.getTodayDate()) | Phone - \(info.getBattery())% \(info.getCurrentTemp() != 0 ? ("| \(info.getCurrentTemp())°F") : "")"))
    }
    
    func defaultDisplay() -> [String] {
        return(currentDisplayLines)
    }
    
    func musicDisplay() -> [String]{
        let curSong = info.getCurSong()
        var artist: String = curSong.artist
        var title: String = curSong.title
        
//        print("Title: \(title), Artist: \(artist)")
//        print(rm.getWidth(text: "\(title) - \(artist)"))
//        print("Fits on screen: \(rm.doesFitOnScreen(text: "\(title) - \(artist)"))")
        
        if !rm.doesFitOnScreen(text: "\(title) - \(artist)") {
            let separator = " - "
            let separatorWidth = rm.getWidth(text: separator)
            let ellipsis = "..."
            let ellipsisWidth = rm.getWidth(text: ellipsis)
            
            let maxArtistWidth = displayWidth * 0.7
            
            do {
                // 1. Shorten artist ONLY if it's longer than 70% of the screen
                if rm.getWidth(text: artist) > maxArtistWidth {
                    let newArtistLength = findBestFit(text: artist, availableWidth: maxArtistWidth - ellipsisWidth)
                    artist = String(artist.prefix(newArtistLength)) + ellipsis
                }
                
                // 2. Calculate available width for title based on the (potentially shortened) artist
                let availableTitleWidth = displayWidth - rm.getWidth(text: artist) - separatorWidth
                
                // 3. Shorten title if it doesn't fit in the remaining space
                if rm.getWidth(text: title) > availableTitleWidth {
                    let newTitleLength = findBestFit(text: title, availableWidth: availableTitleWidth - ellipsisWidth)
                    title = String(title.prefix(newTitleLength)) + ellipsis
                }
            } catch {
                print("Error fitting text: \(error)")
            }
        }
        
        currentDisplayLines.append((centerText(text: "\(title)\(artist.isEmpty ? "" : " - ")\(artist)"))) //Appending song info
        
        if !curSong.isPaused{
            let duration = String(describing: Duration.seconds(curSong.duration).formatted(.time(pattern: .minuteSecond)))
            let currentTime = String(describing: Duration.seconds(curSong.currentTime).formatted(.time(pattern: .minuteSecond)))
            
            let progressBar = progressBar(percentDone: curSong.percentagePlayed ,value: curSong.currentTime, max: curSong.duration)
            currentDisplayLines.append(centerText(text:"\(currentTime) \(progressBar) \(duration)"))
        }else{
            currentDisplayLines.append(centerText(text: "--Paused--"))
        } //Hiding progress bar if song is paused, showing paused text
        
        return currentDisplayLines
    }
    
    func calendarDisplay() -> [String]{
        if (info.getEvents().count != 0) {
            for event in info.eventsFormatted {
                let title = (event.titleLine.count > 25 ? (String(event.titleLine.prefix(25)) + "...") : event.titleLine)
                currentDisplayLines.append(centerText(text: "\(title)"))
                currentDisplayLines.append(centerText(text: (event.subtitleLine)))
            }
        }else{
            currentDisplayLines.append(centerText(text: "No events"))
        }
        return currentDisplayLines
    }
    
    /*
    func debugDisplay(index: Int) -> [String] {
        currentDisplayLines.removeAll()
        let offsetIndex = index + 31
        
        
        if rm.key != nil {
            
            currentDisplayLines.append(String(repeating: selectedChar, count: keys[keys[offsetIndex]] ))
            currentDisplayLines.append(String(repeating: keys[offsetIndex+31], count: 80))
            
        }else{
            currentDisplayLines.append("No key found")
            print("rm.key is nil, UserDefaults empty")
        } //Printing out full row of character,
        
        return currentDisplayLines
    }
     */
    
    func progressBar(percentDone: CGFloat, value: CGFloat, max: CGFloat) -> String {
        var fullBar: String = ""
        let percentage = percentDone
        
        do {
            let constantWidth = CGFloat(rm.getWidth(text: "\(Duration.seconds(Double(value)).formatted(.time(pattern: .minuteSecond))) [|] \(Duration.seconds(Double(max)).formatted(.time(pattern: .minuteSecond)))")) //Constant characters in the progress bar
            
            let workingWidth = (displayWidth-constantWidth)
            
            let percentCompleted = workingWidth * percentage
            let percentRemaining = workingWidth * (1.0-percentage)
            
            let completed = String(repeating: "-", count: Int((percentCompleted / rm.getWidth(text: "-"))))
            let remaining = String(repeating: "_", count: Int((percentRemaining / rm.getWidth(text: "_", overrideProgressBar: mirror))))
            fullBar = "[" + completed + "|" + remaining + "]"
        } catch {
            print("Error creating progress bar: \(error)")
        }
        
        
        return fullBar
    }
    
    func centerText(text: String) -> String {
        if mirror {
            return text
        } else {
            let widthOfText = rm.getWidth(text: text)
            
            let widthRemaining: CGFloat = max(0, displayWidth-widthOfText)
            let padding = String(repeating: " ", count: Int(widthRemaining/rm.getWidth(text: " "))/2)
            
            let FinalText = padding + text
            return FinalText
        }
    }
    
    func findBestFit(text: String, availableWidth: CGFloat) -> Int {
        var lowerBound = 0
        var upperBound = text.count
        var bestFit = 0

        while lowerBound <= upperBound {
            let mid = (lowerBound + upperBound) / 2
            let prefix = String(text.prefix(mid))
            if rm.getWidth(text: prefix) <= availableWidth {
                bestFit = mid
                lowerBound = mid + 1
            } else {
                upperBound = mid - 1
            }
        }
        return bestFit
    }
}
