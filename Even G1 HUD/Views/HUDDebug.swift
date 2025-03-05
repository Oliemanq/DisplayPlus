//
//  SecondView.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/4/25.
//

import SwiftUI

struct HUDDebug: View {
    var body: some View {
        NavigationStack{
            List {
                Text("Hello, World!")
                Button("Demo Notification Access") {
                    demonstrateNotificationAccess()
                }
            }
        }.navigationTitle(Text("Debug View"))
    }
}

#Preview {
    HUDDebug()
}

// Debug Usage Example
func demonstrateNotificationAccess() {
    let notificationManager = NotificationContentManager.shared
    
    notificationManager.requestNotificationAccess { granted in
        if granted {
            print("✅ Notification Access Granted")
            
            // Get ALL delivered notifications with detailed logging
            notificationManager.getDeliveredNotifications { notifications in
                print("📬 Completed Delivered Notifications Retrieval")
            }
            
            // Try to get notifications for the current app's bundle identifier
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                notificationManager.getNotificationsForApp(bundleIdentifier: bundleIdentifier) { appNotifications in
                    print("📱 App-Specific Notifications: \(appNotifications)")
                    notificationManager.getAllNotifications()
                }
            } else {
                print("❌ Could not retrieve bundle identifier")
            }
        } else {
            print("❌ Notification Access Denied")
        }
    }
}

