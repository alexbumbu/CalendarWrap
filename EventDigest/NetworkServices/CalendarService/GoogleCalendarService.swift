//
//  GoogleCalendarService.swift
//  EventDigest
//
//  Created by Alex Bumbu on 18.06.2023.
//

import Foundation
import OSLog
import GoogleAPIClientForREST
import GoogleSignIn

private enum Request {
    case calendars
    case events(String, Date, Date)
}

extension Request {
    
    private var query: GTLRCalendarQuery {
        let query: GTLRCalendarQuery
        switch self {
        case .calendars:
            query = GTLRCalendarQuery_CalendarListList.query()
        case .events(let calendarId, let since, let until):
            query = GTLRCalendarQuery_EventsList.query(withCalendarId: calendarId)
            (query as? GTLRCalendarQuery_EventsList)?.timeMin = GTLRDateTime(date: since)
            (query as? GTLRCalendarQuery_EventsList)?.timeMax = GTLRDateTime(date: until)
        }
        
        return query
    }
    
    func perform<T>() async throws -> T {
        let service = GTLRCalendarService()
        service.authorizer = GIDSignIn.sharedInstance.currentUser?.fetcherAuthorizer
                
        let result = try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<T, Error>) in
            service.executeQuery(query) { callbackTicket, response, error in
                if let error {
                    continuation.resume(throwing: error)
                }
                
                if let response = response as? T {
                    continuation.resume(returning: response)
                }
            }
        })
        
        return result
    }
}

struct GoogleCalendarService: CalendarService {
    
    static var permissions: [String] {[
        kGTLRAuthScopeCalendar,
        kGTLRAuthScopePhotosLibrary
    ]}
    
    static func getCalendars() async -> [EventsCalendar]?  {
        do {
            let calendarList: GTLRCalendar_CalendarList = try await Request.calendars.perform()
            guard let items = calendarList.items else {
                Logger.api.error("getCalendars failure \(ApiError.parsing)")
                return nil
            }
            
            return GoogleCalendarMapper.mapCalendars(from: items)
        } catch {
            Logger.api.error("getCalendars failure \(error)")
            return nil
        }
    }
    
    static func getEvents(calendarId: String, since: Date, until: Date) async -> [CalendarEvent]? {
        do {
            let events: GTLRCalendar_Events = try await Request.events(calendarId, since, until).perform()
            guard let items = events.items else {
                Logger.api.error("getEvents failure \(ApiError.parsing)")
                return nil
            }
            
            return GoogleEventMapper.mapEvents(from: items)
        } catch {
            Logger.api.error("getEvents failure \(error)")
            return nil
        }
    }
    
}
