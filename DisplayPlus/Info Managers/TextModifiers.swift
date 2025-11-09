//
//  TextModifiers.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

import Foundation
import CoreGraphics
import SwiftUI

// A globally accessible utility namespace for text-related helpers.
// These methods are static and can be called from anywhere.
public enum tm {
    /// Builds a textual progress bar string based on the available display width.
    /// - Parameters:
    ///   - percentDone: Value in 0...1 representing progress completion.
    ///   - value: The current value (in seconds) for display alongside the bar.
    ///   - total: The maximum value (in seconds) for display alongside the bar.
    ///   - displayWidth: Total width available for the progress bar, in the same units used by `RenderingManager.getWidth`.
    ///   - mirror: Whether to use mirrored/progress-bar-specific width overrides when measuring certain characters.
    ///   - renderingManager: Optional injection for testing; defaults to nil.
    /// - Returns: A string representing the progress bar.
    public static func progressBar(
        percentDone: CGFloat,
        value: CGFloat,
        max: CGFloat,
        displayWidth: CGFloat = 100,
        mirror: Bool = false,
        renderingManager: RenderingManager? = nil
    ) -> String {
        let rm = renderingManager ?? RenderingManager()
        let percentage = Swift.max(CGFloat(0), Swift.min(CGFloat(1), percentDone))

        let constantText = "\(Duration.seconds(Double(value)).formatted(.time(pattern: .minuteSecond))) [|] \(Duration.seconds(Double(max)).formatted(.time(pattern: .minuteSecond)))"
        let constantWidth = rm.getWidth(text: constantText)

        let workingWidth = Swift.max(0, displayWidth - constantWidth)
        let percentCompleted = workingWidth * percentage
        let percentRemaining = workingWidth * (1.0 - percentage)

        let dashWidth = Swift.max(CGFloat(1), rm.getWidth(text: "-"))
        let underscoreWidth = Swift.max(CGFloat(1), rm.getWidth(text: "_", overrideProgressBar: mirror))

        let completedCount = Int(percentCompleted / dashWidth)
        let remainingCount = Int(percentRemaining / underscoreWidth)

        let completed = String(repeating: "-", count: Swift.max(0, completedCount))
        let remaining = String(repeating: "_", count: Swift.max(0, remainingCount))
        let fullBar = "[" + completed + "|" + remaining + "]"
        return fullBar
    }

    /// Centers the given text within the provided display width.
    /// - Parameters:
    ///   - text: The text to center.
    ///   - displayWidth: Available width to center within.
    ///   - mirror: If true, returns text unchanged.
    ///   - renderingManager: Optional injection for testing; defaults to nil.
    /// - Returns: The centered text with left padding spaces.
    public static func centerText(
        _ text: String,
        displayWidth: CGFloat = 100,
        mirror: Bool = false,
        renderingManager: RenderingManager? = nil
    ) -> String {
        if mirror { return text }
        let rm = renderingManager ?? RenderingManager()

        let widthOfText = rm.getWidth(text: text)
        let widthRemaining: CGFloat = Swift.max(0, displayWidth - widthOfText)
        let spaceWidth = Swift.max(CGFloat(1), rm.getWidth(text: " "))
        let paddingCount = Int((widthRemaining / spaceWidth) / 2)
        let padding = String(repeating: " ", count: Swift.max(0, paddingCount))
        let finalText = padding + text
        return finalText
    }

    /// Finds the largest prefix length of `text` that fits into `availableWidth`.
    /// - Parameters:
    ///   - text: The text to measure.
    ///   - availableWidth: The maximum width available.
    ///   - renderingManager: Optional injection for testing; defaults to nil.
    /// - Returns: The character count that best fits.
    public static func findBestFit(
        _ text: String,
        availableWidth: CGFloat,
        renderingManager: RenderingManager? = nil
    ) -> Int {
        let rm = renderingManager ?? RenderingManager()

        var lowerBound = 0
        var upperBound = text.count
        var bestFit = 0

        while lowerBound <= upperBound {
            let mid = (lowerBound + upperBound) / 2
            let prefix = String(text.prefix(mid))
            if rm.getWidth(text: prefix) <= availableWidth {
                bestFit = mid
                lowerBound = mid + 1
            } else {
                upperBound = mid - 1
            }
        }
        return bestFit
    }
    
    public static func getWidth(_ text: String) -> CGFloat {
        let rm = RenderingManager()
        return rm.getWidth(text: text)
    }
    public static func doesFitOnScreen(text: String) -> Bool {
        let rm = RenderingManager()
        return rm.doesFitOnScreen(text: text)
    }
    public static func isJapanese(char: Character) -> Bool {
        let rm = RenderingManager()
        return rm.isJapanese(char: char)
    }
    
    public static func containsEmoji(_ text: String) -> Bool {
        return text.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x1F600...0x1F64F, // Emoticons
                 0x1F300...0x1F5FF, // Misc Symbols and Pictographs
                 0x1F680...0x1F6FF, // Transport and Map
                 0x2600...0x26FF,   // Misc symbols
                 0x2700...0x27BF,   // Dingbats
                 0xFE00...0xFE0F,   // Variation Selectors
                 0x1F900...0x1F9FF, // Supplemental Symbols and Pictographs
                 0x1F1E6...0x1F1FF: // Flags
                return true
            default:
                return false
            }
        }
    }
    
    public static func shorten(to: CGFloat, text: String, log: Bool = false) -> String {
        let textWidth = tm.getWidth(text)
        
        // If text already fits, return as-is
        if textWidth <= to {
            if log {
                print("Text fits, returning original")
            }
            return text
        }
        
        // Find best fit using binary search
        let maxChars = tm.findBestFit(text, availableWidth: to, renderingManager: RenderingManager())
        
        if maxChars <= 3 {
            if log {
                print("Text too short to shorten meaningfully, returning truncated")
            }
            return String(text.prefix(maxChars))
        }
        
        // Try to preserve important words by removing less important ones
        let words = text.split(separator: " ").map(String.init)
        
        // Define low-priority words to remove first
        let lowPriorityWords = Set(["the", "a", "an", "of", "in", "on", "at", "to", "for", "and", "or", "but", "be", "is", "are", "was", "were", "it", "that", "this", "these", "those"])
        
        // Try removing low-priority words first
        var shortenedWords = words.filter { !lowPriorityWords.contains($0.lowercased()) }
        for word in shortenedWords {
            if word.hasSuffix("ed.") {
                var newWord = String(word.dropLast(3))
                newWord.append("ing.")
                if log {
                    print("Changed working of '\(word)' to '\(newWord)'")
                }
                shortenedWords = shortenedWords.map { $0 == word ? newWord : $0 }
            }
            
            if containsEmoji(word) {
                if log {
                    print("Removing emoji")
                }
                let newWord = word.filter { !tm.containsEmoji(String($0)) }
                shortenedWords = shortenedWords.map { $0 == word ? newWord : $0 }
            }
        }
            
        var attempt = shortenedWords.joined(separator: " ")
        
        if tm.getWidth(attempt) <= to {
            if log {
                print("Shortened by removing low-priority words")
            }
            return attempt
        }
        
        // If still too long, progressively remove words from middle
        while shortenedWords.count > 2 && tm.getWidth(attempt) > to {
            let middleIndex = shortenedWords.count / 2
            shortenedWords.remove(at: middleIndex)
            attempt = shortenedWords.joined(separator: " ")
        }
        
        if tm.getWidth(attempt) <= to {
            if log {
                print("Shortened by removing middle words")
            }
            return attempt
        }
        
        // Last resort: truncate with ellipsis
        let ellipsisWidth = tm.getWidth("...")
        let availableForText = to - ellipsisWidth
        let fitChars = tm.findBestFit(text, availableWidth: availableForText, renderingManager: RenderingManager())
        
        if fitChars > 0 {
            if log {
                print("Shortened by truncating with ellipsis")
            }
            return String(text.prefix(fitChars)) + "..."
        }
        
        // Absolute fallback: just fit what we can
        if log {
            print("Giving up, returning maximum fit")
        }
        return String(text.prefix(maxChars))
    }
}

public class RenderingManager {
    var DisplayWidth = 576
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
        for (k, v) in calibratedChars {
            tempDict[k] = 100.0 / Float(v)
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
    
    func doesFitOnScreen(text: String, maxWidth: CGFloat = 100) -> Bool {
        let charWidth: CGFloat = getWidth(text: text)
        return charWidth <= maxWidth
    }
    
    
}
