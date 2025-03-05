import SwiftUI
import UserNotifications

// Create a class to act as the UNUserNotificationCenterDelegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

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
    }
}
