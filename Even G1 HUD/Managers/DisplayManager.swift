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


class DisplayManager {
    @State var currentDisplay: String = ""
    @State var currentPage: String = "Default"
    
    var time = Date().formatted(date: .omitted, time: .shortened)
    var timer: Timer?
    
    @State var musicMonitor: MusicMonitor = MusicMonitor()
    @State var curSong = MusicMonitor.init().curSong
    
    @State private var progressBar: CGFloat = 0.0
    @State private var counter: Int = 0
    @State private var events: [EKEvent] = []


    //Updating needed info
    func updateHUDInfo(){
        time = Date().formatted(date: .omitted, time: .shortened)
        musicMonitor.updateCurrentSong()
        curSong = musicMonitor.curSong
    }
    
    
    
    
    func defaultDisplay() -> String{
        print("Ran default")
        currentPage = "Default"
        return "\(centerText(text: "\(time)  \(getTodayWeekDay())"))\n\n  \(curSong.title)\n  \(curSong.artist)"
    }
    func musicDisplay() -> String{
        print("Ran music")
        let songProgAsBars = progressBar(
            value: Double(curSong.currentTime.components.seconds/curSong.duration.components.seconds),
            max: Double(curSong.duration.components.seconds),
            width: 20
        )
         return "\(centerText(text: "\(time)  \(getTodayWeekDay())"))\n\n\(centerText(text:"\(curSong.title) - \(curSong.artist)"))\n\(songProgAsBars)"
    }
    
    
    func getTodayWeekDay()-> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        let weekDay = dateFormatter.string(from: Date())
        return weekDay
    }
    
    func progressBar(value: Double, max: Double, width: Int = 50) -> String {
        let percentage: Double
        if max == 0 {
            percentage = 0.0
        } else {
            percentage = Swift.min(1.0, Swift.max(0.0, value / max))
        }
        
        let completedWidth = Int(percentage * Double(width))
        
        let completed = String(repeating: "-", count: completedWidth)
        let remaining = String(repeating: "_", count: width - completedWidth)
        return "[\(completed)\(remaining)]"
    }
    
    func centerText(text: String, width: Int = 50) -> String{
        let padding = Int(Double(width - text.count) / 2.0)
        let newText = String(repeating: "  ", count: padding) + text + String(repeating: "  ", count: padding)
        return newText
    }
}
