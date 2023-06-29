//
//  CalendarService.swift
//  EventDigest
//
//  Created by Alex Bumbu on 19.06.2023.
//

import Foundation

protocol CalendarService {
    
    static var permissions: [String] { get }
    
    static func getCalendars() async -> [Calendar]?
    static func getEvents(calendarId: String, since: Date, until: Date) async -> [CalendarEvent]?
}
