//
//  CalendarEventMapper.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 19.06.2023.
//

import Foundation
import GoogleAPIClientForREST

protocol CalendarEventMapper {
    associatedtype T
    
    static func mapEvent(from event: T) -> CalendarEvent?
    static func mapEvents(from events: Array<T>) -> [CalendarEvent]
}

struct FacebookEventMapper: CalendarEventMapper {
    
    static func mapEvent(from event: [String: Any]) -> CalendarEvent? {
        let dateFormatter = ISO8601DateFormatter()
        
        guard
            let id = event["id"] as? String,
            let name = event["name"] as? String,
            let formattedStartTime = event["start_time"] as? String,
            let startTime = dateFormatter.date(from: formattedStartTime),
            let formattedEndTime = event["end_time"] as? String,
            let endTime = dateFormatter.date(from: formattedEndTime),
            let isOnline = event["is_online"] as? Bool
        else {
            return nil
        }
        
        let place = (event as NSDictionary).value(forKeyPath: "place.name") as? String
        
        return CalendarEvent(id: id, name: name, location: place, startTime: startTime, endTime: endTime, isOnline: isOnline)
    }
    
    static func mapEvents(from events: Array<[String: Any]>) -> [CalendarEvent] {
        events.compactMap() { mapEvent(from: $0) }
    }
}


// MARK: -

struct GoogleEventMapper: CalendarEventMapper {
    
    static func mapEvent(from event: GTLRCalendar_Event) -> CalendarEvent? {
        guard
            let id = event.identifier,
            let name = event.summary,
            let startTime = event.start?.dateTime?.date ?? event.start?.date?.date.startOfDay(),
            let endTime = event.end?.dateTime?.date ?? event.end?.date?.date.endOfDay()
        else {
            return nil
        }
        
        let location = event.location
        
        // TODO: isOnline is false by default for google events. Figure out solution if needed.
        return CalendarEvent(id: id, name: name, location: location, startTime: startTime, endTime: endTime, isOnline: false)
    }
    
    static func mapEvents(from events: Array<GTLRCalendar_Event>) -> [CalendarEvent] {
        events.compactMap() { mapEvent(from: $0) }
    }
}

// MARK: -

private extension Date {
    
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
    
    func endOfDay() -> Date {
        Calendar.current.endOfDay(for: self)
    }
}
