import Foundation
import EventKit

class CalendarManager {
    private let eventStore = EKEventStore()
    
    // Completion handler type definition for async operations
    typealias CalendarEventsCompletion = (Result<[EKEvent], Error>) -> Void
    
    // Error types specific to our calendar operations
    enum CalendarError: Error {
        case accessDenied
        case failedToFetchEvents
    }
    
    // Request access to the calendar and fetch events for the next day
    func fetchEventsForNextDay(completion: @escaping CalendarEventsCompletion) {
        // Request access to calendar
        requestAccess { [weak self] success in
            guard let self = self else { return }
            
            if success {
                self.getTodayEvents(completion: completion)
            } else {
                completion(.failure(CalendarError.accessDenied))
            }
        }
    }
    
    // Request calendar access permission with proper handling of all authorization states
    private func requestAccess(completion: @escaping (Bool) -> Void) {
        // Check for EventKit authorization status
        let authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        
        switch authorizationStatus {
        case .authorized:
            completion(true)
            
        case .fullAccess:
            completion(true)
            
        case .writeOnly:
            completion(false)
            
        case .notDetermined:
            // Request permission using the appropriate API based on iOS version
            if #available(iOS 17.0, macOS 14.0, *) {
                // Use new API for iOS 17+
                eventStore.requestFullAccessToEvents { granted, error in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            } else {
                // Use older API for pre-iOS 17
                eventStore.requestAccess(to: .event) { granted, error in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            }
            
        case .denied, .restricted:
            completion(false)
            
        @unknown default:
            completion(false)
        }
    }
    
    // Fetch events for the next day
    private func getTodayEvents(completion: @escaping CalendarEventsCompletion) {
        // Get the current date and calendar
        let today = Date()
        let calendar = Calendar.current
        
        // Calculate the start and end of today
        let startOfToday = calendar.startOfDay(for: today)
        guard let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) else {
            completion(.failure(CalendarError.failedToFetchEvents))
            return
        }
        
        var morning = DateComponents()
        morning.hour = 0
        morning.minute = 0
        
        
        // Create the date range predicate for the search.
        let predicate = eventStore.predicateForEvents(withStart: today, end: endOfToday, calendars: nil)
        
        // Fetch events matching the predicate (includes all-day events for now)
        let events = eventStore.events(matching: predicate)
        
        // Filter out all-day events
        let filteredEvents = events.filter { event in
                // Keep events that are NOT all-day AND don't start at midnight
                if event.isAllDay {
                    return false
                }
                
                // Filter out events that start at midnight (12:00 AM)
                let startDateComponents = calendar.dateComponents([.hour, .minute], from: event.startDate)
                if startDateComponents.hour == 0 && startDateComponents.minute == 0 {
                    return false
                }
                
                // Filter out Canvas events
                if event.calendar.title == "Canvas" {
                    return false
                }
                
                return true
            }
         
        completion(.success(filteredEvents))
    }
}
