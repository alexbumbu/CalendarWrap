//
//  CalendarEventMapper.swift
//  EventDigest
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
            let formattedTime = event["start_time"] as? String,
            let startTime = dateFormatter.date(from: formattedTime),
            let isOnline = event["is_online"] as? Bool
        else {
            return nil
        }
        
        let place = (event as NSDictionary).value(forKeyPath: "place.name") as? String
        
        return CalendarEvent(id: id, name: name, location: place, startTime: startTime, isOnline: isOnline)
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
            let startTime = event.start?.dateTime?.date,
            let location = event.location
        else {
            return nil
        }
        
        // TODO: isOnline is false by default for google events. Figure out solution if needed.
        return CalendarEvent(id: id, name: name, location: location, startTime: startTime, isOnline: false)
    }
    
    static func mapEvents(from events: Array<GTLRCalendar_Event>) -> [CalendarEvent] {
        events.compactMap() { mapEvent(from: $0) }
    }
}
