//
//  DisplayPlusTests.swift
//  DisplayPlusTests
//
//  Created by Oliver Heisel on 4/26/25.
//

import XCTest
@testable import DisplayPlus

final class DisplayPlusTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCenterTest() throws {
        //Given
        let textToCenter = "Hello World"
        let displayManager = DisplayManager()
        
        //When
        let centeredText = displayManager.centerText(text: textToCenter)
        let centeredSpace = displayManager.centerText(text: "")
        
        //Then
        XCTAssertEqual(centeredText, "                                      Hello World")
        XCTAssertEqual(centeredSpace, String(repeating: " ", count: 45))
        
    }

    
    func testProgressBar() throws {
        //Given
        let d = DisplayManager()
        let progress = 0.5
        let max = 1.0
        
        //When
        let bar = d.progressBar(value: progress, max: max)
        
        //Then
        XCTAssertEqual(bar, "[-----------------------|_____________________________]")
    }
    
    func testDefaultDisplay() throws {
        //Given
        let time = Date().formatted(date: .omitted, time: .shortened)
        let displayManager = DisplayManager()
        var textOutput: [String] = []
        var textOutputManual: [String] = []
        
        var batteryLevel: Float { UIDevice.current.batteryLevel }
        let batteryLevelFormatted = (Int)(batteryLevel * 100)
        
        //When
        textOutput = displayManager.defaultDisplay()
        
        textOutputManual.append(displayManager.centerText(text: "\(time) \(displayManager.getTodayWeekDay()) \(batteryLevelFormatted)%"))
        
        //Then
        XCTAssertEqual(textOutput, textOutputManual)
    }
}
