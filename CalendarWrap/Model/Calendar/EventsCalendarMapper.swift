//
//  EventsCalendarMapper.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 19.06.2023.
//

import Foundation
import GoogleAPIClientForREST

protocol EventsCalendarMapper {
    associatedtype T
    
    static func mapCalendar(from calendar: T) -> EventsCalendar?
    static func mapCalendars(from calendars: Array<T>) -> [EventsCalendar]
}

struct FacebookCalendarMapper: EventsCalendarMapper {
    
    static func mapCalendar(from calendar: [String: Any]) -> EventsCalendar? {
        guard
            let id = calendar["id"] as? String,
            let name = calendar["name"] as? String
        else {
            return nil
        }
        
        return EventsCalendar(id: id, name: name ,type: .facebook)
    }
    
    static func mapCalendars(from calendars: Array<[String: Any]>) -> [EventsCalendar] {
        calendars.compactMap() { mapCalendar(from: $0) }
    }
}


// MARK: -

struct GoogleCalendarMapper: EventsCalendarMapper {
    
    static func mapCalendar(from calendar: GTLRCalendar_CalendarListEntry) -> EventsCalendar? {
        guard
            let id = calendar.identifier,
            let name = calendar.summary
        else {
            return nil
        }
        
        return EventsCalendar(id: id, name: name ,type: .google)
    }
    
    static func mapCalendars(from calendars: Array<GTLRCalendar_CalendarListEntry>) -> [EventsCalendar] {
        calendars.compactMap() { mapCalendar(from: $0) }
    }
}
