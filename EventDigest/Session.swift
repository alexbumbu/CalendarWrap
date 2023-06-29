//
//  Session.swift
//  EventDigest
//
//  Created by Alex Bumbu on 09.02.2023.
//

import Foundation

struct Session {
        
    var calendars: [Calendar]
    var activeCalendar: Calendar {
        didSet {
            saveToCache()
        }
    }
    
    init?(calendars: [Calendar]) {
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
        guard let calendar: Calendar = Cache.Session.currentCalendar.load(decode: true) else {
            return nil
        }
        
        return Session(calendars: [calendar])
    }
}
