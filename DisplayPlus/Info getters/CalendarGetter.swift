import Foundation
import EventKit
import SwiftUI

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
    // Modified to accept optional list of calendar IDs to filter
    func fetchEventsForNextDay(calendarIDs: [String] = [], completion: @escaping CalendarEventsCompletion) {
        // Request access to calendar
        requestAccess { [weak self] success in
            guard let self = self else { return }
            
            if success {
                self.getTodayEvents(calendarIDs: calendarIDs, completion: completion)
            } else {
                completion(.failure(CalendarError.accessDenied))
            }
        }
    }
    
    // New function to retrieve all available calendars
    func getAvailableCalendars() -> [EKCalendar] {
        return eventStore.calendars(for: .event)
    }
    
    // Request calendar access permission with proper handling of all authorization states
    private func requestAccess(completion: @escaping (Bool) -> Void) {
        // ... (Existing implementation remains unchanged) ...
        let authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        
        switch authorizationStatus {
        case .authorized:
            completion(true)
            
        case .fullAccess:
            completion(true)
            
        case .writeOnly:
            print("Calendar write access")
            completion(false)
            
        case .notDetermined:
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
            
        case .denied, .restricted:
            print("Calendar access denied/restricted")
            completion(false)
            
        @unknown default:
            print("Calendar access unknown default")
            completion(false)
        }
    }
    
    // Fetch events for the next day, filtered by the user's selected calendars.
    private func getTodayEvents(calendarIDs: [String], completion: @escaping CalendarEventsCompletion) {
        // Get the current date and calendar
        let today = Date()
        let calendar = Calendar.current
        
        // Calculate the start and end of today
        let startOfToday = calendar.startOfDay(for: today)
        guard let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) else {
            completion(.failure(CalendarError.failedToFetchEvents))
            return
        }
        
        // Resolve calendar objects from IDs if provided
        var calendarsToSearch: [EKCalendar]? = nil
        if !calendarIDs.isEmpty {
            calendarsToSearch = calendarIDs.compactMap { self.eventStore.calendar(withIdentifier: $0) }
        }
        
        // Create the date range predicate for the search.
        // Pass the specific calendars if selected, otherwise nil searches all.
        let predicate = eventStore.predicateForEvents(withStart: today, end: endOfToday, calendars: calendarsToSearch)
        
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
            
            return true
        }
        
        completion(.success(filteredEvents))
    }
    
    func getAuthStatus() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        return (status == .fullAccess || status == .authorized)
    }
}

struct event: Identifiable, Hashable{
    var id = UUID()
    var titleLine: String
    var subtitleLine: String
    var startTime: Date
    var endTime: Date
}
