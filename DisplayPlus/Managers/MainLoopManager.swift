//
//  MainLoopManager.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 4/27/25.
//

import Foundation

class MainLoop {
    var textOutput: String = ""
    var displayManager = DisplayManager()
    
    func start() {
        displayManager.loadEvents()
        displayManager.updateHUDInfo()
        
    }
    
    
    func HandleText() {
        textOutput = ""
        
        if let page = UserDefaults.standard.string(forKey: "currentPage") {
            if page == "Default"{ // DEFAULT PAGE HANDLER
                let displayLines = displayManager.defaultDisplay()
                
                if displayLines.isEmpty{
                    textOutput = "broken"
                } else {
                    for line in displayLines {
                        textOutput += line + "\n"
                    }
                }
                
                
            } else if page == "Music"{ // MUSIC PAGE HANDLER
                for line in displayManager.musicDisplay() {
                    textOutput += line + "\n"
                }
                
            } else if page == "RearView"{
                textOutput = "To be implemented later, getting UI in place"
                
            } else if page == "Calendar"{ // CALENDAR PAGE HANDLER
                for line in displayManager.calendarDisplay() {
                    textOutput += line + "\n"
                }
                
            } else {
                textOutput = "No page selected"
            }
        } else {
            textOutput = "No page selected"
        }
    }
}
