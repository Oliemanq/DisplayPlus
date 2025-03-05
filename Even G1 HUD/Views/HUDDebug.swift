//
//  SecondView.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/4/25.
//

import SwiftUI

struct HUDDebug: View {
    @State private var notificationStatus = "Requesting Notification Access..."

    var body: some View {
        NavigationStack{
            VStack {
                        Text("Notification Mirroring Status:")
                            .padding()
                        Text(notificationStatus)
                            .padding()
                    }
                    .onAppear(perform: requestNotificationPermissionAndSetupDelegate)
        }.navigationTitle(Text("Debug View"))
    }
    func requestNotificationPermissionAndSetupDelegate() {
        print("requestNotificationPermissionAndSetupDelegate() called") // ADD THIS LINE
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("Current notification settings status: \(settings.authorizationStatus)") // ADD THIS LINE
                switch settings.authorizationStatus {
                case .notDetermined:
                    print("Authorization status: Not Determined - Requesting Permissions") // ADD THIS LINE
                    // Request permission
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                        DispatchQueue.main.async {
                            if granted {
                                print("Notifications permission granted! (inside requestAuthorization completion)") // ADD THIS LINE
                                notificationStatus = "Notifications permission granted!"
                                self.setupNotificationDelegate()
                            } else {
                                print("Notifications permission denied :(") // ADD THIS LINE
                                notificationStatus = "Notifications permission denied."
                                if let error = error {
                                    print("Permission error: \(error.localizedDescription)") // ADD THIS LINE
                                    notificationStatus += " Error: \(error.localizedDescription)"
                                }
                            }
                        }
                    }
                case .authorized, .provisional, .ephemeral: // Already authorized
                    print("Authorization status: Authorized - Notifications already authorized.") // ADD THIS LINE
                    notificationStatus = "Notifications already authorized."
                    self.setupNotificationDelegate()
                case .denied:
                    print("Authorization status: Denied - Notifications denied by user.") // ADD THIS LINE
                    notificationStatus = "Notifications denied by user."
                @unknown default:
                    print("Authorization status: Unknown - Unknown notification authorization status.") // ADD THIS LINE
                    notificationStatus = "Unknown notification authorization status."
                }
            }
        }
    }
        
        func setupNotificationDelegate() {
            print("setupNotificationDelegate() called") // ADD THIS LINE
            // Create the notification delegate and set it to the UNUserNotificationCenter
            let delegate = NotificationDelegate()
            UNUserNotificationCenter.current().delegate = delegate
            print("Delegate set: \(String(describing: UNUserNotificationCenter.current().delegate))") // ADD THIS LINE
            notificationStatus = "Notification mirroring active."
        }
}

#Preview {
    HUDDebug()
}

