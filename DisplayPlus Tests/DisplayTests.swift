//
//  DisplayTests.swift
//  Even G1 HUD Tests
//
//  Created by Oliver Heisel on 4/26/25.
//

import Testing
import SwiftUI
@testable import DisplayPlus

struct DisplayTests {

    @Test func testDefaultDisplay() async throws {
        //Given
        var time = Date().formatted(date: .omitted, time: .shortened)
        var displayManager = DisplayManager()
        var textOutput: [String] = []
        var textOutputManual: [String] = []
        
        //When
        textOutput = displayManager.defaultDisplay()
        
        textOutputManual.append(displayManager.centerText(text: "\(time) \(displayManager.getTodayWeekDay())"))
        //Then
        
        #expect(textOutput == textOutputManual)
        
    }

}
