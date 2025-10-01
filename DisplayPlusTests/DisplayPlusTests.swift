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
        b.battery = 75
        
        XCTAssertEqual(b.toString() , "75%" )
    }
}
