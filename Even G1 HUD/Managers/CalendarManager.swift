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
        print("Beginning calendar access request")
        requestAccess { [weak self] success in
            guard let self = self else { return }
            
            print("Calendar access request result: \(success)")
            if success {
                self.getTodayEvents(completion: completion)
            } else {
                print("Calendar access denied")
                completion(.failure(CalendarError.accessDenied))
            }
        }
    }
    
    // Request calendar access permission with proper handling of all authorization states
    private func requestAccess(completion: @escaping (Bool) -> Void) {
        // Check for EventKit authorization status
        let authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        print("Current authorization status: \(authorizationStatus)")
        
        switch authorizationStatus {
        case .authorized:
            print("Already authorized")
            completion(true)
            
        case .fullAccess:
            print("Already has full access")
            completion(true)
            
        case .writeOnly:
            print("Has write-only access, can't read events")
            completion(false)
            
        case .notDetermined:
            print("Permission not determined, requesting...")
            // Request permission using the appropriate API based on iOS version
            if #available(iOS 17.0, macOS 14.0, *) {
                // Use new API for iOS 17+
                print("Using iOS 17+ API")
                eventStore.requestFullAccessToEvents { granted, error in
                    print("Full access request result: \(granted), error: \(String(describing: error))")
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            } else {
                // Use older API for pre-iOS 17
                print("Using pre-iOS 17 API")
                eventStore.requestAccess(to: .event) { granted, error in
                    print("Access request result: \(granted), error: \(String(describing: error))")
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            }
            
        case .denied, .restricted:
            print("Access denied or restricted")
            completion(false)
            
        @unknown default:
            print("Unknown authorization status")
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
            print("Failed to calculate today's date range")
            completion(.failure(CalendarError.failedToFetchEvents))
            return
        }
        
        print("Searching for events between \(today) and \(endOfToday)")
        
        // Create the date range predicate for the search.
        let predicate = eventStore.predicateForEvents(withStart: today, end: endOfToday, calendars: nil)
        
        // Fetch events matching the predicate (includes all-day events for now)
        let events = eventStore.events(matching: predicate)
        print("Found \(events.count) events for today (including all-day)")
        
        // Filter out all-day events
        var filteredEvents = events.filter { event in
            return !event.isAllDay // Keep events that are NOT all-day
        }
        print("Found \(filteredEvents.count) events for today (excluding all-day)")
        
        filteredEvents = events.filter { event in
            return event.calendar.title == "Canvas"
        }
        print("Found \(filteredEvents.count) events for today (excluding all-day and canvas)")
        completion(.success(filteredEvents))
    }
}
