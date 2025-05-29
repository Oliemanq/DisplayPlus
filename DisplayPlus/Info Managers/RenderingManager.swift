//
//  RenderingManager.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 5/8/25.
//
import SwiftUI

public class RenderingManager {
    var DisplayWidth = 576
    var key = UserDefaults.standard.dictionary(forKey: "calibratedKeys")
    
    var charWidth: [String: Float] {
        var tempDict: [String: Float] = [:]
        
        if let keyDict = key {
            for (k, v) in keyDict {
                if let intValue = v as? Float {
                    tempDict[k] = 100 / intValue 
                }
            }
        }
        
        return tempDict
    }
    
    func getWidth(text: String) -> Float {
        var totalWidth: Float = 0
        for char in text {
            totalWidth += ((charWidth[String(char)] ?? 48/100))
        }
        return totalWidth
    }
    
    func fitOnScreen(text: String) -> String {
        var numOfChar = 0
        let charWidth = getWidth(text: text)
        while true {
            if Int(round(charWidth)) * numOfChar <= DisplayWidth {
                numOfChar += 1
            } else {
                let modifier = -1
                return String(repeating: text, count: numOfChar + modifier)
            }
        }
    }
}
