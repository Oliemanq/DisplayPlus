//
//  NotificationSystemDebugger.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/5/25.
//


import UserNotifications
import Foundation

class NotificationSystemDebugger {
    static func retrieveNotifications() {
        // Explicit authorization request
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            guard granted else {
                print("❌ Notification permissions not granted")
                return
            }
            
            // Use DispatchQueue to ensure this runs on the main queue
            DispatchQueue.main.async {
                UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                    print("🔔 Total System Notifications Attempt: \(notifications.count)")
                    
                    if notifications.isEmpty {
                        print("⚠️ No notifications found via standard method")
                        
                        // Additional diagnostic steps
                        self.checkNotificationSettings()
                        self.printSystemNotificationDetails()
                    } else {
                        for (index, notification) in notifications.enumerated() {
                            let content = notification.request.content
                            print("---")
                            print("Notification \(index + 1):")
                            print("Title: \(content.title)")
                            print("Body: \(content.body)")
                            print("Subtitle: \(content.subtitle)")
                        }
                    }
                }
            }
        }
    }
    
    private static func checkNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("📱 Notification Settings:")
            print("Authorization Status: \(settings.authorizationStatus.rawValue)")
            print("Alert Setting: \(settings.alertSetting.rawValue)")
            print("Sound Setting: \(settings.soundSetting.rawValue)")
            print("Badge Setting: \(settings.badgeSetting.rawValue)")
        }
    }
    
    private static func printSystemNotificationDetails() {
        // Additional debugging method
        print("⚠️ Additional System Checks:")
        print("Main Bundle Identifier: \(Bundle.main.bundleIdentifier ?? "Unknown")")
        print("Current Process Name: \(ProcessInfo.processInfo.processName)")
    }
}

// Usage
class NotificationTester {
    func testNotifications() {
        NotificationSystemDebugger.retrieveNotifications()
    }
}