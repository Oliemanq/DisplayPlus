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
    let displayWidth: Float = 100.0
    
    //Info manager
    var info: InfoManager
    
    var songProgAsBars: String = ""
    

    @AppStorage("currentPage", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var currentPage = "Default"
    
    var currentDisplayLines: [String] = []
    
    init(info: InfoManager){
        self.info = info
    }
    
    func header() -> String {
        currentDisplayLines.removeAll()
        currentDisplayLines.append("")

        return centerText(text: ("\(info.getTime()) | \(info.getTodayDate()) | Phone - \(info.getBattery())% \(info.getCurrentTemp() != 0 ? ("| \(info.getCurrentTemp())°F") : "")"))
    }
    
    func defaultDisplay() -> [String] {
        return(currentDisplayLines)
    }
    
    func musicDisplay() -> [String]{
        var artist = ""
        if info.getCurSong().artist.count > 25 {
            artist = ("\(info.getCurSong().artist.prefix(25))...")
        }else{
            artist = info.getCurSong().artist
        } //Setting maximum character count for artist and song name to avoid spilling over onto next line
        
        var songTitle: String = ""
        if info.getCurSong().title.count > 25 {
            songTitle = ("\(info.getCurSong().title.prefix(25))...")
        }else{
            songTitle = info.getCurSong().title
        }
        
        currentDisplayLines.append((centerText(text: "\(songTitle) - \(artist)"))) //Appening song info
        
        if !info.getCurSong().isPaused{
            //let tempProgBar = progressBar(value: 0.99, max: 1.0)
            //let tempProgBar = progressBar(value: 0.0001, max: 1.0)
            //let tempProgBar = progressBar(value: 0.5, max: 1.0)
            //currentDisplayLines.append("\(Duration.seconds(musicMonitor.currentTime).formatted(.time(pattern: .minuteSecond))) \(tempProgBar) \(Duration.seconds(musicMonitor.curSong.duration).formatted(.time(pattern: .minuteSecond)))")
            currentDisplayLines.append(centerText(text:"\(Duration.seconds(info.getCurSong().currentTime).formatted(.time(pattern: .minuteSecond))) \(progressBar(value: Float(info.getCurSong().currentTime), max: Float(info.getCurSong().duration), song: true)) \(Duration.seconds(info.getCurSong().duration).formatted(.time(pattern: .minuteSecond)))"))
        }else{
            currentDisplayLines.append(centerText(text: "--Paused--"))
        } //Hiding progress bar if song is paused, showing paused text
        
        return currentDisplayLines
    }
    
    func calendarDisplay() -> [String]{
        if (info.getEvents().count != 0) {
            for event in info.eventsFormatted {
                let title = (event.titleLine.count > 15 ? String(event.titleLine.prefix(25) + "...") : event.titleLine)
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
    
    func progressBar(value: Float, max: Float, song: Bool) -> String {
        var fullBar: String = ""
        if song{
            if value != 0.0 && max != 0.0 {
                let constantWidth = Float(rm.getWidth(text: "\(Duration.seconds(Double(value)).formatted(.time(pattern: .minuteSecond))) [|] \(Duration.seconds(Double(max)).formatted(.time(pattern: .minuteSecond)))")) //Constant characters in the progress bar
                
                let workingWidth = (displayWidth-constantWidth)
                
                let percentage = value/max
                
                let percentCompleted = workingWidth * percentage
                let percentRemaining = workingWidth * (1.0-percentage)
                
                let completed = String(repeating: "-", count: Int((percentCompleted / rm.getWidth(text: "-"))))
                let remaining = String(repeating: "_", count: Int((percentRemaining / rm.getWidth(text: "_"))))
                
                fullBar = "[" + completed + "|" + remaining + "]"
            }else{
                fullBar = "Broken"
            }
        }
        
        return fullBar
    }
    
    func centerText(text: String) -> String {
        let widthOfText = rm.getWidth(text: text)
        
        let widthRemaining: Float = max(0, displayWidth-widthOfText)
        let padding = String(repeating: " ", count: Int(widthRemaining/rm.getWidth(text: " "))/2)
        
        let FinalText = padding + text
        return FinalText
    }
}
