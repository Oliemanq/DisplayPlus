//
//  TextModifiers.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

import Foundation
import CoreGraphics

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
        total: CGFloat,
        displayWidth: CGFloat = 100,
        mirror: Bool = false,
        renderingManager: RenderingManager? = nil
    ) -> String {
        let rm = renderingManager ?? RenderingManager()
        let percentage = Swift.max(CGFloat(0), Swift.min(CGFloat(1), percentDone))

        let constantText = "\(Duration.seconds(Double(value)).formatted(.time(pattern: .minuteSecond))) [|] \(Duration.seconds(Double(total)).formatted(.time(pattern: .minuteSecond)))"
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
}
