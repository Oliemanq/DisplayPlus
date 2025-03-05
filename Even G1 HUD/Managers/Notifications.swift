import UserNotifications

class NotificationContentManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationContentManager()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestNotificationAccess(completion: @escaping (Bool) -> Void) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if let error = error {
                    print("🚨 Notification Authorization Error: \(error.localizedDescription)")
                }
                
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    
    func extractNotificationDetails(notification: UNNotification) -> [String: Any] {
        let request = notification.request
        let content = request.content
        
        return [
            "title": content.title,
            "body": content.body,
            "subtitle": content.subtitle,
            "threadIdentifier": content.threadIdentifier,
            "categoryIdentifier": content.categoryIdentifier,
            "bundleIdentifier": request.identifier, // Changed this line
            "timestamp": notification.date
        ]
    }
    
    func getDeliveredNotifications(completion: @escaping ([UNNotification]) -> Void) {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            print("Total Delivered Notifications: \(notifications.count)")
            
            for notification in notifications {
                let details = self.extractNotificationDetails(notification: notification)
                print("Notification Details:")
                print(details)
            }
            
            completion(notifications)
        }
    }
    
    func getNotificationsForApp(bundleIdentifier: String, completion: @escaping ([UNNotification]) -> Void) {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            print("Checking Notifications for Bundle: \(bundleIdentifier)")
            print("Total Notifications to Check: \(notifications.count)")
            
            let appNotifications = notifications.filter { notification in
                // Print out request details for debugging
                print("Notification Request Identifier: \(notification.request.identifier)")
                print("Notification Content Description: \(notification.request.content.description)")
                
                return true // Temporarily return all notifications
            }
            
            print("App-Specific Notifications Found: \(appNotifications.count)")
            completion(appNotifications)
        }
    }
    
    // UNUserNotificationCenterDelegate Methods
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let notification = response.notification
        let details = extractNotificationDetails(notification: notification)
        print("Notification tapped: \(details)")
        
        completionHandler()
    }
    func getAllNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            print("Total Notifications: \(notifications.count)")
            
            for notification in notifications {
                let content = notification.request.content
                print("---")
                print("Title: \(content.title)")
                print("Body: \(content.body)")
                print("Subtitle: \(content.subtitle)")
            }
        }
    }
}
