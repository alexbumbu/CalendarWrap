//
//  CalendarMapper.swift
//  EventDigest
//
//  Created by Alex Bumbu on 19.06.2023.
//

import Foundation
import GoogleAPIClientForREST

protocol CalendarMapper {
    associatedtype T
    
    static func mapCalendar(from calendar: T) -> Calendar?
    static func mapCalendars(from calendars: Array<T>) -> [Calendar]
}

struct FacebookCalendarMapper: CalendarMapper {
    
    static func mapCalendar(from calendar: [String: Any]) -> Calendar? {
        guard
            let id = calendar["id"] as? String,
            let name = calendar["name"] as? String
        else {
            return nil
        }
        
        return Calendar(id: id, name: name ,type: .facebook)
    }
    
    static func mapCalendars(from calendars: Array<[String: Any]>) -> [Calendar] {
        calendars.compactMap() { mapCalendar(from: $0) }
    }
}


// MARK: -

struct GoogleCalendarMapper: CalendarMapper {
    
    static func mapCalendar(from calendar: GTLRCalendar_CalendarListEntry) -> Calendar? {
        guard
            let id = calendar.identifier,
            let name = calendar.summary
        else {
            return nil
        }
        
        return Calendar(id: id, name: name ,type: .google)
    }
    
    static func mapCalendars(from calendars: Array<GTLRCalendar_CalendarListEntry>) -> [Calendar] {
        calendars.compactMap() { mapCalendar(from: $0) }
    }
}
