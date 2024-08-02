//
//  Session.swift
//  EventDigest
//
//  Created by Alex Bumbu on 09.02.2023.
//

import Foundation

struct Session {
        
    var calendars: [EventsCalendar]
    var activeCalendar: EventsCalendar {
        didSet {
            saveToCache()
        }
    }
    
    init?(calendars: [EventsCalendar]) {
        guard let calendar = calendars.first else {
            return nil
        }
        
        self.calendars = calendars
        self.activeCalendar = calendar
        saveToCache()
    }
}

extension Session {
    static var current: Session? = {
        return loadFromCache()
    }()
}

private extension Session {
    
    func saveToCache() {
        Cache.Session.currentCalendar.save(activeCalendar, encode: true)
    }
    
    static func loadFromCache() -> Session? {
        guard let calendar: EventsCalendar = Cache.Session.currentCalendar.load(decode: true) else {
            return nil
        }
        
        return Session(calendars: [calendar])
    }
}
