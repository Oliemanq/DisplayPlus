//
//  RenderingManager.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 5/8/25.
//
import SwiftUI
import Foundation

public class RenderingManager {
    var DisplayWidth = 576
    var key = UserDefaults.standard.dictionary(forKey: "calibratedKeys")
    var calibratedChars: [String: Int] = [:]
    
    init(){
        var amountOfChars = 36
        calibratedChars.updateValue(amountOfChars, forKey: "&")
        calibratedChars.updateValue(amountOfChars, forKey: "@")
        calibratedChars.updateValue(amountOfChars, forKey: "M")
        calibratedChars.updateValue(amountOfChars, forKey: "W")
        calibratedChars.updateValue(amountOfChars, forKey: "m")
        calibratedChars.updateValue(amountOfChars, forKey: "w")
        calibratedChars.updateValue(amountOfChars, forKey: "~")
        
        amountOfChars = 144
        calibratedChars.updateValue(amountOfChars, forKey: "!")
        calibratedChars.updateValue(amountOfChars, forKey: ",")
        calibratedChars.updateValue(amountOfChars, forKey: ".")
        calibratedChars.updateValue(amountOfChars, forKey: ";")
        calibratedChars.updateValue(amountOfChars, forKey: ":")
        calibratedChars.updateValue(amountOfChars, forKey: "i")
        calibratedChars.updateValue(amountOfChars, forKey: "l")
        calibratedChars.updateValue(amountOfChars, forKey: "|")
        
        amountOfChars = 41
        calibratedChars.updateValue(amountOfChars, forKey: "#")
        calibratedChars.updateValue(amountOfChars, forKey: "%")
        calibratedChars.updateValue(amountOfChars, forKey: "A")
        calibratedChars.updateValue(amountOfChars, forKey: "V")
        calibratedChars.updateValue(amountOfChars, forKey: "X")
        calibratedChars.updateValue(amountOfChars, forKey: "Y")
        
        amountOfChars = 57
        calibratedChars.updateValue(amountOfChars, forKey: "+")
        calibratedChars.updateValue(amountOfChars, forKey: "-")
        calibratedChars.updateValue(amountOfChars, forKey: "<")
        calibratedChars.updateValue(amountOfChars, forKey: "=")
        calibratedChars.updateValue(amountOfChars, forKey: ">")
        calibratedChars.updateValue(amountOfChars, forKey: "E")
        calibratedChars.updateValue(amountOfChars, forKey: "F")
        calibratedChars.updateValue(amountOfChars, forKey: "L")
        calibratedChars.updateValue(amountOfChars, forKey: "^")
        calibratedChars.updateValue(amountOfChars, forKey: "b")
        calibratedChars.updateValue(amountOfChars, forKey: "c")
        calibratedChars.updateValue(amountOfChars, forKey: "d")
        calibratedChars.updateValue(amountOfChars, forKey: "e")
        calibratedChars.updateValue(amountOfChars, forKey: "f")
        calibratedChars.updateValue(amountOfChars, forKey: "g")
        calibratedChars.updateValue(amountOfChars, forKey: "h")
        calibratedChars.updateValue(amountOfChars, forKey: "k")
        calibratedChars.updateValue(amountOfChars, forKey: "n")
        calibratedChars.updateValue(amountOfChars, forKey: "o")
        calibratedChars.updateValue(amountOfChars, forKey: "p")
        calibratedChars.updateValue(amountOfChars, forKey: "q")
        calibratedChars.updateValue(amountOfChars, forKey: "s")
        calibratedChars.updateValue(amountOfChars, forKey: "z")
        
        amountOfChars = 48
        calibratedChars.updateValue(amountOfChars, forKey: "$")
        calibratedChars.updateValue(amountOfChars, forKey: "0")
        calibratedChars.updateValue(amountOfChars, forKey: "2")
        calibratedChars.updateValue(amountOfChars, forKey: "3")
        calibratedChars.updateValue(amountOfChars, forKey: "4")
        calibratedChars.updateValue(amountOfChars, forKey: "5")
        calibratedChars.updateValue(amountOfChars, forKey: "6")
        calibratedChars.updateValue(amountOfChars, forKey: "7")
        calibratedChars.updateValue(amountOfChars, forKey: "8")
        calibratedChars.updateValue(amountOfChars, forKey: "9")
        calibratedChars.updateValue(amountOfChars, forKey: "?")
        calibratedChars.updateValue(amountOfChars, forKey: "B")
        calibratedChars.updateValue(amountOfChars, forKey: "C")
        calibratedChars.updateValue(amountOfChars, forKey: "D")
        calibratedChars.updateValue(amountOfChars, forKey: "G")
        calibratedChars.updateValue(amountOfChars, forKey: "H")
        calibratedChars.updateValue(amountOfChars, forKey: "K")
        calibratedChars.updateValue(amountOfChars, forKey: "N")
        calibratedChars.updateValue(amountOfChars, forKey: "O")
        calibratedChars.updateValue(amountOfChars, forKey: "P")
        calibratedChars.updateValue(amountOfChars, forKey: "Q")
        calibratedChars.updateValue(amountOfChars, forKey: "R")
        calibratedChars.updateValue(amountOfChars, forKey: "S")
        calibratedChars.updateValue(amountOfChars, forKey: "T")
        calibratedChars.updateValue(amountOfChars, forKey: "U")
        calibratedChars.updateValue(amountOfChars, forKey: "Z")
        calibratedChars.updateValue(amountOfChars, forKey: "a")
        calibratedChars.updateValue(amountOfChars, forKey: "u")
        calibratedChars.updateValue(amountOfChars, forKey: "v")
        calibratedChars.updateValue(amountOfChars, forKey: "x")
        calibratedChars.updateValue(amountOfChars, forKey: "y")
        
        amountOfChars = 72
        calibratedChars.updateValue(amountOfChars, forKey: "*")
        calibratedChars.updateValue(amountOfChars, forKey: "/")
        calibratedChars.updateValue(amountOfChars, forKey: "1")
        calibratedChars.updateValue(amountOfChars, forKey: "J")
        calibratedChars.updateValue(amountOfChars, forKey: "_")
        calibratedChars.updateValue(amountOfChars, forKey: "r")
        calibratedChars.updateValue(amountOfChars, forKey: "t")
        calibratedChars.updateValue(amountOfChars, forKey: "{")
        calibratedChars.updateValue(amountOfChars, forKey: "}")
        
        amountOfChars = 96
        calibratedChars.updateValue(amountOfChars, forKey: "(")
        calibratedChars.updateValue(amountOfChars, forKey: ")")
        calibratedChars.updateValue(amountOfChars, forKey: "I")
        calibratedChars.updateValue(amountOfChars, forKey: "[")
        calibratedChars.updateValue(amountOfChars, forKey: "]")
        calibratedChars.updateValue(amountOfChars, forKey: "`")
        calibratedChars.updateValue(amountOfChars, forKey: "j")
        
        amountOfChars = 96
        calibratedChars.updateValue(amountOfChars, forKey: " ")
        
        UserDefaults.standard.set(calibratedChars, forKey: "calibratedKeys")
    }
    
    var charWidth: [String: Float] {
        var tempDict: [String: Float] = [:]
        
        if let keyDict = key {
            for (k, v) in keyDict {
                if let intValue = v as? Int {
                    tempDict[k] = 100.0 / Float(intValue)
                }
            }
        }
        return tempDict
    }
    
    func getWidth(text: String, overrideProgressBar: Bool = false) -> CGFloat {        
        var totalWidth: CGFloat = 0
        for char in text {
            if isJapanese(char: char) {
                totalWidth += CGFloat(100.0 / 32) // Assuming Japanese characters are wide, like 'M'
            } else if overrideProgressBar {
                if text == "_" {
                    totalWidth += CGFloat(charWidth[String("-")] ?? 100/32)
                }
            } else {
                totalWidth += CGFloat(charWidth[String(char)] ?? 48/100)
            }
        }
        return totalWidth
    }
    
    func isJapanese(char: Character) -> Bool {
        for scalar in char.unicodeScalars {
            let value = scalar.value
            // Hiragana, Katakana, CJK Unified Ideographs (Kanji)
            if (value >= 0x3040 && value <= 0x309F) || // Hiragana
               (value >= 0x30A0 && value <= 0x30FF) || // Katakana
               (value >= 0x4E00 && value <= 0x9FAF) {  // CJK Unified Ideographs (Kanji)
                return true
            }
        }
        return false
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
    
    func doesFitOnScreen(text: String) -> Bool {
        let charWidth: CGFloat = getWidth(text: text)
        return charWidth <= 100
    }
}
