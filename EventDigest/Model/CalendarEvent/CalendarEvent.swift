//
//  CalendarEvent.swift
//  EventDigest
//
//  Created by Alex Bumbu on 03.02.2023.
//

import Foundation

struct CalendarEvent {
    let id: String
    let name: String
    let location: String?
    let startTime: Date
    let endTime: Date
    let isOnline: Bool
}

extension CalendarEvent {
    
    var isMultiday: Bool {
        if endTime.timeIntervalSince(startTime) > 24 * 3600 {
            return true
        }
        
        return false
    }
    
    func splitByDay() -> [CalendarEvent]? {
        guard isMultiday else {
            return nil
        }
        
        let dateInterval = DateInterval(start: startTime, end: endTime)
        let dates = Calendar.current.datesInInterval(DateInterval(start: startTime, end: endTime))
        
        let events: [CalendarEvent] = dates.enumerated().compactMap { index, date in
            let startTime = date
            let endTime = index == dates.endIndex - 1 ? Calendar.current.endOfDay(for: date) : date
            
            return CalendarEvent(id: self.id,
                                 name: "\(self.name) - Day \(index + 1)",
                                 location: self.location,
                                 startTime: startTime,
                                 endTime: endTime,
                                 isOnline: self.isOnline)
        }
        
        return events
    }
}
