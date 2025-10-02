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
        c.eventsFormatted = [
            event(titleLine: "Test", subtitleLine: "10:00 AM - 11:00 AM"),
            event(titleLine: "Test 2", subtitleLine: "10:00 PM - 11:00 PM"),
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
        
            
        p.newRow(thingsInOrder: [
            time,
            battery,
            music
        ], row: 0)
        
        
        print(p.outputPage())
    }
    
    func testSavingAndLoadingPages() throws {
        
        let pm = PageManager(loadPagesOnStart: false)
        
        var p1: Page = Page(name: "Test Page")
        
        let time: TimeThing = TimeThing(name: "Time Test")
        let date: DateThing = DateThing(name: "Date Test")
        let battery: BatteryThing = BatteryThing(name: "Battery Test")
        let music: MusicThing = MusicThing(name: "Music Test", size: "Big")
        
        p1.newRow(thingsInOrder: [time, date], row: 0)
        p1.newRow(thingsInOrder: [battery], row: 1)
        p1.newRow(thingsInOrder: [music], row: 2)
        
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
}

