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
            var artistShortened = false
            var titleShortened = false
            
            let separatorWidth = rm.getWidth(text: " - ")
            let dotWidth = rm.getWidth(text: "...")
            
            // Iteratively shorten artist/title until it fits or strings are empty
            while true {
                let titleWidth = rm.getWidth(text: title)
                let artistWidth = rm.getWidth(text: artist)
                
                if titleWidth + artistWidth + dotWidth*2 <= displayWidth - separatorWidth {
                    break
                }
                
                // Prefer shortening the longer one first; keep artist above a small threshold before switching
                if artistWidth + dotWidth > 50, !artist.isEmpty {
                    artist = String(artist.dropLast())
                    artistShortened = true
                } else if !title.isEmpty {
                    title = String(title.dropLast())
                    titleShortened = true
                } else {
                    break
                }
            }
            
            if artistShortened {
                artist.append("...")
            }
            if titleShortened {
                title.append("...")
            }
        }
        
        currentDisplayLines.append((centerText(text: "\(title) - \(artist)"))) //Appening song info
        
        if !info.getCurSong().isPaused{
            let duration = String(describing: Duration.seconds(info.getCurSong().duration).formatted(.time(pattern: .minuteSecond)))
            let currentTime = String(describing: Duration.seconds(info.getCurSong().currentTime).formatted(.time(pattern: .minuteSecond)))
            
            let progressBar = progressBar(percentDone: info.getCurSong().percentagePlayed ,value: info.getCurSong().currentTime, max: info.getCurSong().duration, song: true, mixing: info.getCurSong().isMixing)
            currentDisplayLines.append(centerText(text:"\(info.getCurSong().isMixing ? "Mixing ~ " : "")\(currentTime) \(progressBar) \(duration)"))
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
    
    func progressBar(percentDone: CGFloat, value: CGFloat, max: CGFloat, song: Bool, mixing: Bool) -> String {
        var fullBar: String = ""
        if song{
            let percentage = percentDone
            let constantWidth = CGFloat(rm.getWidth(text: "\(mixing ? "Mixing ~ " : "")\(Duration.seconds(Double(value)).formatted(.time(pattern: .minuteSecond))) [|] \(Duration.seconds(Double(max)).formatted(.time(pattern: .minuteSecond)))")) //Constant characters in the progress bar
            
            let workingWidth = (displayWidth-constantWidth)
            
            let percentCompleted = workingWidth * percentage
            let percentRemaining = workingWidth * (1.0-percentage)
            
            let completed = String(repeating: "-", count: Int((percentCompleted / rm.getWidth(text: "-"))))
            let remaining = String(repeating: "_", count: Int((percentRemaining / rm.getWidth(text: "_", overrideProgressBar: mirror))))
            fullBar = "[" + completed + "|" + remaining + "]"
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
}
