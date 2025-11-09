//
//  DisplayPlusTests.swift
//  DisplayPlusTests
//
//  Created by Oliver Heisel on 4/26/25.
//

import XCTest
import SwiftUI
@testable import DisplayPlus

final class DisplayPlusTests: XCTestCase {
    func testCalendarThing() throws {
        let c: CalendarThing = CalendarThing(name: "Test")
        
        let calendar = Calendar.current
        let today = Date()
        
        // Create dates for "10:00 AM - 11:00 AM"
        let startTime1 = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today)!
        let endTime1 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: today)!
        
        // Create dates for "10:00 PM - 11:00 PM"
        let startTime2 = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: today)!
        let endTime2 = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: today)!
        
        c.eventsFormatted = [
            event(titleLine: "Test", subtitleLine: "10:00 AM - 11:00 AM", startTime: startTime1, endTime: endTime1),
            event(titleLine: "Test 2", subtitleLine: "10:00 PM - 11:00 PM", startTime: startTime2, endTime: endTime2),
        ]
        
        XCTAssertEqual(c.toString() , "\n\(tm.centerText("Test - 10:00 AM - 11:00 AM"))\n\(tm.centerText("Test 2 - 10:00 PM - 11:00 PM"))" )
    }
    func testBatteryThing() throws {
        let b: BatteryThing = BatteryThing(name: "Test")
        b.setBatteryLevel(level: 75)
        
        XCTAssertEqual(b.toString() , "75%" )
        XCTAssertEqual(b.toInt() , 75 )
    }
    
    func testDisplayOutputFromPageClass() throws {
        let time: TimeThing = TimeThing(name: "Time Test")
        
        let battery: BatteryThing = BatteryThing(name: "Battery Test")
        battery.setBatteryLevel(level: 50)
        
        let music: MusicThing = MusicThing(name: "Music Test", size: "Small")
        music.setCurSong(song: Song(title: "Test Song", artist: "Me", album: "Dev", duration: 200, currentTime: 100, isPaused: false, songChanged: false))
        
        
        let p: Page = Page(name: "Test")
        
            
        p.newRow([
            time,
            battery,
            music
        ], row: 0)
        
        
        print(p.outputPage())
    }
    
    func testSavingAndLoadingPages() throws {
        
        let pm = PageManager(loadPagesOnStart: false, currentPageIn: "Default")
        
        var p1: Page = Page(name: "Test Page")
        
        let time: TimeThing = TimeThing(name: "Time Test")
        let date: DateThing = DateThing(name: "Date Test")
        let battery: BatteryThing = BatteryThing(name: "Battery Test")
        let music: MusicThing = MusicThing(name: "Music Test", size: "Big")
        
        p1.newRow([time, date], row: 0)
        p1.newRow([battery], row: 1)
        p1.newRow([music], row: 2)
        
        let p2: Page = p1 //Creating a duplicate page
        
        pm.addPage(p: p1) //Adding page to manager
        
        pm.savePages(testing: true) //Saving pages to AppStorage String
                
        pm.loadPages() //Loading Page objects from AppStorage String
        
        p1 = pm.getPage(num: 0) //Getting the first page from the manager
        
        p1.updateAllThingsFromPage()
        p2.updateAllThingsFromPage()
        
        print("\nPrinting good page: ---------\n\(p2.outputPage())\n")
        print("\nPrinting loaded page: ---------\n\(p1.outputPage())\n")
        
        XCTAssertEqual(p1.PageName, p2.PageName) //Checking if page name is the same
        XCTAssertEqual(p1.outputPage(), p2.outputPage()) //Checking if output is the same
    }
    
    func testingShorten() throws {
        print("\n\n")
        let originalText = "This is a long text that needs to be shortened."
        print("Original: \(originalText)")
        let shortenedText = tm.shorten(to: 50, text: originalText)
        print("Shortened: \(shortenedText)")
        print("\n\n")
    
        let originalText2 = "This is a very long text that definitely needs to be shortened because it exceeds the maximum width allowed."
        print("Original: \(originalText2)")
        let shortenedText2 = tm.shorten(to: 50, text: originalText2)
        print("Shortened: \(shortenedText2)")
        print("\n\n")
        
        let originalText3 = "🏎 FORMULA 1 GRAN PREMIO DE LA CIUDAD DE MÉXICO 2025 - Practice 3"
        print("Original: \(originalText3)")
        let shortenedText3 = tm.shorten(to: 40, text: originalText3)
        print("Shortened: \(shortenedText3)")
        print("\n\n")

        let originalText4 = "🏁 FORMULA 1 MSC CRUISES UNITED STATES GRAND PRIX 2025 - Race"
        print("Original: \(originalText4)")
        let shortenedText4 = tm.shorten(to: 25, text: originalText4)
        print("Shortened: \(shortenedText4)")
        print("\n\n")
    }
}

