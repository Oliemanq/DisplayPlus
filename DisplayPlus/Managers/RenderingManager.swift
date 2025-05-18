//
//  RenderingManager.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 5/8/25.
//
import SwiftUI

public class RenderingManager {
    var DisplayWidth = 576
    var key: [String: Int] = [
        "A": 11,
        "B": 9,
        "C": 9,
        "D": 9,
        "E": 8,
        "F": 8,
        "G": 9,
        "H": 9,
        "I": 3,
        "J": 7,
        "K": 10,
        "L": 9,
        "M": 13,
        "N": 10,
        "O": 9,
        "P": 10,
        "Q": 11,
        "R": 10,
        "S": 9,
        "T": 9,
        "U": 11,
        "V": 12,
        "W": 14,
        "X": 12,
        "Y": 11,
        "Z": 11,
        "a": 6,
        "b": 5,
        "c": 5,
        "d": 5,
        "e": 5,
        "f": 4,
        "g": 5,
        "h": 5,
        "i": 1,
        "j": 3,
        "k": 5,
        "l": 1,
        "m": 8,
        "n": 5,
        "o": 5,
        "p": 5,
        "q": 5,
        "r": 4,
        "s": 6,
        "t": 4,
        "u": 5,
        "v": 6,
        "w": 8,
        "x": 6,
        "y": 6,
        "z": 5,
        "1": 3,
        "2": 6,
        "3": 5,
        "4": 6,
        "5": 6,
        "6": 6,
        "7": 6,
        "8": 6,
        "9": 6,
        "0": 6,
        ",": 2,
        ".": 2,
        "/": 5,
        "<": 5,
        ">": 5,
        ";": 2,
        ":": 2,
        "[": 3,
        "]": 3,
        "{": 4,
        "}": 4,
        "(": 4,
        ")": 4,
        "-": 5,
        "=": 5,
        "_": 4,
        "+": 5,
        "`": 3,
        "~": 9,
        "|": 2,
        "°": 6,
        "?": 10,
        "!": 3,
        "@": 15,
        "#": 12,
        "$": 12,
        "%": 12,
        "^": 9,
        "&": 14,
        "*": 6,
        " ": 7
    ]
    private var keyWithPadding: [String: Int] {
        var tempKey = key
        for (char, value) in key {
            if char == "_" {
                tempKey[char] = value + 1
            }else{
                tempKey[char] = value + 2
            }
        }
        return tempKey
    }
    
    var howManyFit: [String: Int] = [
        "|" : 144
    ]
    
    func getWidth(text: String) -> Int {
        var totalWidth: Int = 0
        for char in text {
            totalWidth += ((keyWithPadding[String(char)] ?? 7))
        }
        return totalWidth
    }
    
    func fitOnScreen(text: String) -> String {
        var numOfChar = 0
        let charWidth = getWidth(text: text)
        while true {
            if charWidth * numOfChar <= DisplayWidth {
                numOfChar += 1
            } else {
                let modifier = -1
                print("numOfChar = \(numOfChar)")
                print("numOfChar modified = \(numOfChar + modifier)")
                print("char width = \(charWidth)")
                print("total width = \(charWidth) * \(numOfChar) = \(charWidth * (numOfChar + modifier))")
                print("\n")
                return String(repeating: text, count: numOfChar + modifier)
            }
        }
    }
}
