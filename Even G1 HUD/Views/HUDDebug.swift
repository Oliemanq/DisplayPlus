//
//  SecondView.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/4/25.
//

import SwiftUI
import UserNotifications
import Combine

struct HUDDebug: View {
    @State private var notificationStatus = "Requesting Notification Access..."
    @State private var delegate = NotificationDelegate()
    @State private var nc = UNUserNotificationCenter.current()
    
    var body: some View {
        NavigationStack{
            VStack {
                Button("Send test notification"){
                    testNotification()
                }.buttonStyle(.borderedProminent)
                Text("Notification Mirroring Status:")
                    .padding()
                Text(notificationStatus)
                    .padding()
                List{
                    ForEach(delegate.Notifications){ notif in
                        List(delegate.Notifications, id: \.body) { data in
                            VStack(alignment: .leading) {
                                Text(data.title ?? "No title").font(.headline)
                                Text(data.subtitle ?? "No subtitle").font(.subheadline)
                                Text(data.body ?? "No body")
                            }
                        }
                    }
                }
            }
            .onAppear(perform: requestNotificationPermission)
        }
        .navigationTitle(Text("Debug View"))
    }
    func requestNotificationPermission() {
        print("requestNotificationPermission() called") // ADD THIS LINE
        nc.getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("Current notification settings status: \(settings.authorizationStatus)") // ADD THIS LINE
                switch settings.authorizationStatus {
                case .notDetermined:
                    print("Authorization status: Not Determined - Requesting Permissions") // ADD THIS LINE
                    // Request permission
                    nc.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                        DispatchQueue.main.async {
                            if granted {
                                print("Notifications permission granted! (inside requestAuthorization completion)") // ADD THIS LINE
                                notificationStatus = "Notifications permission granted!"
                                setupNotificationDelegate()
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
                    setupNotificationDelegate()
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
        nc.delegate = delegate
        print("Delegate set: \(String(describing: nc.delegate))") // ADD THIS LINE
        notificationStatus = "Notification mirroring active."
    }
    // Delegate method called when a notification is about to be presented while the app is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print(">>> userNotificationCenter:willPresent: called! Title: \(notification.request.content.title)") // ADD THIS LINE
        print("Notification will be presented: \(notification.request.content.title)")
        processNotification(notification: notification)
        completionHandler([.banner, .sound]) // Example: Present as banner and sound on iOS device as well.
    }
    // Delegate method called when the user interacts with a notification (e.g., taps on it) or when a notification is delivered while the app is in the background and brought to foreground because of the notification.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print(">>> userNotificationCenter:didReceive: called! Title: \(response.notification.request.content.title)") // ADD THIS LINE
        print("Notification was received: \(response.notification.request.content.title)")
        processNotification(notification: response.notification)
        completionHandler()
    }

    private func processNotification(notification: UNNotification) {
        let content = notification.request.content
        let title = content.title
        let subtitle = content.subtitle
        let body = content.body
        
        // Create a string representation of the notification content.
        // You can customize the format as needed for your BLE device.
        let notificationString = "Title: \(title)\nSubtitle: \(subtitle)\nBody: \(body)"
        
        print("Notification String: \(notificationString)")
        
        // *** HERE IS WHERE YOU WOULD INTEGRATE YOUR BLE SENDING CODE ***
        // Use 'notificationString' to send the notification data
        // to your BLE device using your existing BLE communication methods.
        // Example:
        // myBLEManager.sendNotificationData(notificationString: notificationString)
        delegate.updateRecentNotif( title: title, subtitle: subtitle, body: body)
    }
    
    func testNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.subtitle = "From your app"
        content.body = "This is a local test notification to check delegate methods."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false) // Trigger in 5 seconds
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        nc.add(request) { error in
            if let error = error {
                print("Error scheduling local notification: \(error.localizedDescription)")
            } else {
                print("Local test notification scheduled.")
            }
        }
    }
    
    
}

#Preview {
    HUDDebug()
}
