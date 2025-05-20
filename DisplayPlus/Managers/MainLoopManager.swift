import Foundation
import SwiftUICore
import UIKit


class MainLoop: ObservableObject {
    var textOutput: String = ""
    var displayManager: DisplayManager
    var weather: weatherManager
    
    var counter: Int = 0
    
    init(displayManager: DisplayManager){
        self.displayManager = displayManager
        self.weather = displayManager.weather
        
        
    }
    
    func update() {
        displayManager.loadEvents()
        displayManager.updateHUDInfo()
        displayManager.batteryLevelFormatted = (Int)(UIDevice.current.batteryLevel * 100)
        Task{
            if counter % 600 == 0{
                await updateWeather()
            }
        }
        counter += 1
        
    }
    
    func updateWeather() async{
        do{
            try await weather.fetchWeatherData()
        }catch {
            print("failed weather fetch \(error)")
        }
    
    }
    
    func HandleText() {
        textOutput = ""
        
        if let page = UserDefaults.standard.string(forKey: "currentPage") {
            if page == "Default" { // DEFAULT PAGE HANDLER
                let displayLines = displayManager.defaultDisplay()
                
                if displayLines.isEmpty {
                    textOutput = "broken"
                } else {
                    for line in displayLines {
                        textOutput += line + "\n"
                    }
                }
                
            } else if page == "Music" { // MUSIC PAGE HANDLER
                for line in displayManager.musicDisplay() {
                    textOutput += line + "\n"
                }
                
            } else if page == "RearView" {
                textOutput = "To be implemented later, getting UI in place"
                
            } else if page == "Calendar" { // CALENDAR PAGE HANDLER
                for line in displayManager.calendarDisplay() {
                    textOutput += line + "\n"
                }
                
            /*
            }else if page == "Debug" {
                for line in displayManager.debugDisplay(index: counter%26) {
                    textOutput += line + "\n"
                }
             */
            }else {
                textOutput = "No page selected"
            }
        } else {
            textOutput = "No page selected"
        }
    }
}
